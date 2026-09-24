# Materiais para a LG Content Store

O que está pronto aqui e o que ainda depende de você.

## Pronto

| Arquivo | Para que serve |
| --- | --- |
| `1-rola-comecando.png` … `5-tela-inicial.png` | Capturas em 1280x720, geradas do app real |
| `icone-400.png` | Ícone 400x400 para a listagem da loja |
| `ux-scenario.md` | Documento de cenário de UX exigido pela LG, em inglês |
| `icone.svg` | Fonte vetorial do ícone; rasterize daqui em qualquer tamanho |
| `icone-quadrado.svg` | Mesma marca, fundo quadrado cheio |
| `icone-loja-1024.png` | **Ícone da listagem** (1024x1024, quadrado, sem gradiente no fundo) |
| `icone-generico-400/130/80.png` | Tamanhos menores, usados dentro do pacote |
| `splash-1920x1080.png` | Tela de abertura |
| `launcher-1920x1080.png` | Fundo no lançador da TV |
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
| Chipset | `All` — a própria tela manda isso para app Web |
| Service Platform | webOS 3.0 e acima |
| App Icon | `icone-loja-1024.png` |
| Splash / Launcher | `splash-1920x1080.png` e `launcher-1920x1080.png` |

São **dois arquivos**, mesmo app, mesma versão. A LG recomenda os dois porque
enviar só o de 720p degrada a imagem nos modelos UHD. O mesmo HTML serve aos
dois: o layout é em `vh/vw` e escala sozinho — o relógio sai com 291 px em 720p
e 457 px em 1080p, sem transbordar em nenhum dos dois (verificado).

### Regras das imagens que a LG impõe

- **Ícone:** 400x400 ou maior, quadrado, e **sem gradiente na cor de fundo**.
  O nosso usa fundo sólido `#0B1016` e quatro segmentos de cor chapada — a
  primeira versão do anel era um gradiente linear e teria esbarrado nessa
  regra, além de inverter a leitura de verde para vermelho.
- **Splash e launcher:** 1920x1080, JPG ou PNG até 10 MB.

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
