#!/usr/bin/env bash
# ============================================================
# set_zotero_key.sh — Zotero API 키를 _secrets/zotero.env 에 저장 (gitignore, 권한 600)
#
# ★ 가장 확실한 방법: 키를 명령 인자로 바로 전달(붙여넣기). 대화형 입력이 안 되는
#   터미널에서도 항상 동작합니다.
#     bash set_zotero_key.sh <API_KEY> <USER_ID>
#   예) bash set_zotero_key.sh P9xAbC123... 1234567
#
# 인자를 생략하면 대화형으로 물어봅니다(입력이 화면에 보입니다 — 일부러 안 가립니다,
# 가리면 일부 터미널에서 입력 자체가 안 되는 문제가 있어서).
# ============================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/zotero.env"

KEY="${1:-}"
ZID="${2:-}"

if [ -z "$KEY" ]; then
  printf "Zotero API key 를 붙여넣고 Enter: "
  IFS= read -r KEY
fi
if [ -z "$ZID" ]; then
  printf "Zotero userID(숫자, https://www.zotero.org/settings/keys 에 표시) 를 입력하고 Enter: "
  IFS= read -r ZID
fi

if [ -z "$KEY" ] || [ -z "$ZID" ]; then
  echo "키와 userID가 모두 필요합니다. 예: bash set_zotero_key.sh <API_KEY> <USER_ID>" >&2
  exit 1
fi

umask 077
printf 'ZOTERO_API_KEY=%s\nZOTERO_USER_ID=%s\nZOTERO_LIBRARY_TYPE=user\n' "$KEY" "$ZID" > "$ENV_FILE"
chmod 600 "$ENV_FILE" 2>/dev/null || true
echo "저장 완료: $ENV_FILE  (git 추적 안 됨). 키 길이 ${#KEY}자, userID $ZID."
