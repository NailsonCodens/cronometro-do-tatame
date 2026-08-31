# Cronômetro do Tatame

Cronômetro de rolas para treino de jiu-jitsu. Um arquivo HTML só, sem build e
sem dependência: abre no celular, no navegador ou em qualquer hospedagem estática.

## Como funciona

- Rola de 5 minutos, 1 minuto de descanso e emenda no próximo — tudo configurável
- Buzina no fim de cada tempo e bipes nos últimos 10 segundos, os 3 finais mais agudos
- Encaixa em pé e deitado; o número ocupa a tela toda
- Segura a tela acesa enquanto o cronômetro roda (Screen Wake Lock)
- Os ajustes ficam salvos no aparelho
- Modo TV para usar espelhado ou num TV Box: tudo maior e com margem contra o
  overscan que quase toda TV aplica
- A cor do rola esquenta ao longo do tempo: verde no começo, amarelo, laranja e
  vermelho no fim, com uma curva que segura o verde e despenca nos últimos
  segundos. O descanso fica azul, sem gradiente, para separar as duas coisas de
  longe

## Uso

Abra o `index.html`. Toque no número para começar ou pausar.

Atalhos de teclado: espaço ou Enter começa/pausa, `R` zera, `S` pula a etapa,
`T` liga o modo TV.

No controle da TV o direcional já resolve. Em aparelho sem toque o foco começa
no botão principal, então OK/Enter inicia e pausa, e o direcional anda entre
zerar, iniciar, pular, tela cheia e ajustes — tudo alcançável sem mouse.

As setas são **sempre** navegação, nunca atalho de ação. Elas já foram atalho
e isso causou um bug ruim: ao fechar os ajustes o foco caía no `body`, a seta
direita virava "pular etapa" e a tela alternava entre rola e descanso sem
explicação. Atalhos de ação ficam nas letras: `R` zera, `S` pula, `+` e `-`
mexem no volume.

Abrir e fechar os ajustes reposiciona o foco em aparelho sem toque, senão o
elemento focado desaparece junto com o painel e o controle parece morrer.

Para um aparelho que fica fixo na academia, abrir com `?tv=1` no fim da URL já
entra no modo TV sem precisar mexer nos ajustes.

## Detalhes de implementação

- O tempo vem do relógio do sistema (`Date.now`), não de contagem de ticks, então
  não acumula erro e se realinha quando o celular volta do bloqueio.
- Os avisos são agendados no relógio do Web Audio no início de cada etapa, o que
  mantém o som na hora certa mesmo se o navegador segurar o JavaScript em
  segundo plano.
- Os sons vivem entre 500 Hz e 2 kHz: alto-falante de celular quase não reproduz
  grave, e essa é a faixa que corta o barulho da academia.
- Cada dígito ocupa um box de largura fixa porque a fonte Big Shoulders não tem
  tabular figures — sem isso os dois pontos saem do centro e o número escorrega
  a cada segundo.

## App para TV LG (webOS)

O mesmo `index.html` roda como app nativo de webOS — apps de TV LG são HTML,
CSS e JS, então não há reescrita, só empacotamento. Numa TV o modo TV liga
sozinho, detectado pelo user agent, e o botão Voltar do controle fecha o app.

Para gerar o pacote:

```sh
npm install -g @webos-tools/cli --registry=https://registry.npmjs.org/
./build-webos.sh
```

Sai um `.ipk` de ~180 KB em `webos/`. Para instalar na TV, sem loja e sem
revisão:

1. Na TV, pela Content Store, instale o app **Developer Mode**, entre com sua
   conta LG e ligue o Dev Mode. Anote o IP mostrado na tela.
2. `ares-setup-device --add tv --info "host=<IP>" --info "port=9922" --info "username=prisoner"`
3. `ares-novacom --device tv --getkey` — pede a senha exibida na TV
4. `ares-install --device tv webos/*.ipk`
5. `ares-launch --device tv com.nailson.tatame`

A sessão de desenvolvedor da LG expira a cada ~50 horas; renova-se pelo app
Developer Mode na TV, sem reinstalar nada.

### O ares-install não funciona: use o install-tv.sh

Testado em 2026-08-31 numa LG **webOS TV Lite 5.6.2** (imagem
`starfish-atsc-secured`). A instalação funciona, mas não pela ferramenta oficial:

- A TV negocia **somente o algoritmo `ssh-rsa`**. O OpenSSH moderno recusa por
  padrão e precisa de `-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa`.
- O `ares-install` usa a lib `ssh2` embutida, que também recusa `ssh-rsa` e
  **não lê `~/.ssh/config`** — então não há como configurar. Ele falha com
  "All configured authentication methods failed".

O `install-tv.sh` contorna isso usando o ssh do sistema e chamando o mesmo
serviço Luna que o ares-install chamaria:

```sh
ares-novacom --device tv --getkey        # uma vez, pede a passphrase da TV
./install-tv.sh 192.168.1.60 C0D62C      # IP e passphrase do Key Server
```

O mesmo comando serve para **atualizar**: ele reempacota o `index.html` atual,
reinstala em cima e reabre o app. Não precisa desinstalar nada.

### Navegação por controle: o app tem que implementar

Chromium **não faz navegação espacial**, então as setas do controle não movem o
foco sozinhas — num app de TV isso é responsabilidade do app. A primeira versão
deixava as setas para o navegador e o resultado era OK funcionando e setas
mortas. O `navigate()` no código percorre grupos que são as faixas visuais da
tela: setas laterais andam dentro do grupo, verticais trocam de grupo. O
`keyName()` cai para `keyCode` porque motor antigo de TV pode não ter
`KeyboardEvent.code`.

Duas armadilhas que custaram tempo e valem registro:

1. **`luna-send-pub` precisa da flag `-i`.** Com `-n 1` ele sai antes da
   resposta chegar e imprime nada — o que parece um bloqueio de permissão e não
   é. Como `-i` não termina sozinho, roda em segundo plano e mata-se depois.
2. **`luna-send` é exclusivo do root** (`rwx------`), mas o `luna-send-pub` é
   executável por todos e alcança `com.webos.appInstallService/dev/install`.
   O usuário `prisoner` do Dev Mode tem privilégio suficiente.

## Arquivos

| Arquivo | Para que serve |
| --- | --- |
| `index.html` | O app inteiro, com a logo embutida |
| `logo-academia.png` | Logo da D.O Academy recortada no círculo, fundo transparente |
| `logo-academia.jpg` | Foto original da logo |
| `webos/appinfo.json` | Manifesto do app de TV LG |
| `webos/icon.png`, `largeIcon.png` | Ícones 80x80 e 130x130 exigidos pela webOS |
| `build-webos.sh` | Copia o index.html e gera o `.ipk` |
| `install-tv.sh` | Envia e instala o `.ipk` na TV por Dev Mode |
