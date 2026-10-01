# Defeito QA2026093023459

**Relatado:** App Icon Background does not match the tile color (P2)

**Causa real:** o campo "Set an App Tile Color", em Applications > Edit >
Images, estava em `#000000`, enquanto o fundo do ícone é `#0B1016`. A LG exige
que sejam exatamente iguais.

**Correção:** trocar o campo do formulário para `#0B1016`. Não exige reenviar o
pacote nem alterar a imagem do ícone.

O requisito de "fundo em cor sólida, sem gradiente" já era atendido: o fundo é
chapado e o anel são quatro segmentos de cor sólida.

Texto para a resposta do chamado:

```
Fixed.

The App Tile Color field was set to #000000 while the app icon background is
#0B1016. The tile colour has been updated to #0B1016, so it now matches the
icon background exactly.

The icon image itself was not changed. Its background is a single solid colour
and the ring is drawn with four solid segments, with no gradient anywhere.
```
