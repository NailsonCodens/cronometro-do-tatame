#!/bin/sh
# Empacota o app para TV LG (webOS). O index.html tem uma cópia só, na raiz:
# ele é copiado para webos/ na hora de empacotar, para não haver duas versões
# divergindo. Só arquivos do app moram em webos/.
set -e
cd "$(dirname "$0")"

if ! command -v ares-package >/dev/null 2>&1; then
  echo "ares-package não encontrado. Instale com:"
  echo "  npm install -g @webos-tools/cli --registry=https://registry.npmjs.org/"
  exit 1
fi

# Num app webOS a resolução vem do appinfo.json. Deixar a meta viewport faz o
# motor antigo montar a página num viewport do dobro do tamanho e mostrar só o
# quadrante superior esquerdo — no navegador ela é essencial, no app estorva.
sed '/name="viewport"/d' index.html > webos/index.html
rm -f webos/*.ipk
ares-package webos --outdir webos

echo
echo "Pacote em webos/. Para instalar na TV:"
echo
echo "  1. Na TV: Content Store -> instale 'Developer Mode' -> entre com sua"
echo "     conta LG -> ligue Dev Mode. Anote o IP mostrado na tela."
echo
echo "  2. ares-setup-device --add tv --info \"host=<IP-DA-TV>\" \\"
echo "       --info \"port=9922\" --info \"username=prisoner\""
echo "  3. ares-novacom --device tv --getkey     # pede a senha exibida na TV"
echo "  4. ares-install --device tv webos/*.ipk"
echo "  5. ares-launch --device tv com.nailson.tatame"
