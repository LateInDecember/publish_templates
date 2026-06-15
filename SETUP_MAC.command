#!/bin/bash
# ============================================================
#  논문 파이프라인 설치 런처 (macOS) — 더블클릭하세요.
#  Homebrew가 없으면 설치하고, 도구(Quarto·R·Obsidian·Zotero)를 깐 뒤
#  프로젝트 폴더·양식까지 만들어 줍니다.
#
#  처음 더블클릭 시 "확인되지 않은 개발자" 경고가 뜨면:
#    이 파일 우클릭 → 열기 → (경고창에서) 열기  한 번만 하면 됩니다.
# ============================================================
clear
echo "==================================================="
echo "  논문 파이프라인 설치 (macOS)"
echo "==================================================="
echo ""

DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL="$DIR/skills/setup-manuscript-pipeline/references/install"

if [ ! -f "$INSTALL/bootstrap.sh" ]; then
  echo "오류: bootstrap.sh를 찾을 수 없습니다. 이 파일이 publish_templates 폴더 맨 위에 있는지 확인하세요."
  read -n 1 -s -r -p "엔터를 누르면 닫힙니다..."; exit 1
fi

# 1) Homebrew (없으면 설치)
if ! command -v brew >/dev/null 2>&1; then
  echo "[1/2] Homebrew(패키지 관리자)가 없어 설치합니다."
  echo "      설치 중 Mac 로그인 비밀번호를 물어볼 수 있습니다 (화면엔 안 보이지만 입력됩니다)."
  echo ""
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
    echo "  (Homebrew 설치에 문제가 있었습니다. https://brew.sh 를 참고하세요.)"
fi
# brew를 이 세션 PATH에 추가 (Apple Silicon / Intel)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"

# 2) 설치 + 프로젝트 생성 (bootstrap이 프로젝트 이름/위치를 물어봅니다)
echo ""
echo "[2/2] 도구 설치 + 프로젝트 생성을 시작합니다..."
echo ""
bash "$INSTALL/bootstrap.sh"

echo ""
echo "==================================================="
echo "  끝났습니다. 위에 안내된 'Next' 단계(Zotero/Obsidian)를 진행하세요."
echo "==================================================="
read -n 1 -s -r -p "엔터를 누르면 창이 닫힙니다..."
