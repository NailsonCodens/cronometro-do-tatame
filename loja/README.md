# Materiais para a LG Content Store

O que está pronto aqui e o que ainda depende de você.

## Pronto

| Arquivo | Para que serve |
| --- | --- |
| `1-rola-comecando.png` … `5-tela-inicial.png` | Capturas em 1280x720, geradas do app real |
| `icone-400.png` | Ícone 400x400 para a listagem da loja |
| `ux-scenario.md` | Documento de cenário de UX exigido pela LG, em inglês |
| `icone-generico-400/130/80.png` | Ícone próprio do app, sem marca de terceiro |
| `../webos-loja/1280x720/*.ipk` | Pacote para TVs Full HD e HD |
| `../webos-loja/1920x1080/*.ipk` | Pacote para TVs UHD |

As capturas foram feitas com Chrome headless a partir do próprio `index.html`,
com as transições desligadas — sem isso o tempo virtual do headless congela as
cores no estado inicial.

## Preencher no formulário de upload

| Campo | Valor |
| --- | --- |
| App ID | `com.nailson.cronometrotatame` |
| File Version | `1.0.0` (nos dois pacotes) |
| Resolution | um envio por pacote: `1280x720` e `1920x1080` |
| Deep Link | não usar |

São **dois arquivos**, mesmo app, mesma versão. A LG recomenda os dois porque
enviar só o de 720p degrada a imagem nos modelos UHD. O mesmo HTML serve aos
dois: o layout é em `vh/vw` e escala sozinho — o relógio sai com 291 px em 720p
e 457 px em 1080p, sem transbordar em nenhum dos dois (verificado).

## Falta, e só você consegue

1. **Conta no LG Seller Lounge** (seller.lgappstv.com), com os dados fiscais.
2. **Self-checklist**: a LG exige a versão MAIS RECENTE do formulário, baixada
   do Seller Lounge, preenchida com resultados de teste reais numa TV física.
   Enviar uma versão antiga do formulário é rejeição automática.
3. **Classificação de conteúdo** e categoria, preenchidas no formulário.
4. **Confirmar os tamanhos de imagem** exigidos: eles aparecem no formulário de
   submissão e mudam de tempos em tempos.

## Duas versões, de propósito

| | Academia | Loja |
| --- | --- | --- |
| Script | `./build-webos.sh` | `./build-loja.sh` |
| App ID | `com.nailson.tatame` | `com.nailson.cronometrotatame` |
| Brasão da D.O | sim | **não** |
| Ícone | o brasão | anel genérico |
| Relógio | 36vh | 46vh, ocupando o espaço do brasão |
| Pacote | 180 kB | **56 kB** |

Os ids são diferentes, então as duas convivem na mesma TV sem conflito: você
segue usando a versão com o brasão nas TVs da academia por Dev Mode, e a
genérica é a que vai para a loja.

Tirar o brasão evita que a LG peça comprovação de direito sobre a marca, e um
cronômetro genérico serve a qualquer academia — o que é o ponto de estar numa
loja pública.
