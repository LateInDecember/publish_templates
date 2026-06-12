#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — 설치 → 폴더·양식 생성 → 검증을 한 번에 (macOS/Linux)
#
# 사용법:
#   bash bootstrap.sh <프로젝트_절대경로> [--install]
#     <프로젝트_절대경로>  : 01_manuscript / 02_anal / AGENTS.md 가 생길 프로젝트 루트
#     --install            : 먼저 install.sh로 Quarto/R/Obsidian/Zotero 설치 시도
#
# 예:
#   bash bootstrap.sh "/Users/me/Papers/01_loneliness" --install
# ============================================================
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../references/install
REF="$(dirname "$SELF_DIR")"                                # .../references
FMT="$REF/manuscript_format"
SCR="$REF/scripts"

PROJECT="${1:-}"
DO_INSTALL="${2:-}"
if [ -z "$PROJECT" ]; then
  echo "사용법: bash bootstrap.sh <프로젝트_절대경로> [--install]"; exit 1
fi

ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
say(){ printf "\n\033[1m%s\033[0m\n" "$1"; }

# ---- 0) 선택: 도구 설치 ----
if [ "$DO_INSTALL" = "--install" ]; then
  say "[0] 도구 설치 (install.sh)"
  bash "$SELF_DIR/install.sh" || echo "  (install.sh 일부 실패 — 수동 확인 필요)"
fi

MS="$PROJECT/01_manuscript"

# ---- 1) 폴더 구조 ----
say "[1] 폴더 구조 생성: $PROJECT"
mkdir -p "$MS"/{01_source/{styles,notes},02_literature/{pdfs,notes},03_assets/figures,04_synced/{tables/{main,supplementary},figures},05_output,_scripts/lit,_logs/literature,_archive}
mkdir -p "$PROJECT/02_anal/01_R"/{00_code,01_data/{01_interim,02_final},02_meta_data,03_results/06_reporting/{docs/{main,supplementary},figures/{main,supplementary},tables/{main,supplementary}},04_docs}
ok "01_manuscript / 02_anal 생성"

# ---- 2) 원고 양식 ----
say "[2] 원고 양식 배치"
[ -f "$MS/manuscript.md" ] || cp "$FMT/manuscript_skeleton.md" "$MS/manuscript.md"
cp "$FMT/_quarto.yml" "$MS/_quarto.yml"
cp -R "$FMT/styles/." "$MS/01_source/styles/"
cp "$FMT/journal_format_kjcbp_2020.md" "$FMT/journal_requirements.md" "$MS/01_source/notes/" 2>/dev/null || true
[ -f "$FMT/gitignore.template" ] && cp "$FMT/gitignore.template" "$MS/.gitignore"
ok "manuscript.md, _quarto.yml, styles, notes"

# ---- 3) 스크립트 ----
say "[3] 렌더·동기화 스크립트 배치"
cp "$SCR"/*.R "$MS/_scripts/" 2>/dev/null || true
cp "$SCR/render.command" "$MS/01_source/render.command"
chmod +x "$MS/01_source/render.command"
ok "_scripts/*.R, 01_source/render.command (+x)"

# ---- 4) Obsidian 스타터 (.obsidian) ----
say "[4] Obsidian 스타터 설정"
if [ -d "$MS/.obsidian" ]; then
  echo "  기존 .obsidian/ 존재 → Shell commands 설정만 보강(덮어쓰지 않음)."
  mkdir -p "$MS/.obsidian/plugins/obsidian-shellcommands"
  cp "$SELF_DIR/obsidian_starter/.obsidian/plugins/obsidian-shellcommands/data.json" "$MS/.obsidian/plugins/obsidian-shellcommands/data.json" 2>/dev/null || true
else
  cp -R "$SELF_DIR/obsidian_starter/.obsidian" "$MS/.obsidian"
  ok ".obsidian 스타터 복사 (커뮤니티 플러그인은 Obsidian에서 Browse로 설치 필요)"
fi

# ---- 5) AGENTS.md ----
say "[5] AGENTS.md 템플릿 배치"
if [ ! -f "$PROJECT/AGENTS.md" ]; then
  cp "$REF/AGENTS_TEMPLATE.md" "$PROJECT/AGENTS.md"
  ok "AGENTS.md 생성 — <...> 플레이스홀더를 실제 값으로 채우세요"
else
  echo "  AGENTS.md 이미 존재 → 유지"
fi

# ---- 6) 검증 ----
say "[6] 검증"
bash "$SELF_DIR/verify.sh" "$MS" || true

# ---- 7) 다음 단계 안내 ----
say "다음 (직접) 할 일"
cat <<EOF
  1) Zotero: Better BibTeX auto-export 를 $MS/01_source/references.bib 로 설정
     → install/zotero_bbt_setup.md 참고
  2) Obsidian: $MS 를 vault로 열고 Shell commands/Citations/Dataview 설치
     → install/obsidian_starter/README.md 참고
  3) AGENTS.md 의 <...> 플레이스홀더(분석 경로, Zotero 컬렉션 등) 채우기
  4) sync_reporting_assets.R 의 reporting_root 를 실제 분석 결과 폴더로 맞추기
  5) render_with_insertions.R 의 표/그림 마커 매핑을 이 논문 실제 표/그림으로 수정
  6) 렌더: cd "$MS" && Rscript _scripts/render_with_insertions.R
EOF
echo ""
echo "부트스트랩 완료."
