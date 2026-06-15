#!/usr/bin/env bash
# ============================================================
# verify.sh — 설치·연동 검증
# 사용법:  bash verify.sh <01_manuscript 절대경로>
#   인자를 생략하면 현재 폴더를 01_manuscript로 간주.
# ============================================================
set -uo pipefail
MS="${1:-$(pwd)}"
pass=0; fail=0
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; pass=$((pass+1)); }
bad()  { printf "  \033[31m✗\033[0m %s\n" "$1"; fail=$((fail+1)); }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "== 도구 (모두 필수) =="
have quarto && ok "quarto $(quarto --version)" || bad "quarto 미설치 (필수) — install.sh/.ps1 실행"
if have R; then
  ok "$(R --version | head -1)"
  Rscript -e 'p<-c("officer","png","stringr","xml2","zip"); m<-p[!p %in% rownames(installed.packages())]; if(length(m)) {cat("MISSING:",paste(m,collapse=","),"\n"); quit(status=1)} else cat("ok\n")' >/dev/null 2>&1 \
    && ok "R 렌더 패키지(officer,png,stringr,xml2,zip)" \
    || bad "R 패키지 누락 (필수) — Rscript -e 'install.packages(c(\"officer\",\"png\",\"stringr\",\"xml2\",\"zip\"))'"
else
  bad "R 미설치 (필수, render_with_insertions.R가 R 기반) — install.sh/.ps1 실행"
fi

echo "== 폴더·파일 =="
[ -d "$MS/01_source" ] && ok "01_source/ 존재" || bad "01_source/ 없음 (경로 확인: $MS)"
[ -d "$MS/_scripts" ] && ok "_scripts/ 존재" || bad "_scripts/ 없음"
[ -f "$MS/_scripts/render_with_insertions.R" ] && ok "render_with_insertions.R 있음" || bad "render 스크립트 없음"
[ -x "$MS/01_source/render.command" ] && ok "render.command 실행권한 있음" || bad "render.command 없음/실행권한 없음 (chmod +x)"
grep -q "embed-resources: true" "$MS/_quarto.yml" 2>/dev/null && ok "_quarto.yml embed-resources:true" || bad "_quarto.yml embed-resources 확인 필요"
[ -f "$MS/01_source/apa.csl" ] && ok "01_source/apa.csl 있음" || bad "apa.csl 없음 (렌더 필수) — bootstrap 재실행 또는 manuscript_format/apa.csl 복사"
[ -f "$MS/01_source/styles/reference-nanum-myeongjo.docx" ] && ok "reference docx 있음" || bad "reference-nanum-myeongjo.docx 없음 (DOCX 렌더 필수)"

echo "== Zotero 연동 (references.bib) =="
BIB="$MS/01_source/references.bib"
if [ -f "$BIB" ]; then
  n=$(grep -c '^@' "$BIB" 2>/dev/null || echo 0)
  if [ "$n" -eq 0 ]; then
    warn "references.bib가 비어 있음(0항목) — Zotero 연결 전이면 정상. 연결: install/zotero_bbt_setup.md"
  fi
  if [ "$n" -gt 0 ]; then
    ok "references.bib 존재 — 항목 ${n}개"
    # 최근 수정 여부(자동 export 동작 추정)
    if find "$BIB" -mtime -7 >/dev/null 2>&1 && [ -n "$(find "$BIB" -mtime -7 2>/dev/null)" ]; then
      ok "references.bib 최근 7일 내 갱신됨 (BBT auto-export 동작 추정)"
    else
      printf "  \033[33m!\033[0m references.bib가 최근에 갱신되지 않음 — Zotero를 열고 BBT auto-export(Keep updated)를 확인하세요.\n"
    fi
  fi
else
  bad "references.bib 없음 — bootstrap이 빈 파일을 만들거나 Zotero auto-export를 $BIB 로 지정하세요"
fi

echo "== 시크릿 (_secrets) =="
SEC="$MS/../_secrets"
if [ -f "$SEC/zotero.env" ]; then
  ok "_secrets/zotero.env 존재"
  perm=$(stat -c "%a" "$SEC/zotero.env" 2>/dev/null || stat -f "%Lp" "$SEC/zotero.env" 2>/dev/null)
  [ "$perm" = "600" ] && ok "zotero.env 권한 600" || warn "zotero.env 권한이 600이 아님($perm) — chmod 600 권장"
  grep -q '^ZOTERO_API_KEY=.\+' "$SEC/zotero.env" && ok "ZOTERO_API_KEY 채워짐" || warn "ZOTERO_API_KEY 비어 있음 — set_zotero_key.sh 실행"
else
  warn "_secrets/zotero.env 없음(선택) — Zotero API 쓰려면 bash _secrets/set_zotero_key.sh"
fi

echo ""
echo "== 결과: 통과 $pass / 실패 $fail =="
[ "$fail" -eq 0 ] && echo "모든 검증 통과 🎉" || echo "위 실패 항목을 해결한 뒤 다시 실행하세요."
