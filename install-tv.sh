#!/bin/sh
# Instala/atualiza o app na TV LG por Dev Mode.
#
# Por que não usar o ares-install: a TV negocia só o algoritmo ssh-rsa, que a
# lib ssh2 embutida no CLI da LG não aceita — e ela não lê ~/.ssh/config, então
# não há como ensinar. Aqui usamos o ssh do sistema, que aceita o algoritmo
# antigo por opção, e chamamos o mesmo serviço Luna que o ares-install chamaria.
#
# Uso:  ./install-tv.sh <IP-DA-TV> <PASSPHRASE-DO-KEY-SERVER> [NOME-DO-APARELHO]
#
# O nome do aparelho é o mesmo usado no ares-setup-device e define o arquivo da
# chave (~/.ssh/<nome>_webos). Padrão "tv". Para uma segunda TV, cadastre com
# outro nome e passe-o aqui — as duas convivem sem conflito.
set -e
cd "$(dirname "$0")"

IP="$1"; PASS="$2"; DEV="${3:-tv}"
KEY="$HOME/.ssh/${DEV}_webos"
APPID="com.nailson.tatame"
REMOTE_DIR="/media/developer/apps/usr/palm/applications/$APPID"

die() { echo; echo "FALHOU: $1"; exit 1; }

[ -n "$IP" ] && [ -n "$PASS" ] || die "uso: ./install-tv.sh <IP> <PASSPHRASE> [NOME]"
[ -f "$KEY" ] || die "chave $KEY não existe. Rode:
  ares-setup-device --add $DEV --info \"host=$IP\" --info \"port=9922\" \\
    --info \"username=prisoner\" --info \"passphrase=$PASS\"
  ares-novacom --device $DEV --getkey"

# A sessão de Dev Mode expira em ~50h. Sem esta checagem o script seguia adiante
# e imprimia sucesso mesmo sem ter conectado.
nc -z -G 5 -w 5 "$IP" 9922 >/dev/null 2>&1 || die "porta 9922 fechada em $IP.
A sessão de Dev Mode expirou ou a TV está fora da rede.
Abra o app Developer Mode na TV e aperte EXTEND."

./build-webos.sh >/dev/null
IPK=$(ls webos/*.ipk)

TMPKEY=$(mktemp); cp "$KEY" "$TMPKEY"; chmod 600 "$TMPKEY"
trap 'rm -f "$TMPKEY" "$TMPKEY.pub"' EXIT
ssh-keygen -p -P "$PASS" -N "" -f "$TMPKEY" >/dev/null 2>&1 || die "passphrase incorreta"

SSHOPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa -o ConnectTimeout=15"

echo "== $DEV ($IP): enviando $IPK =="
scp -i "$TMPKEY" -P 9922 $SSHOPTS "$IPK" "prisoner@$IP:/tmp/tatame.ipk" \
  >/dev/null 2>/tmp/scp.err || die "não conseguiu copiar o pacote:
$(grep -viE 'warning: perman' /tmp/scp.err | head -3)"

# O luna-send-pub precisa de -i: com -n ele sai antes da resposta chegar. E como
# -i não termina sozinho, roda em segundo plano e é morto depois.
ssh -i "$TMPKEY" -p 9922 $SSHOPTS "prisoner@$IP" 'sh -s' <<'REMOTE' 2>/dev/null
cd /tmp
/usr/bin/luna-send-pub -i luna://com.webos.appInstallService/dev/install '{"id":"com.nailson.tatame","ipkUrl":"/tmp/tatame.ipk","subscribe":true}' > ins.txt 2>&1 &
P=$!; sleep 14; kill $P 2>/dev/null
grep -oE '"state":"[^"]*"|"reason":"[^"]*"' ins.txt | tail -3

# Reinstalar com o app aberto não recarrega a página: a webOS mantém a versão em
# memória e o launch só traz para frente. Fechar antes é obrigatório.
/usr/bin/luna-send-pub -i luna://com.webos.applicationManager/dev/closeByAppId '{"id":"com.nailson.tatame"}' > c.txt 2>&1 &
P=$!; sleep 4; kill $P 2>/dev/null
sleep 2
/usr/bin/luna-send-pub -i luna://com.webos.applicationManager/launch '{"id":"com.nailson.tatame"}' > l.txt 2>&1 &
P=$!; sleep 4; kill $P 2>/dev/null
cat l.txt
rm -f ins.txt c.txt l.txt tatame.ipk
REMOTE

# Confere no disco da TV que o arquivo instalado é o que acabou de sair daqui.
# Com retentativa: logo após abrir o app a TV fica ocupada e recusa a conexão,
# o que fazia esta verificação falhar mesmo com a instalação correta.
LOCAL_SUM=$(sed '/name="viewport"/d' index.html | cksum | awk '{print $1}')
REMOTE_SUM=""
sleep 6
for try in 1 2 3 4; do
  REMOTE_SUM=$(ssh -i "$TMPKEY" -p 9922 $SSHOPTS "prisoner@$IP" \
    "cksum < $REMOTE_DIR/index.html" 2>/dev/null | awk '{print $1}')
  [ -n "$REMOTE_SUM" ] && break
  sleep 6
done

echo
if [ -z "$REMOTE_SUM" ]; then
  echo "AVISO: a instalação foi aceita, mas a TV não respondeu para verificar."
  echo "Provavelmente está ocupada abrindo o app. Confira na tela."
elif [ "$LOCAL_SUM" = "$REMOTE_SUM" ]; then
  echo "OK — verificado: o arquivo na TV é idêntico ao daqui ($REMOTE_SUM)."
  echo "App reaberto. Está em Minhas Apps na TV."
else
  die "o arquivo na TV ($REMOTE_SUM) difere do esperado ($LOCAL_SUM)"
fi
