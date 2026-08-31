# Instalar e atualizar um app web na TV LG (webOS)

Anotado a partir de uma instalação real em **31/08/2026**, numa LG
**webOS TV Lite 5.6.2**, imagem `starfish-atsc-secured`, build `20260421`.
Boa parte disto não está na documentação da LG, ou está de forma que engana.

Testado nesta TV: IP `192.168.1.60`, passphrase do Key Server `C0D62C`.

---

## 1. Conta de desenvolvedor: login social não serve

O app Developer Mode da TV pede **ID de e-mail e senha** do site de
desenvolvedor da LG. Se você criou a conta com "Continuar com Google", **não
existe senha** e não há o que digitar na TV — o site mostra seu e-mail e ainda
assim o login falha.

Saídas, em ordem de menor esforço:

1. Usar **"Esqueci minha senha"** com o mesmo e-mail. Se a LG deixar definir
   uma, a conta passa a ter as duas coisas e o login na TV funciona.
2. Cadastrar de novo com **e-mail e senha**, usando um alias do Gmail
   (`seuemail+lg@gmail.com`) — mesma caixa de entrada, e-mail diferente para a LG.

O cadastro precisa ser no **site de desenvolvedor** (`webostv.developer.lge.com`),
não apenas uma LG Account comum de TV.

Se aparecer `requestLogin error` ou "visit LG developer site and sign in first":
abra o site no navegador, deixe a sessão logada e tente na TV de novo. Se o
login não avançar de jeito nenhum, em **Ajustes → Geral → Contratos de Usuário**
desmarque os termos e repita.

## 2. Ligar o modo desenvolvedor

1. Content Store → instalar **Developer Mode**
2. Abrir e entrar com a conta de desenvolvedor
3. **Dev Mode Status** → ligar → **a TV reinicia** (é esse passo que abre a
   porta 9922; sem ele nada funciona)
4. Reabrir o app e clicar em **Key Server** → aparece uma **passphrase de 6
   caracteres** no canto inferior esquerdo, sensível a maiúsculas
5. Anotar o **IP** mostrado na tela

Conferir do computador, na mesma rede:

```sh
nc -z -G 3 192.168.1.60 9922 && echo "dev mode ativo"
```

Se a porta estiver fechada, o Dev Mode Status não está ligado ou a TV está em
outra rede. A descoberta por SSDP (`ares-setup-device --search`) costuma não
achar nada mesmo com tudo certo — não use isso como diagnóstico. Varrer a rede
inteira é lento; olhe primeiro `arp -an` e teste só os IPs que já apareceram.

**A sessão expira em ~50 horas.** O campo *Remain Session* no app mostra o que
resta e o botão **EXTEND** renova, desde que a TV esteja na rede. Se zerar, não
dá mais para estender: religue o Dev Mode. Ele também se desliga após 10
reinícios sem internet.

## 3. Empacotar

App de webOS TV é HTML, CSS e JS — o modelo nativo. Não há reescrita.

```sh
npm install -g @webos-tools/cli --registry=https://registry.npmjs.org/
ares-package webos --outdir webos      # ou ./build-webos.sh
```

O `appinfo.json` mínimo que funcionou:

```json
{
  "id": "com.nailson.tatame",
  "version": "1.0.0",
  "vendor": "Nailson Israel",
  "type": "web",
  "main": "index.html",
  "title": "Cronômetro do Tatame",
  "icon": "icon.png",
  "largeIcon": "largeIcon.png",
  "bgColor": "#07090C",
  "resolution": "1920x1080",
  "disableBackHistoryAPI": true
}
```

Ícones: **80x80** (`icon`) e **130x130** (`largeIcon`), PNG, caminho relativo ao
`appinfo.json`. O `id` não pode começar com `com.lge`, `com.palm` ou `com.webos`.

Só arquivos do app na pasta empacotada. Qualquer coisa que estiver lá vai para
dentro do `.ipk` — um `build.sh` esquecido dentro dela foi junto.

## 4. Pegar a chave

```sh
ares-setup-device --add tv \
  --info "host=192.168.1.60" --info "port=9922" \
  --info "username=prisoner" --info "passphrase=C0D62C"

ares-novacom --device tv --getkey     # pede a passphrase exibida na TV
```

A chave fica em `~/.ssh/tv_webos`, criptografada com a passphrase. Para
confirmar que a passphrase está certa, sem depender de mais nada:

```sh
ssh-keygen -y -P "C0D62C" -f ~/.ssh/tv_webos >/dev/null && echo "passphrase ok"
```

## 5. O `ares-install` não funciona — e por quê

```
ares-install ERR! [ssh exec failure]: All configured authentication methods failed
```

**A TV negocia somente o algoritmo `ssh-rsa`.** A lib `ssh2` embutida no CLI da
LG (v1.x) removeu `ssh-rsa` dos padrões e **não lê `~/.ssh/config`**, então não
há como configurar. O CLI sobrescreve algoritmos em `lib/base/novacom.js`, mas
só os de troca de chave (`kex`) — adicionar `serverHostKey` ali **não resolve**,
porque a falha é na assinatura da autenticação, não no host key.

O `ssh` do sistema funciona, com os algoritmos antigos habilitados:

```sh
ssh -i /tmp/tvkey -p 9922 \
    -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa \
    prisoner@192.168.1.60 'echo ok'
```

Sem essas duas opções: `no matching host key type found. Their offer: ssh-rsa`.

Para rodar sem prompt, faça uma cópia da chave sem passphrase e apague depois:

```sh
cp ~/.ssh/tv_webos /tmp/tvkey && chmod 600 /tmp/tvkey
ssh-keygen -p -P "C0D62C" -N "" -f /tmp/tvkey
# ... usar ...
rm -f /tmp/tvkey /tmp/tvkey.pub
```

## 6. Instalar à mão

```sh
scp -i /tmp/tvkey -P 9922 \
    -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa \
    webos/*.ipk prisoner@192.168.1.60:/tmp/tatame.ipk
```

Depois, **na TV**:

```sh
/usr/bin/luna-send-pub -i \
  luna://com.webos.appInstallService/dev/install \
  '{"id":"com.nailson.tatame","ipkUrl":"/tmp/tatame.ipk","subscribe":true}' > ins.txt 2>&1 &
P=$!; sleep 12; kill $P
grep -oE '"state":"[^"]*"' ins.txt
```

Sucesso é `"state":"installed"`. Depois:

```sh
/usr/bin/luna-send-pub -i luna://com.webos.applicationManager/launch \
  '{"id":"com.nailson.tatame"}'
```

O app fica em `/media/developer/apps/usr/palm/applications/<id>/`.

### As armadilhas que custaram horas

1. **`luna-send-pub` precisa da flag `-i`.** Com `-n 1` ele **sai antes da
   resposta chegar e imprime absolutamente nada** — o que parece bloqueio de
   permissão e não é. Como `-i` não termina sozinho, rode em segundo plano
   gravando num **arquivo**: `timeout` e pipes engolem a saída e reproduzem o
   mesmo silêncio enganoso.
2. **`luna-send` é exclusivo do root** (`-rwx------`), daí `Permission denied`.
   O `luna-send-pub` é `-rwxr-xr-x` e alcança o serviço de instalação. O usuário
   `prisoner` tem privilégio suficiente.
3. **`LUNASERVICE ERROR -1031: ... not privileged`** só aparece se você declarar
   um appId com `-a`. **Não se aplica à chamada de instalação** — foi essa
   mensagem que me fez concluir, erradamente, que a TV não aceitava sideload.
4. **`"reason":"ipk verified failed"` com `errorCode:-5`** costuma ser
   simplesmente **caminho errado**: o arquivo apontado em `ipkUrl` não existe.
5. `/media/developer` é do root e o `prisoner` não tem grupo para escrever nela.
   Não tente extrair o app à mão ali; use o serviço.
6. `opkg` é executável pelo `prisoner`, mas não consegue escrever nos destinos.
   Não é caminho.
7. O `timeout` do busybox dessa TV usa `-t N`, não `N`.

## 7. Atualizar

Reinstalar em cima. Não precisa desinstalar, nem repetir o Key Server.

```sh
./install-tv.sh 192.168.1.60 C0D62C
```

Quando a sessão de Dev Mode expirar, o script falha na conexão: abra o app
Developer Mode na TV e aperte **EXTEND**.

## 7b. Mais de uma TV com a mesma conta

A conta de desenvolvedor **não está amarrada a nenhuma TV**. Dá para repetir o
processo em quantas quiser, sem novo cadastro.

Cada TV, porém, tem o seu próprio: instalação do app Developer Mode, sessão de
Dev Mode (com validade independente), IP e passphrase do Key Server.

O nome do aparelho no `ares-setup-device` define o arquivo da chave —
`--add tv` gera `~/.ssh/tv_webos`. Use nomes diferentes e as duas convivem:

```sh
ares-setup-device --add academia \
  --info "host=192.168.0.42" --info "port=9922" \
  --info "username=prisoner" --info "passphrase=XXXXXX"
ares-novacom --device academia --getkey     # gera ~/.ssh/academia_webos

./install-tv.sh 192.168.0.42 XXXXXX academia
```

Se a outra TV **não** for webOS Lite e for de geração mais nova, vale testar o
`ares-install` primeiro: o problema do `ssh-rsa` é de TV antiga, e numa que
negocie algoritmo moderno a ferramenta oficial funciona e o roteio manual deixa
de ser necessário.

```sh
ares-install --device academia webos/*.ipk
```

## 8. Comandos úteis na TV

Todos com `-i`, em segundo plano, gravando em arquivo.

| Para que | URI |
| --- | --- |
| Listar apps de dev | `luna://com.webos.applicationManager/dev/listApps` |
| O que está rodando | `luna://com.webos.applicationManager/dev/running` |
| Abrir | `luna://com.webos.applicationManager/launch` |
| Fechar | `luna://com.webos.applicationManager/dev/closeByAppId` |
| Desinstalar | `luna://com.webos.appInstallService/dev/remove` |
| Info do sistema | `luna://com.webos.service.systemservice/osInfo/query` |

Diagnóstico: `/opt/devmode/usr/bin/` tem `strace`, `gdb` e `gdbserver`. Foi o
`strace -f -e trace=connect` que mostrou o socket `com.palm.hub` conectando com
sucesso e provou que o barramento não era o problema.

---

## 9. Escrever o app para TV: o que não é óbvio

Aprendido testando na TV de verdade, não no emulador.

- **Chromium não faz navegação espacial.** As setas do controle **não movem o
  foco** sozinhas. Num app de TV, mover o foco é responsabilidade do app —
  deixar as setas "passarem para o navegador" resulta em OK funcionando e setas
  mortas.
- **O controle não gera `pointerdown`, gera `click`.** Qualquer botão que
  escute apenas eventos de ponteiro é inalcançável pelo controle. Use `click`
  como gatilho universal e o `pointerdown` só para repetição ao segurar.
- **Ao esconder um painel, o foco cai no `body`.** Se o elemento focado estava
  dentro dele, o controle parece morrer. Reposicione o foco ao abrir e fechar.
- **Não misture navegação e ação na mesma tecla.** As setas foram atalho de
  "pular etapa" quando nada estava focado, e depois de fechar os ajustes a tela
  alternava entre etapas sem explicação. Seta é navegação, sempre; ação nas
  letras.
- **`KeyboardEvent.code` pode não existir** em motor antigo. Tenha fallback
  para `keyCode`: 13 Enter, 32 Espaço, 37 a 40 setas.
- **Botão Voltar do controle é `keyCode` 461.** Deve fechar o painel aberto ou
  encerrar o app, que é o que a webOS espera.
- **A tecla se chama OK ou Select, nunca "Enter".** O texto na tela precisa
  falar a língua do controle. Detecte toque com `navigator.maxTouchPoints`, que
  acerta onde as media queries de `pointer` erram (TV Box reporta 0).
- **O foco precisa ser lido a 3 metros.** Contorno fino não serve: o item
  selecionado deve acender e crescer.
- **`gap` do flexbox não existe.** Exige Chromium 84 e a webOS 5.x roda 68. Não
  há aviso: todo espaçamento simplesmente vira zero, e aumentar o valor não
  muda nada. Use margem entre irmãos (`> * + * { margin-left: ... }`), que
  funciona em qualquer motor. Foi o erro que mais tempo demorou a ser visto,
  porque o sintoma — "os botões estão colados" — parece problema de valor.
- **CSS moderno pode não existir.** `inset` exige Chrome 87, `clamp()` e `min()`
  exigem 79, a unidade `dvh` exige 108. Declare sempre uma versão simples antes
  da moderna: motor antigo descarta a que não entende e fica com a anterior.
  Cuidado especial com o atalho `font:` contendo `clamp()` — se não parseia,
  leva peso e família junto.
- **Reserve margem contra overscan.** Quase toda TV corta a borda da imagem.
- **Fontes remotas dependem de internet.** Sem rede, cai para a fonte do
  sistema; tenha uma pilha de fallback real.
