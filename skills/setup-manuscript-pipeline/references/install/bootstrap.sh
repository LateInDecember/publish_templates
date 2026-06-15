#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — 설치 → 폴더·양식 생성 → 시크릿 → 검증을 한 번에 (macOS/Linux)
#
# 사용법:
#   bash bootstrap.sh <프로젝트_절대경로> [--no-install]
#     <프로젝트_절대경로> : 01_manuscript / 02_anal / AGENTS.md 가 생길 프로젝트 루트
#     (기본)              : Quarto·R·Obsidian·Zotero 를 install.sh 로 **자동 설치**
#     --no-install        : 설치를 건너뛰고 폴더·양식만 생성
#
# 이 스크립트는 기본적으로 도구를 **직접 설치**합니다(단순 안내 아님). Quarto·R은 필수입니다.
# 단, Cowork 샌드박스 같은 격리 셸에서는 사용자 컴퓨터에 설치할 수 없습니다 —
# 사용자 맥의 터미널, 또는 로컬 셸을 가진 에이전트(Codex CLI/Claude Code)에서 실행해야 실제로 설치됩니다.
# 분석 도구 폴더 02_anal 은 도구 중립 이름을 씁니다(R/Python/MATLAB 무엇이든).
# ============================================================
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../references/install
REF="$(dirname "$SELF_DIR")"                                # .../references
FMT="$REF/manuscript_format"
SCR="$REF/scripts"

PROJECT=""; DO_INSTALL=1
for a in "$@"; do
  case "$a" in
    --no-install) DO_INSTALL=0 ;;
    --install)    DO_INSTALL=1 ;;   # 기본값이지만 호환 위해 허용
    -*) echo "알 수 없는 옵션: $a" ;;
    *) [ -z "$PROJECT" ] && PROJECT="$a" ;;
  esac
done
if [ -z "$PROJECT" ]; then
  # 인자가 없으면 물어본다(더블클릭 런처용).
  printf "프로젝트 이름 (기본: my_manuscript): "; IFS= read -r _name; _name="${_name:-my_manuscript}"
  printf "어디에 만들까요 (기본: %s): " "$HOME/Documents"; IFS= read -r _base; _base="${_base:-$HOME/Documents}"
  PROJECT="$_base/$_name"
  echo "→ 프로젝트 경로: $PROJECT"
fi

ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
say(){ printf "\n\033[1m%s\033[0m\n" "$1"; }

# ---- 0) 도구 설치 (기본 실행; --no-install 로만 생략) ----
if [ "$DO_INSTALL" -eq 1 ]; then
  say "[0] 도구 설치 (install.sh) — Quarto·R·Obsidian·Zotero (필수)"
  bash "$SELF_DIR/install.sh" || echo "  ! 일부 설치 실패 — 위 메시지 확인. 격리 셸이면 사용자 맥에서 install.sh를 실행하세요."
else
  say "[0] 설치 건너뜀 (--no-install) — Quarto·R 없으면 렌더가 안 됩니다."
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
cp "$FMT/apa.csl" "$MS/01_source/apa.csl"
# 빈 references.bib (Zotero 연동 전에도 렌더가 깨지지 않도록). 이후 Better BibTeX auto-export가 덮어씀.
[ -f "$MS/01_source/references.bib" ] || printf '%% references.bib — Zotero Better BibTeX auto-export target (currently empty).\n%% See install/zotero_bbt_setup.md to connect Zotero.\n' > "$MS/01_source/references.bib"
cp "$FMT/journal_format_kjcbp_2020.md" "$FMT/journal_requirements.md" "$MS/01_source/notes/" 2>/dev/null || true
[ -f "$FMT/gitignore.template" ] && cp "$FMT/gitignore.template" "$MS/.gitignore"
ok "manuscript.md, _quarto.yml, apa.csl, references.bib(빈), styles, notes"

# ---- 3) 스크립트 ----
say "[3] 렌더·동기화 스크립트 배치"
cp "$SCR"/*.R "$MS/_scripts/" 2>/dev/null || true
cp "$SCR/render.command" "$MS/01_source/render.command" 2>/dev/null || true
cp "$SCR/render.bat" "$MS/01_source/render.bat" 2>/dev/null || true
chmod +x "$MS/01_source/render.command" 2>/dev/null || true
ok "_scripts/*.R, 01_source/render.command(mac)+render.bat(win)"

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
  5) sync_reporting_assets.R 의 reporting_root 를 02_anal/03_results/06_reporting 또는 실제 분석 결과 경로로 확인
  6) render_with_insertions.R 의 표/그림 마커 매핑을 이 논문 실제 표/그림으로 수정
  7) 렌더: cd "$MS" && Rscript _scripts/render_with_insertions.R
EOF
echo ""
echo "부트스트랩 완료."
