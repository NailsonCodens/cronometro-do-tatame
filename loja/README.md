# Materiais para a LG Content Store

O que está pronto aqui e o que ainda depende de você.

## Pronto

| Arquivo | Para que serve |
| --- | --- |
| `1-rola-comecando.png` … `5-tela-inicial.png` | Capturas em 1280x720, geradas do app real |
| `icone-400.png` | Ícone 400x400 para a listagem da loja |
| `ux-scenario.md` | Documento de cenário de UX exigido pela LG, em inglês |
| `../webos/*.ipk` | O pacote, gerado por `./build-webos.sh` |

As capturas foram feitas com Chrome headless a partir do próprio `index.html`,
com as transições desligadas — sem isso o tempo virtual do headless congela as
cores no estado inicial.

## Falta, e só você consegue

1. **Conta no LG Seller Lounge** (seller.lgappstv.com), com os dados fiscais.
2. **Self-checklist**: a LG exige a versão MAIS RECENTE do formulário, baixada
   do Seller Lounge, preenchida com resultados de teste reais numa TV física.
   Enviar uma versão antiga do formulário é rejeição automática.
3. **Classificação de conteúdo** e categoria, preenchidas no formulário.
4. **Confirmar os tamanhos de imagem** exigidos: eles aparecem no formulário de
   submissão e mudam de tempos em tempos.

## Uma decisão antes de enviar

O app mostra o **brasão da D.O Academy**. Numa listagem pública da loja isso
levanta duas questões: a LG pode pedir comprovação de direito sobre a marca, e
um app com a marca de uma academia específica faz menos sentido para o público
geral da loja.

Duas saídas:

- **Publicar sem o brasão**, como cronômetro genérico de jiu-jitsu. Mais fácil
  de aprovar e mais útil para outras academias.
- **Publicar com o brasão**, tendo em mãos a comprovação de que a marca é da
  academia.

O brasão está embutido como data URI no `index.html`; tirá-lo é uma alteração
pequena.
