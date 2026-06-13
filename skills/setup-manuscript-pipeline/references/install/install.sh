#!/usr/bin/env bash
# ============================================================
# install.sh — Quarto · R(+패키지) · Obsidian · Zotero 설치 (macOS / Linux)
# 사용법:  bash install.sh
#
# 이 스크립트는 단순히 "안내"하지 않고 가능한 한 **직접 설치**합니다.
# (단, Cowork 샌드박스 같은 격리 셸에서는 사용자 컴퓨터에 설치할 수 없습니다 —
#  사용자 맥의 터미널, 또는 로컬 셸을 가진 에이전트(Codex CLI/Claude Code)에서 실행해야 실제로 설치됩니다.)
#
# R은 필수입니다(원고 렌더 render_with_insertions.R가 R 기반).
# GUI 앱(Obsidian/Zotero)은 설치만 자동, 플러그인 승인·BBT export 지정은 앱에서 직접.
# ============================================================
set -uo pipefail

R_PACKAGES='c("officer","png","stringr","xml2","zip")'
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
bad()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
echo "== 설치 시작 (OS: $OS) =="

install_mac() {
  if ! have brew; then
    bad "Homebrew가 없습니다. 자동 설치를 위해 먼저 Homebrew를 설치하세요: https://brew.sh"
    echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 1
  fi
  ok "Homebrew 발견"
  echo "-- Quarto --";   have quarto || brew install --cask quarto;   have quarto && ok "quarto $(quarto --version)" || bad "Quarto 설치 실패"
  echo "-- R --";        have R      || brew install --cask r;        have R && ok "$(R --version | head -1)" || bad "R 설치 실패"
  echo "-- Obsidian --"; brew list --cask obsidian >/dev/null 2>&1 || brew install --cask obsidian; ok "Obsidian"
  echo "-- Zotero --";   brew list --cask zotero   >/dev/null 2>&1 || brew install --cask zotero;   ok "Zotero"
}

install_linux() {
  echo "-- R --"
  if have R; then ok "$(R --version | head -1)"
  elif have apt-get; then sudo apt-get update -qq && sudo apt-get install -y r-base && ok "R 설치" || bad "R 설치 실패"
  else bad "apt 미발견. R 수동 설치: https://cloud.r-project.org/"; fi

  echo "-- Quarto --"
  if have quarto; then ok "quarto $(quarto --version)"
  else
    ARCH="$(uname -m)"; case "$ARCH" in x86_64) QA=amd64;; aarch64|arm64) QA=arm64;; *) QA=amd64;; esac
    warn "Quarto는 https://quarto.org/docs/get-started/ 에서 linux-$QA .deb 받아 'sudo dpkg -i' 로 설치."
  fi
  echo "-- Obsidian --"; warn "Obsidian: https://obsidian.md/download (flatpak: md.obsidian.Obsidian)"
  echo "-- Zotero --";   warn "Zotero: https://www.zotero.org/download/ (flatpak: org.zotero.Zotero)"
}

case "$OS" in
  Darwin) install_mac ;;
  Linux)  install_linux ;;
  *) bad "지원 외 OS($OS). Windows는 install.ps1을 사용하세요." ;;
esac

# R 렌더 패키지 (필수)
echo "-- R 렌더 패키지 --"
if have Rscript; then
  Rscript -e "pkgs <- ${R_PACKAGES}; miss <- pkgs[!pkgs %in% rownames(installed.packages())]; if(length(miss)) install.packages(miss, repos='https://cloud.r-project.org'); cat('R render packages ready\n')" \
    && ok "R 패키지(officer,png,stringr,xml2,zip)" || bad "R 패키지 설치 실패 — 수동: Rscript -e 'install.packages(${R_PACKAGES})'"
else
  bad "Rscript 미발견 — R 설치가 안 됐습니다(필수). 위 R 설치를 먼저 해결하세요."
fi

echo ""
echo "== 다음 GUI 단계(직접) =="
echo "  1) Zotero Better BibTeX → 컬렉션을 01_manuscript/01_source/references.bib 로 auto-export(Keep updated)."
echo "  2) Obsidian에서 01_manuscript/ vault 열기 → Shell commands/Citations/Dataview 설치."
echo "  3) Zotero API 키: bash _secrets/set_zotero_key.sh"
echo "  검증: bash verify.sh <01_manuscript 경로>"
