#requires -Version 5
<#
  install.ps1 - Install Quarto / Obsidian / Zotero (R is OPTIONAL) on Windows via winget.

  This file is intentionally ASCII / English only. Windows PowerShell 5.1 reads scripts
  using the system ANSI code page by default, so non-ASCII (e.g. Korean) string/comment
  bytes can break parsing. Keeping this script ASCII avoids that entirely.

  Usage (PowerShell):
    powershell -ExecutionPolicy Bypass -File install.ps1            # no R
    powershell -ExecutionPolicy Bypass -File install.ps1 -WithR     # also install R + render packages

  Notes:
    - GUI apps (Obsidian/Zotero) are installed only. Plugin approval and Better BibTeX
      auto-export must be configured inside the app afterward.
    - R is OPTIONAL. render_with_insertions.R (marker/table insertion) requires R.
      Without R, render with plain: quarto render manuscript.md
#>
param([switch]$WithR)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Step($name, $id) {
  Write-Host "-- $name --"
  if (Have winget) {
    winget install --id $id -e --accept-source-agreements --accept-package-agreements
  } else {
    Write-Warning "winget not found. Install 'App Installer' from the Microsoft Store, or download $name from its official site."
  }
}

Write-Host "== Windows install (winget) =="
Step "Quarto"   "Posit.Quarto"      # if not found, try: RStudio.Quarto
Step "Obsidian" "Obsidian.Obsidian"
Step "Zotero"   "Zotero.Zotero"

if ($WithR) {
  Step "R" "RProject.R"
  Write-Host "-- R render packages --"
  if (Have Rscript) {
    & Rscript -e "pkgs <- c('officer','png','stringr','xml2','zip'); miss <- pkgs[!pkgs %in% rownames(installed.packages())]; if (length(miss)) install.packages(miss, repos='https://cloud.r-project.org'); cat('R render packages ready\n')"
  } else {
    Write-Warning "Rscript not found yet. Open a NEW PowerShell window (so PATH refreshes) and run: install.ps1 -WithR"
  }
} else {
  Write-Host "-- R skipped. Use -WithR to install it. (render_with_insertions.R needs R; without R use 'quarto render'.) --"
}

Write-Host ""
Write-Host "== Versions =="
if (Have quarto) { quarto --version } else { Write-Warning "quarto not found (open a new window and retry)" }
if ($WithR -and (Have R)) { (R --version)[0] }

Write-Host ""
Write-Host "== Next (manual GUI steps) =="
Write-Host "  1) Zotero: install Better BibTeX, set auto-export of your collection to"
Write-Host "     01_manuscript\01_source\references.bib  (enable 'Keep updated')."
Write-Host "  2) Obsidian: open 01_manuscript\ as a vault, install community plugins"
Write-Host "     (Shell commands, Citations, Dataview)."
Write-Host "  See: install_quarto_zotero_obsidian.md , obsidian_workflow.md"
