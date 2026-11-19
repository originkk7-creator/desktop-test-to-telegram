#!/bin/bash
set -eu
BASE="$(cd "$(dirname "$0")" && pwd)"
if [ "${1:-}" != "--worker" ]; then
    nohup /bin/bash "$BASE/mac.command" --worker </dev/null >/dev/null 2>&1 &
    printf 'Sending Desktop folder in background. Log: %s/transfer.log\n' "$BASE"
    exit 0
fi
umask 077
TMP="$(mktemp -d)"
cleanup() { rm -f "$TMP/archive.zip" "$TMP/response.json"; rmdir "$TMP"; }
trap cleanup EXIT
failed() { printf '%s FAILED: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" >>"$BASE/transfer.log"; exit 1; }
TOKEN="$(tr -d '\r\n' <"$BASE/token.txt")"
CHAT="$(tr -d '\r\n' <"$BASE/chat-id.txt")"
FOLDER="$HOME/Desktop/тест"
[ -d "$FOLDER" ] || failed 'Desktop folder тест was not found'
# Store symlinks as links; do not follow them into other folders.
(cd "$HOME/Desktop" && /usr/bin/zip -q -r -y "$TMP/archive.zip" 'тест') || failed 'Cannot create ZIP; check Desktop privacy permissions'
SIZE="$(/usr/bin/stat -f %z "$TMP/archive.zip")"
[ "$SIZE" -le 49000000 ] || failed 'ZIP exceeds 49 MB'
if ! printf 'url = "https://api.telegram.org/bot%s/sendDocument"\n' "$TOKEN" | /usr/bin/curl --config - --silent --fail --max-time 1200 --form "chat_id=$CHAT" --form "document=@$TMP/archive.zip;filename=desktop-test-$(date '+%Y%m%d-%H%M%S').zip" --output "$TMP/response.json"; then
    failed 'Telegram upload failed; check network, token and chat ID'
fi
printf '%s SENT\n' "$(date '+%Y-%m-%dT%H:%M:%S')" >>"$BASE/transfer.log"
