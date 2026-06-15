#requires -Version 5
<#
  bootstrap.ps1 - Windows one-shot setup: install tools + create project + verify.
  Mirrors bootstrap.sh. ASCII / English only (Windows PowerShell encoding safety).

  Usage (PowerShell):
    powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -Project "C:\path\to\project"
    powershell -ExecutionPolicy Bypass -File bootstrap.ps1                 # asks where to create
    powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -NoInstall      # skip tool install

  R + Quarto are required (renderer is R-based). 02_anal is tool-neutral.
#>
param([string]$Project, [switch]$NoInstall)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$Install = $PSScriptRoot                                   # ...\references\install
$Ref     = Split-Path -Parent $Install                    # ...\references
$Fmt     = Join-Path $Ref 'manuscript_format'
$Scr     = Join-Path $Ref 'scripts'

function Ok($m){ Write-Host ("  [OK] " + $m) -ForegroundColor Green }
function Say($m){ Write-Host ""; Write-Host $m -ForegroundColor Cyan }

# --- ask for project location if not given ---
if (-not $Project) {
  $name = Read-Host 'Project name (default: my_manuscript)'
  if (-not $name) { $name = 'my_manuscript' }
  $base = Read-Host ('Where to create it (default: ' + [Environment]::GetFolderPath('MyDocuments') + ')')
  if (-not $base) { $base = [Environment]::GetFolderPath('MyDocuments') }
  $Project = Join-Path $base $name
}
$MS = Join-Path $Project '01_manuscript'

# --- 0) install tools ---
if (-not $NoInstall) {
  Say '[0] Installing tools (install.ps1): Quarto, R, Obsidian, Zotero'
  try { & powershell -ExecutionPolicy Bypass -NoProfile -File (Join-Path $Install 'install.ps1') }
  catch { Write-Warning 'Some installs failed - check messages. You can re-run install.ps1.' }
} else {
  Say '[0] Skipping install (-NoInstall). Quarto + R are required to render.'
}

# --- 1) folder structure (tool-neutral) ---
Say ('[1] Creating folders: ' + $Project)
$dirs = @(
  '01_manuscript\01_source\styles','01_manuscript\01_source\notes',
  '01_manuscript\02_literature\pdfs','01_manuscript\02_literature\notes',
  '01_manuscript\03_assets\figures',
  '01_manuscript\04_synced\tables\main','01_manuscript\04_synced\tables\supplementary','01_manuscript\04_synced\figures',
  '01_manuscript\05_output','01_manuscript\_scripts\lit','01_manuscript\_logs\literature','01_manuscript\_archive',
  '_secrets',
  '02_anal\00_code','02_anal\01_data\00_raw','02_anal\01_data\01_interim','02_anal\01_data\02_final',
  '02_anal\02_meta_data',
  '02_anal\03_results\06_reporting\docs\main','02_anal\03_results\06_reporting\docs\supplementary',
  '02_anal\03_results\06_reporting\figures\main','02_anal\03_results\06_reporting\figures\supplementary',
  '02_anal\03_results\06_reporting\tables\main','02_anal\03_results\06_reporting\tables\supplementary',
  '02_anal\04_docs'
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $Project $d) | Out-Null }
Ok '01_manuscript / 02_anal (tool-neutral; data: 00_raw,01_interim,02_final)'

# --- 2) manuscript format ---
Say '[2] Placing manuscript format'
$dst = Join-Path $MS 'manuscript.md'
if (-not (Test-Path $dst)) { Copy-Item (Join-Path $Fmt 'manuscript_skeleton.md') $dst -Force }
Copy-Item (Join-Path $Fmt '_quarto.yml') (Join-Path $MS '_quarto.yml') -Force
Copy-Item (Join-Path $Fmt 'styles\*')    (Join-Path $MS '01_source\styles') -Recurse -Force
Copy-Item (Join-Path $Fmt 'apa.csl')     (Join-Path $MS '01_source\apa.csl') -Force
$bib = Join-Path $MS '01_source\references.bib'
if (-not (Test-Path $bib)) {
  Set-Content -Path $bib -Encoding ASCII -Value @('% references.bib - Zotero Better BibTeX auto-export target (currently empty).','% See install/zotero_bbt_setup.md to connect Zotero.')
}
Copy-Item (Join-Path $Fmt 'journal_format_kjcbp_2020.md') (Join-Path $MS '01_source\notes') -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Fmt 'journal_requirements.md')      (Join-Path $MS '01_source\notes') -Force -ErrorAction SilentlyContinue
if (Test-Path (Join-Path $Fmt 'gitignore.template')) { Copy-Item (Join-Path $Fmt 'gitignore.template') (Join-Path $MS '.gitignore') -Force }
Ok 'manuscript.md, _quarto.yml, apa.csl, references.bib(empty), styles, notes'

# --- 3) scripts ---
Say '[3] Placing render/sync scripts'
Copy-Item (Join-Path $Scr '*.R') (Join-Path $MS '_scripts') -Force
Copy-Item (Join-Path $Scr 'render.command') (Join-Path $MS '01_source\render.command') -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Scr 'render.bat')     (Join-Path $MS '01_source\render.bat') -Force -ErrorAction SilentlyContinue
Ok '_scripts\*.R, 01_source\render.bat (Windows), render.command (mac)'

# --- 4) Obsidian starter ---
Say '[4] Obsidian starter config'
$obs = Join-Path $MS '.obsidian'
if (Test-Path $obs) {
  New-Item -ItemType Directory -Force -Path (Join-Path $obs 'plugins\obsidian-shellcommands') | Out-Null
  Copy-Item (Join-Path $Install 'obsidian_starter\.obsidian\plugins\obsidian-shellcommands\data.json') (Join-Path $obs 'plugins\obsidian-shellcommands\data.json') -Force -ErrorAction SilentlyContinue
} else {
  Copy-Item (Join-Path $Install 'obsidian_starter\.obsidian') $obs -Recurse -Force
  Ok '.obsidian starter copied (install community plugins in Obsidian: Shell commands, Citations, Dataview)'
}

# --- 5) secrets store (Zotero API key) ---
Say '[5] Secrets store (_secrets, Zotero API key)'
$sec = Join-Path $Project '_secrets'
Copy-Item (Join-Path $Install 'secrets\zotero.env.example') $sec -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Install 'secrets\set_zotero_key.sh')  $sec -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Install 'secrets\set_zotero_key.ps1') $sec -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $Install 'secrets\README.md')         $sec -Force -ErrorAction SilentlyContinue
$gi = Join-Path $Project '.gitignore'
if (-not (Select-String -Path $gi -Pattern '_secrets/zotero.env' -SimpleMatch -Quiet -ErrorAction SilentlyContinue)) {
  Add-Content -Path $gi -Value @('.DS_Store','_secrets/zotero.env','_secrets/*.env','!_secrets/*.example')
}
Ok '_secrets (zotero.env.example, set_zotero_key.sh/.ps1, README) + .gitignore'

# --- 6) AGENTS.md ---
Say '[6] AGENTS.md'
$ag = Join-Path $Project 'AGENTS.md'
if (-not (Test-Path $ag)) { Copy-Item (Join-Path $Ref 'AGENTS_TEMPLATE.md') $ag -Force; Ok 'AGENTS.md created - fill in <...> placeholders' }
else { Write-Host '  AGENTS.md already exists - kept' }

# --- 7) verify (basic) ---
Say '[7] Verify'
function Have($c){ [bool](Get-Command $c -ErrorAction SilentlyContinue) }
if (Have quarto) { Ok ('quarto ' + (quarto --version)) } else { Write-Warning 'quarto not found (open a NEW window after install)' }
if (Have R)      { Ok 'R found' } else { Write-Warning 'R not found (open a NEW window after install)' }
foreach ($f in @('01_source\apa.csl','01_source\references.bib','_quarto.yml','manuscript.md','_scripts\render_with_insertions.R','01_source\render.bat')) {
  if (Test-Path (Join-Path $MS $f)) { Ok $f } else { Write-Warning ('MISSING ' + $f) }
}

# --- 8) next steps ---
Say 'Next (do these by hand)'
Write-Host '  1) Zotero: install Better BibTeX, auto-export your collection to'
Write-Host ('     ' + (Join-Path $MS '01_source\references.bib') + '  (Keep updated). See install\zotero_bbt_setup.md')
Write-Host ('  2) Zotero API key:  powershell -File "' + (Join-Path $sec 'set_zotero_key.ps1') + '" -ApiKey KEY -UserId ID')
Write-Host ('  3) Obsidian: open "' + $MS + '" as a vault; install Shell commands / Citations / Dataview')
Write-Host '  4) Fill AGENTS.md placeholders; set sync_reporting_assets.R reporting_root if using R analysis'
Write-Host ('  5) Render: double-click 01_source\render.bat  (or: cd "' + $MS + '"; Rscript _scripts\render_with_insertions.R)')
Write-Host ''
Write-Host 'Bootstrap complete.' -ForegroundColor Green
