#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — 설치 → 폴더·양식 생성 → 시크릿 → 검증을 한 번에 (macOS/Linux)
#
# 사용법:
#   bash bootstrap.sh <프로젝트_절대경로> [--install] [--with-r]
#     <프로젝트_절대경로> : 01_manuscript / 02_anal / AGENTS.md 가 생길 프로젝트 루트
#     --install           : 먼저 install.sh 로 Quarto/Obsidian/Zotero 설치
#     --with-r            : (install 시) R + 렌더 패키지도 설치 (R은 선택)
#
# 분석 도구는 중립입니다(R/Python/MATLAB 무엇이든). 02_anal 폴더는 도구 이름을 쓰지 않습니다.
# render_with_insertions.R(마커·표 삽입)만 R이 필요하며, R 없이는 `quarto render manuscript.md`를 씁니다.
# ============================================================
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../references/install
REF="$(dirname "$SELF_DIR")"                                # .../references
FMT="$REF/manuscript_format"
SCR="$REF/scripts"

PROJECT=""; DO_INSTALL=0; WITH_R=0
for a in "$@"; do
  case "$a" in
    --install) DO_INSTALL=1 ;;
    --with-r)  WITH_R=1 ;;
    -*) echo "알 수 없는 옵션: $a" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$a" ;;
  esac
done
if [ -z "$PROJECT" ]; then
  echo "사용법: bash bootstrap.sh <프로젝트_절대경로> [--install] [--with-r]"; exit 1
fi

ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
say(){ printf "\n\033[1m%s\033[0m\n" "$1"; }

# ---- 0) 선택: 도구 설치 ----
if [ "$DO_INSTALL" -eq 1 ]; then
  say "[0] 도구 설치 (install.sh)"
  if [ "$WITH_R" -eq 1 ]; then bash "$SELF_DIR/install.sh" --with-r || true
  else bash "$SELF_DIR/install.sh" || true; fi
fi

MS="$PROJECT/01_manuscript"

# ---- 1) 폴더 구조 (도구 중립) ----
say "[1] 폴더 구조 생성: $PROJECT"
mkdir -p "$MS"/{01_source/{styles,notes},02_literature/{pdfs,notes},03_assets/figures,04_synced/{tables/{main,supplementary},figures},05_output,_scripts/lit,_logs/literature,_archive}
# 02_anal: 도구 이름 없는 중립 구조 + data 의 00_raw
mkdir -p "$PROJECT/02_anal"/{00_code,01_data/{00_raw,01_interim,02_final},02_meta_data,03_results/06_reporting/{docs/{main,supplementary},figures/{main,supplementary},tables/{main,supplementary}},04_docs}
ok "01_manuscript / 02_anal (중립 구조, data: 00_raw·01_interim·02_final)"

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

# ---- 4) Obsidian 스타터 ----
say "[4] Obsidian 스타터 설정"
if [ -d "$MS/.obsidian" ]; then
  echo "  기존 .obsidian/ 존재 → Shell commands 설정만 보강(덮어쓰지 않음)."
  mkdir -p "$MS/.obsidian/plugins/obsidian-shellcommands"
  cp "$SELF_DIR/obsidian_starter/.obsidian/plugins/obsidian-shellcommands/data.json" "$MS/.obsidian/plugins/obsidian-shellcommands/data.json" 2>/dev/null || true
else
  cp -R "$SELF_DIR/obsidian_starter/.obsidian" "$MS/.obsidian"
  ok ".obsidian 스타터 복사 (커뮤니티 플러그인은 Obsidian Browse로 설치)"
fi

# ---- 5) 시크릿 저장소 (Zotero API 키) ----
say "[5] 시크릿 저장소 (_secrets, Zotero API 키)"
mkdir -p "$PROJECT/_secrets"
cp "$SELF_DIR/secrets/zotero.env.example" "$PROJECT/_secrets/" 2>/dev/null || true
cp "$SELF_DIR/secrets/set_zotero_key.sh" "$SELF_DIR/secrets/set_zotero_key.ps1" "$SELF_DIR/secrets/README.md" "$PROJECT/_secrets/" 2>/dev/null || true
chmod +x "$PROJECT/_secrets/set_zotero_key.sh" 2>/dev/null || true
# 프로젝트 루트 .gitignore (시크릿 보호)
GI="$PROJECT/.gitignore"
if ! grep -q "_secrets/zotero.env" "$GI" 2>/dev/null; then
  { echo ".DS_Store"; echo "_secrets/zotero.env"; echo "_secrets/*.env"; echo "!_secrets/*.example"; } >> "$GI"
fi
ok "_secrets/(zotero.env.example, set_zotero_key.sh/.ps1, README) + .gitignore 보호"

# ---- 6) AGENTS.md ----
say "[6] AGENTS.md 템플릿 배치"
if [ ! -f "$PROJECT/AGENTS.md" ]; then
  cp "$REF/AGENTS_TEMPLATE.md" "$PROJECT/AGENTS.md"
  ok "AGENTS.md 생성 — <...> 플레이스홀더 채우기"
else
  echo "  AGENTS.md 이미 존재 → 유지"
fi

# ---- 7) 검증 ----
say "[7] 검증"
bash "$SELF_DIR/verify.sh" "$MS" || true

# ---- 8) 다음 단계 ----
say "다음 (직접) 할 일"
cat <<EOF
  1) Zotero: Better BibTeX auto-export → $MS/01_source/references.bib  (install/zotero_bbt_setup.md)
  2) Zotero API 키 저장:  bash "$PROJECT/_secrets/set_zotero_key.sh"
  3) Obsidian: $MS 를 vault로 열고 Shell commands/Citations/Dataview 설치
  4) AGENTS.md 의 <...>(분석 경로·Zotero 컬렉션 등) 채우기
  5) (R 분석이면) sync_reporting_assets.R 의 reporting_root 를 02_anal/03_results/06_reporting 또는 실제 경로로 확인
  6) render_with_insertions.R 의 표/그림 마커 매핑을 이 논문 실제 표/그림으로 수정
  7) 렌더: cd "$MS" && Rscript _scripts/render_with_insertions.R   (R 없으면: quarto render manuscript.md)
EOF
echo ""
echo "부트스트랩 완료."
