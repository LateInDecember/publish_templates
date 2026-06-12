#!/usr/bin/env bash
# ============================================================
# install.sh — Quarto · Obsidian · Zotero 설치 (R은 선택) — macOS / Linux
# 사용법:
#   bash install.sh             # R 없이 (Quarto/Obsidian/Zotero)
#   bash install.sh --with-r    # R + 렌더 패키지까지
#
# R은 선택입니다. render_with_insertions.R(마커·표 삽입)는 R이 필요하지만,
# R을 안 쓰면 분석을 Python/MATLAB 등으로 하고 원고는 `quarto render manuscript.md`로 렌더하면 됩니다.
# GUI 앱(Obsidian/Zotero)은 설치만 자동, 플러그인 승인·BBT export 지정은 앱에서 직접.
# ============================================================
set -uo pipefail

WITH_R=0
for a in "$@"; do [ "$a" = "--with-r" ] && WITH_R=1; done

R_PACKAGES='c("officer","png","stringr","xml2","zip")'
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
echo "== OS: $OS  (R 설치: $([ $WITH_R -eq 1 ] && echo 예 || echo 아니오, --with-r 로 켜기)) =="

install_mac() {
  if ! have brew; then
    warn "Homebrew가 없습니다. 먼저 설치: https://brew.sh"
    return 1
  fi
  ok "Homebrew 발견"
  echo "-- Quarto --";   have quarto || brew install --cask quarto;   have quarto && ok "quarto $(quarto --version)"
  echo "-- Obsidian --"; brew list --cask obsidian >/dev/null 2>&1 || brew install --cask obsidian; ok "Obsidian"
  echo "-- Zotero --";   brew list --cask zotero   >/dev/null 2>&1 || brew install --cask zotero;   ok "Zotero"
  if [ $WITH_R -eq 1 ]; then
    echo "-- R --"; have R || brew install --cask r; have R && ok "$(R --version | head -1)"
  fi
}

install_linux() {
  echo "-- Quarto --"
  if have quarto; then ok "quarto $(quarto --version)"
  else
    ARCH="$(uname -m)"; case "$ARCH" in x86_64) QA=amd64;; aarch64|arm64) QA=arm64;; *) QA=amd64;; esac
    warn "Quarto는 https://quarto.org/docs/get-started/ 에서 linux-$QA .deb를 받아 'sudo dpkg -i' 로 설치."
  fi
  echo "-- Obsidian --"; warn "Obsidian: https://obsidian.md/download (flatpak: md.obsidian.Obsidian)"
  echo "-- Zotero --";   warn "Zotero: https://www.zotero.org/download/ (flatpak: org.zotero.Zotero)"
  if [ $WITH_R -eq 1 ]; then
    echo "-- R --"
    if have R; then ok "$(R --version | head -1)"
    elif have apt-get; then sudo apt-get update -qq && sudo apt-get install -y r-base && ok "R 설치"
    else warn "apt 미발견. R 수동 설치: https://cloud.r-project.org/"; fi
  fi
}

case "$OS" in
  Darwin) install_mac ;;
  Linux)  install_linux ;;
  *) warn "지원 외 OS($OS). Windows는 install.ps1을 사용하세요." ;;
esac

if [ $WITH_R -eq 1 ]; then
  echo "-- R 렌더 패키지 --"
  if have Rscript; then
    Rscript -e "pkgs <- ${R_PACKAGES}; miss <- pkgs[!pkgs %in% rownames(installed.packages())]; if(length(miss)) install.packages(miss, repos='https://cloud.r-project.org'); cat('R render packages ready\n')" \
      && ok "R 패키지 확인/설치 완료" || warn "R 패키지 설치 실패 — 수동: Rscript -e 'install.packages(${R_PACKAGES})'"
  else
    warn "Rscript 미발견 — R 설치 후 다시 실행."
  fi
else
  warn "R 건너뜀(--with-r 로 설치). render_with_insertions.R는 R이 필요; R 없이는 'quarto render manuscript.md' 사용."
fi

echo ""
echo "== 다음 GUI 단계(직접) =="
echo "  1) Zotero Better BibTeX → 컬렉션을 01_manuscript/01_source/references.bib 로 auto-export(Keep updated)."
echo "  2) Obsidian에서 01_manuscript/ vault 열기 → Shell commands/Citations/Dataview 설치."
echo "  3) Zotero API 키는 _secrets/ 에 저장: bash _secrets/set_zotero_key.sh"
echo "  검증: bash verify.sh <01_manuscript 경로>"
