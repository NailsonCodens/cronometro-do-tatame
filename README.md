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

## Uso

Abra o `index.html`. Toque no número para começar ou pausar.

Atalhos de teclado: espaço ou Enter começa/pausa, `R` zera, `S` pula a etapa,
`T` liga o modo TV.

No controle da TV o direcional já resolve. Em aparelho sem toque o foco começa
no botão principal, então OK/Enter inicia e pausa, e o direcional anda entre
zerar, iniciar, pular, tela cheia e ajustes — tudo alcançável sem mouse.

Com o foco fora dos botões o direcional vira atalho direto: direita pula a
etapa, esquerda zera, cima e baixo mexem no volume. As setas nunca são
sequestradas quando um botão está focado, senão a navegação do próprio
navegador da TV deixaria de funcionar.

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

### Aviso: webOS TV Lite não aceita sideload

Testado em 2026-08-31 numa LG **webOS TV Lite 5.6.2** (imagem
`starfish-atsc-secured`) e não funciona, apesar de todo o resto estar correto:

- Dev Mode ativo e SSH na porta 9922 funcionando (a TV só negocia `ssh-rsa`,
  então o OpenSSH moderno precisa de `-o HostKeyAlgorithms=+ssh-rsa`)
- `ares-install` não autentica: a lib `ssh2` embutida no CLI não aceita
  `ssh-rsa`, e ela não lê `~/.ssh/config`
- Instalando à mão dá no mesmo: `luna-send` é `rwx------ root`, e o
  `luna-send-pub` conecta no hub mas nenhuma chamada retorna nada

O erro que revela a causa aparece ao declarar um appId:

```
LUNASERVICE ERROR -1031: LSCallFromApplication with application ID
com.nailson.tatame but not privileged
```

O usuário `prisoner` do Dev Mode não tem privilégio no barramento Luna nessa
build, então `com.webos.appInstallService/dev/install` é inalcançável. O pacote
aqui é válido e deve instalar numa webOS TV normal — em Lite, não.

Nessas TVs o caminho é o navegador da própria TV abrindo a URL publicada, que
já tem modo TV e navegação por controle.

## Arquivos

| Arquivo | Para que serve |
| --- | --- |
| `index.html` | O app inteiro, com a logo embutida |
| `logo-academia.png` | Logo da D.O Academy recortada no círculo, fundo transparente |
| `logo-academia.jpg` | Foto original da logo |
| `webos/appinfo.json` | Manifesto do app de TV LG |
| `webos/icon.png`, `largeIcon.png` | Ícones 80x80 e 130x130 exigidos pela webOS |
| `build-webos.sh` | Copia o index.html e gera o `.ipk` |
