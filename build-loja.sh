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

# 3. manifesto com id próprio
cat > "$SAIDA/appinfo.json" <<'JSON'
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
  "resolution": "1280x720",
  "disableBackHistoryAPI": true
}
JSON

command -v ares-package >/dev/null 2>&1 || {
  echo "ares-package não encontrado. npm install -g @webos-tools/cli --registry=https://registry.npmjs.org/"
  exit 1
}
rm -f "$SAIDA"/*.ipk
ares-package "$SAIDA" --outdir "$SAIDA" >/dev/null
echo "  pacote: $(ls $SAIDA/*.ipk)  ($(du -h $SAIDA/*.ipk | cut -f1))"
