#!/bin/sh
# Renova a sessão de Developer Mode das TVs LG pela API da própria LG.
#
# O botão EXTEND na TV dá 50 horas. Esta API dá 999 (~41 dias), e roda daqui,
# sem precisar mexer na TV. Quando a sessão expira, a LG DESINSTALA os apps
# instalados por Dev Mode — é por isso que o app "sumia do nada".
#
# O token fica em ~/.lg-devmode-tokens, um por linha, fora do repositório
# porque este repo é público. Para descobrir o token de uma TV:
#   ssh ... prisoner@<ip> 'cat /var/luna/preferences/devmode_enabled'
#
# Uso:  ./renova-devmode.sh          renova e mostra o tempo restante
set -e
ARQ="$HOME/.lg-devmode-tokens"
[ -f "$ARQ" ] || { echo "sem $ARQ"; exit 1; }

while IFS= read -r TOKEN; do
  [ -z "$TOKEN" ] && continue
  CURTO="$(printf '%s' "$TOKEN" | cut -c1-8)…"
  R=$(curl -s -m 30 "https://developer.lge.com/secure/ResetDevModeSession.dev?sessionToken=$TOKEN")
  C=$(curl -s -m 30 "https://developer.lge.com/secure/CheckDevModeSession.dev?sessionToken=$TOKEN")
  RESTA=$(printf '%s' "$C" | sed -n 's/.*"errorMsg":"\([^"]*\)".*/\1/p')
  case "$R" in
    *'"result":"success"'*) echo "$(date '+%Y-%m-%d %H:%M')  $CURTO  renovada, restam $RESTA" ;;
    *)                      echo "$(date '+%Y-%m-%d %H:%M')  $CURTO  FALHOU: $R" ;;
  esac
done < "$ARQ"
