#!/bin/sh
# Instala o app na TV LG por Dev Mode.
#
# Por que não usar o ares-install: a TV negocia só o algoritmo ssh-rsa, que a
# lib ssh2 embutida no CLI da LG não aceita — e ela não lê ~/.ssh/config, então
# não há como ensinar. Aqui usamos o ssh do sistema, que aceita o algoritmo
# antigo por opção, e chamamos o mesmo serviço Luna que o ares-install chamaria.
#
# Uso:  ./install-tv.sh <IP-DA-TV> <PASSPHRASE-DO-KEY-SERVER>
set -e
cd "$(dirname "$0")"

IP="$1"
PASS="$2"
KEY="$HOME/.ssh/tv_webos"
APPID="com.nailson.tatame"

[ -n "$IP" ] && [ -n "$PASS" ] || { echo "uso: ./install-tv.sh <IP-DA-TV> <PASSPHRASE>"; exit 1; }
[ -f "$KEY" ] || { echo "chave não encontrada. Rode antes:"; echo "  ares-novacom --device tv --getkey"; exit 1; }

[ -f webos/*.ipk ] 2>/dev/null || ./build-webos.sh >/dev/null
IPK=$(ls webos/*.ipk)

# cópia temporária sem senha, para o ssh rodar sem prompt
TMPKEY=$(mktemp)
cp "$KEY" "$TMPKEY"
chmod 600 "$TMPKEY"
ssh-keygen -p -P "$PASS" -N "" -f "$TMPKEY" >/dev/null 2>&1 || {
  rm -f "$TMPKEY" "$TMPKEY.pub"; echo "passphrase incorreta"; exit 1
}
trap 'rm -f "$TMPKEY" "$TMPKEY.pub"' EXIT

SSH="ssh -i $TMPKEY -p 9922 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa"

echo "== enviando $IPK =="
scp -i "$TMPKEY" -P 9922 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa \
    "$IPK" "prisoner@$IP:/tmp/tatame.ipk" 2>&1 | grep -viE 'warning: perman' || true

# O luna-send-pub precisa de -i: com -n ele sai antes da resposta chegar.
# Roda em segundo plano e é morto depois, porque -i não termina sozinho.
$SSH "prisoner@$IP" 'sh -s' <<'REMOTE' 2>&1 | grep -viE 'warning: perman'
cd /tmp
echo "== instalando =="
/usr/bin/luna-send-pub -i luna://com.webos.appInstallService/dev/install '{"id":"com.nailson.tatame","ipkUrl":"/tmp/tatame.ipk","subscribe":true}' > ins.txt 2>&1 &
P=$!; sleep 12; kill $P 2>/dev/null
grep -oE '"state":"[^"]*"|"reason":"[^"]*"' ins.txt | tail -3

echo "== abrindo =="
/usr/bin/luna-send-pub -i luna://com.webos.applicationManager/launch '{"id":"com.nailson.tatame"}' > l.txt 2>&1 &
P=$!; sleep 4; kill $P 2>/dev/null
cat l.txt
rm -f ins.txt l.txt tatame.ipk
REMOTE
echo
echo "Pronto. O app está na tela inicial da TV, em Minhas Apps."
