#requires -Version 5
<#
  install.ps1 - Install Quarto / R(+packages) / Obsidian / Zotero on Windows via winget.

  ASCII / English only on purpose: Windows PowerShell 5.1 reads scripts using the system
  ANSI code page by default, so non-ASCII (e.g. Korean) bytes can break parsing.

  This script actually INSTALLS (it does not merely print instructions). In a sandboxed /
  remote shell it cannot install onto the user's machine - run it in the user's own
  PowerShell, or via a local-shell agent (Codex CLI / Claude Code).

  R is REQUIRED (the manuscript renderer render_with_insertions.R is R-based).

  Usage (PowerShell):
    powershell -ExecutionPolicy Bypass -File install.ps1
#>

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Step($name, $id) {
  Write-Host "-- $name --"
  if (Have winget) {
    winget install --id $id -e --accept-source-agreements --accept-package-agreements
  } else {
    Write-Warning "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
  }
}

Write-Host "== Installing (winget) =="
Step "Quarto"   "Posit.Quarto"      # fallback id: RStudio.Quarto
Step "R"        "RProject.R"
Step "Obsidian" "Obsidian.Obsidian"
Step "Zotero"   "Zotero.Zotero"

# R render packages (required)
Write-Host "-- R render packages --"
if (Have Rscript) {
  & Rscript -e "pkgs <- c('officer','png','stringr','xml2','zip'); miss <- pkgs[!pkgs %in% rownames(installed.packages())]; if (length(miss)) install.packages(miss, repos='https://cloud.r-project.org'); cat('R render packages ready\n')"
} else {
  Write-Warning "Rscript not found yet (R PATH not refreshed). Open a NEW PowerShell window and run install.ps1 again to finish R packages."
}

Write-Host ""
Write-Host "== Versions =="
if (Have quarto) { quarto --version } else { Write-Warning "quarto not found (open a new window and retry)" }
if (Have R)      { (R --version)[0] } else { Write-Warning "R not found (open a new window and retry)" }

Write-Host ""
Write-Host "== Next (manual GUI steps) =="
Write-Host "  1) Zotero: install Better BibTeX, auto-export your collection to"
Write-Host "     01_manuscript\01_source\references.bib (enable 'Keep updated')."
Write-Host "  2) Obsidian: open 01_manuscript\ as a vault, install community plugins"
Write-Host "     (Shell commands, Citations, Dataview)."
Write-Host "  3) Zotero API key: powershell -File _secrets\set_zotero_key.ps1"
