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

Num controle de TV Box ou tecladinho sem fio o direcional já resolve: Enter
começa e pausa, direita pula a etapa, esquerda zera, cima e baixo mexem no
volume.

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

## Arquivos

| Arquivo | Para que serve |
| --- | --- |
| `index.html` | O app inteiro, com a logo embutida |
| `logo-academia.png` | Logo da D.O Academy recortada no círculo, fundo transparente |
| `logo-academia.jpg` | Foto original da logo |
