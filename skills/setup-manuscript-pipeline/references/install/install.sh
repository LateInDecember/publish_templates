#!/usr/bin/env bash
# ============================================================
# install.sh — Quarto · R(+packages) · Obsidian · Zotero 설치 (macOS / Linux)
# 사용법:  bash install.sh
# 설치는 사용자 컴퓨터에서 실행됩니다. GUI 앱(Obsidian/Zotero)은 설치만 자동,
# 플러그인 승인·BBT export 지정 같은 GUI 단계는 안내에 따라 직접 하세요.
# ============================================================
set -uo pipefail

R_PACKAGES='c("officer","png","stringr","xml2","zip")'
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
echo "== OS: $OS =="

# ----------------------------------------------------------------
install_mac() {
  if ! have brew; then
    warn "Homebrew가 없습니다. 먼저 설치하세요: https://brew.sh"
    warn '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 1
  fi
  ok "Homebrew 발견"
  echo "-- Quarto --";   have quarto || brew install --cask quarto;   have quarto && ok "quarto $(quarto --version)"
  echo "-- R --";        have R      || brew install --cask r;        have R && ok "$(R --version | head -1)"
  echo "-- Obsidian --"; brew list --cask obsidian >/dev/null 2>&1 || brew install --cask obsidian; ok "Obsidian"
  echo "-- Zotero --";   brew list --cask zotero   >/dev/null 2>&1 || brew install --cask zotero;   ok "Zotero"
}

install_linux() {
  echo "-- R --"
  if have R; then ok "$(R --version | head -1)"
  elif have apt-get; then sudo apt-get update -qq && sudo apt-get install -y r-base && ok "R 설치"
  else warn "apt 미발견. R을 수동 설치하세요: https://cloud.r-project.org/"; fi

  echo "-- Quarto --"
  if have quarto; then ok "quarto $(quarto --version)"
  else
    ARCH="$(uname -m)"; case "$ARCH" in x86_64) QA=amd64;; aarch64|arm64) QA=arm64;; *) QA=amd64;; esac
    warn "Quarto는 https://quarto.org/docs/get-started/ 에서 linux-$QA .deb를 받아 설치하세요."
    warn "  예: sudo dpkg -i quarto-*-linux-${QA}.deb"
  fi
  echo "-- Obsidian --"; warn "Obsidian은 AppImage/Flatpak로 설치: https://obsidian.md/download (flatpak: md.obsidian.Obsidian)"
  echo "-- Zotero --";   warn "Zotero는 https://www.zotero.org/download/ 또는 flatpak org.zotero.Zotero"
}

case "$OS" in
  Darwin) install_mac ;;
  Linux)  install_linux ;;
  *) warn "지원 외 OS($OS). Windows는 install.ps1을 사용하세요." ;;
esac

# ----------------------------------------------------------------
echo "-- R 렌더 패키지 --"
if have Rscript; then
  Rscript -e "pkgs <- ${R_PACKAGES}; miss <- pkgs[!pkgs %in% rownames(installed.packages())]; if(length(miss)) install.packages(miss, repos='https://cloud.r-project.org'); cat('installed:', paste(pkgs, collapse=', '), '\n')" \
    && ok "R 패키지 확인/설치 완료" || warn "R 패키지 설치 실패 — 수동: Rscript -e 'install.packages(${R_PACKAGES})'"
else
  warn "Rscript 미발견 — R 설치 후 다시 실행하세요."
fi

# ----------------------------------------------------------------
echo ""
echo "== 다음 GUI 단계(직접) =="
echo "  1) Zotero에서 Better BibTeX 플러그인 설치 → 참고문헌 컬렉션을 references.bib로 auto-export(Keep updated)."
echo "  2) Obsidian에서 01_manuscript/ 를 vault로 열기 → 커뮤니티 플러그인(Shell commands, Citations, Dataview) 설치."
echo "  자세히: install_quarto_zotero_obsidian.md, obsidian_workflow.md"
echo ""
echo "== 검증: bash verify.sh <01_manuscript 경로> =="
