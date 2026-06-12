<#
  install.ps1 — Quarto / R(+packages) / Obsidian / Zotero 설치 (Windows, winget)
  사용법(PowerShell):  ./install.ps1
  GUI 앱(Obsidian/Zotero)은 설치만 자동, 플러그인 승인·BBT export 지정은 직접 하세요.
#>

function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Step($name, $id) {
  Write-Host "-- $name --"
  if (Have winget) {
    winget install --id $id -e --accept-source-agreements --accept-package-agreements
  } else {
    Write-Warning "winget이 없습니다. App Installer를 설치하거나 공식 사이트에서 $name 를 받으세요."
  }
}

Write-Host "== Windows 설치 (winget) =="

Step "Quarto"   "Posit.Quarto"
Step "R"        "RProject.R"
Step "Obsidian" "Obsidian.Obsidian"
Step "Zotero"   "Zotero.Zotero"

# R 렌더 패키지
Write-Host "-- R 렌더 패키지 --"
$rscript = Get-Command Rscript -ErrorAction SilentlyContinue
if ($rscript) {
  & Rscript -e "pkgs <- c('officer','png','stringr','xml2','zip'); miss <- pkgs[!pkgs %in% rownames(installed.packages())]; if(length(miss)) install.packages(miss, repos='https://cloud.r-project.org'); cat('installed:', paste(pkgs, collapse=', '), '\n')"
} else {
  Write-Warning "Rscript 미발견 — R 설치 후(새 PowerShell 창) 다시 실행하세요."
}

# 버전 확인
Write-Host "`n== 버전 확인 =="
if (Have quarto) { quarto --version } else { Write-Warning "quarto 미발견(새 창에서 재시도)" }
if (Have R)      { R --version | Select-Object -First 1 } else { Write-Warning "R 미발견" }

Write-Host "`n== 다음 GUI 단계(직접) =="
Write-Host "  1) Zotero Better BibTeX 설치 → 컬렉션을 references.bib로 auto-export(Keep updated)."
Write-Host "  2) Obsidian에서 01_manuscript\ 를 vault로 열기 → Shell commands/Citations/Dataview 설치."
