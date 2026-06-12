#!/usr/bin/env bash
# ============================================================
# set_zotero_key.sh — Zotero API 키를 안전하게 저장 (같은 폴더의 zotero.env)
#   - zotero.env 는 .gitignore 처리 + 권한 600 (소유자만 읽기/쓰기)
#   - 키를 화면/로그에 출력하지 않음 (붙여넣기는 가려짐)
#
# 사용법:
#   bash set_zotero_key.sh                      # 대화형: 키를 붙여넣기
#   bash set_zotero_key.sh <API_KEY> <USER_ID>  # 인자로 바로
# ============================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DIR/zotero.env"

KEY="${1:-}"
ZID="${2:-}"

if [ -z "$KEY" ]; then
  printf "Zotero API key 붙여넣기 (화면에 안 보임): "
  read -r -s KEY; echo
fi
if [ -z "$ZID" ]; then
  printf "Zotero userID (숫자, https://www.zotero.org/settings/keys 에 표시): "
  read -r ZID
fi

if [ -z "$KEY" ] || [ -z "$ZID" ]; then
  echo "키와 userID가 모두 필요합니다." >&2; exit 1
fi

umask 077
cat > "$ENV_FILE" <<EOF
ZOTERO_API_KEY=$KEY
ZOTERO_USER_ID=$ZID
ZOTERO_LIBRARY_TYPE=user
EOF
chmod 600 "$ENV_FILE"
echo "저장 완료: $ENV_FILE  (권한 600, git 추적 안 됨)"
echo "확인: 키 길이 ${#KEY}자 / userID $ZID  (키 값 자체는 출력하지 않음)"
