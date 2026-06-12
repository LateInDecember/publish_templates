#!/bin/bash
# ────────────────────────────────────────────────────────────
# 원고 렌더링 런처
# Finder에서 이 파일을 더블클릭하면 원고를 DOCX + HTML로 렌더합니다.
# (또는 터미널에서: bash "01_source/render.command")
#
# 내부적으로 실행되는 명령:
#   cd 01_manuscript
#   Rscript _scripts/render_with_insertions.R
#
# 렌더 전 R 분석 폴더의 최신 표·그림이 04_synced/로 자동 동기화됩니다.
# 결과물: 05_output/manuscript.docx, 05_output/manuscript.html
# ────────────────────────────────────────────────────────────
set -e
cd "$(dirname "$0")/.." || exit 1   # -> 01_manuscript

echo "원고 렌더링을 시작합니다…"
echo ""
Rscript _scripts/render_with_insertions.R
status=$?

echo ""
if [ $status -eq 0 ]; then
  echo "✅ 완료. 결과물:"
  echo "   05_output/manuscript.docx"
  echo "   05_output/manuscript.html"
else
  echo "❌ 렌더 중 오류가 발생했습니다 (위 메시지를 확인하세요)."
fi
echo ""
read -n 1 -s -r -p "아무 키나 누르면 창이 닫힙니다…"
echo ""
