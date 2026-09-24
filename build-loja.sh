#!/bin/sh
# Gera a versão para a LG Content Store: sem o brasão da academia e com ícone
# próprio. A versão das TVs da academia continua sendo o build-webos.sh.
#
# Duas diferenças de propósito:
#   - o brasão sai (marca de terceiro numa listagem pública pede comprovação
#     de direito, e serve mal ao público geral da loja)
#   - o id do app é outro, então as duas versões convivem na mesma TV
set -e
cd "$(dirname "$0")"

# A LG recomenda dois pacotes, 1280x720 e 1920x1080: enviando só o de 720p a
# imagem fica pior nos modelos UHD. Como o layout é todo em vh/vw, o mesmo HTML
# serve aos dois — muda apenas a resolução declarada no appinfo.json.
SAIDA=webos-loja
mkdir -p "$SAIDA"

# 1. o app, sem a meta viewport (a resolução vem do appinfo) e sem o brasão
python3 - <<'PY'
import re, sys
s = open("index.html", encoding="utf-8").read()

s = re.sub(r'<meta name="viewport"[^>]*>\n?', '', s)

antes = len(s)
s, n = re.subn(r'\s*<img class="crest"[^>]*>', '', s)
if n != 1:
    sys.exit("esperava exatamente 1 brasão, encontrei %d" % n)
print("  brasão removido: %.0f kB a menos" % ((antes - len(s)) / 1024))

# Sem o brasão sobra altura; o relógio cresce para ocupá-la.
s, n = re.subn(r'body\.tv-mode \.clock\{ font-size:36vh; \}',
               'body.tv-mode .clock{ font-size:46vh; }', s)
if n != 1:
    sys.exit("esperava 1 regra de tamanho do relógio, encontrei %d" % n)
print("  relógio ampliado de 36vh para 46vh")

open("webos-loja/index.html", "w", encoding="utf-8").write(s)
PY

# 2. ícones genéricos
cp loja/icone-generico-80.png  "$SAIDA/icon.png"
cp loja/icone-generico-130.png "$SAIDA/largeIcon.png"

command -v ares-package >/dev/null 2>&1 || {
  echo "ares-package não encontrado. npm install -g @webos-tools/cli --registry=https://registry.npmjs.org/"
  exit 1
}

# 3. um pacote por resolução, mesmo id e mesma versão
for RES in 1280x720 1920x1080; do
  DIR="$SAIDA/$RES"
  rm -rf "$DIR"; mkdir -p "$DIR"
  cp "$SAIDA/index.html" "$DIR/index.html"
  cp "$SAIDA/icon.png" "$SAIDA/largeIcon.png" "$DIR/"
  sed "s/__RES__/$RES/" > "$DIR/appinfo.json" <<'JSON'
{
  "id": "com.nailson.cronometrotatame",
  "version": "1.0.0",
  "vendor": "Nailson Israel",
  "type": "web",
  "main": "index.html",
  "title": "Cronômetro do Tatame",
  "appDescription": "Cronômetro de rolas para treino de jiu-jitsu",
  "icon": "icon.png",
  "largeIcon": "largeIcon.png",
  "bgColor": "#07090C",
  "resolution": "__RES__",
  "disableBackHistoryAPI": true
}
JSON
  ares-package "$DIR" --outdir "$DIR" >/dev/null
  echo "  $RES  ->  $(ls $DIR/*.ipk)  ($(du -h $DIR/*.ipk | cut -f1))"
done

rm -f "$SAIDA"/icon.png "$SAIDA"/largeIcon.png "$SAIDA"/index.html
