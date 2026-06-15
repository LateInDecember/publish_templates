#requires -Version 5
# ============================================================
# set_zotero_key.ps1 - Store the Zotero API key in zotero.env (same folder, gitignored).
#   ASCII / English only (Windows PowerShell encoding safety).
#
# BEST: pass the key as arguments (paste it right into the command). This always works,
#   even in terminals where interactive input does not.
#     powershell -ExecutionPolicy Bypass -File set_zotero_key.ps1 -ApiKey <KEY> -UserId <ID>
#
# Without arguments it asks interactively (input is VISIBLE on purpose: a hidden/secure
# prompt fails to accept input in some terminals).
# ============================================================
param([string]$ApiKey, [string]$UserId)

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $dir 'zotero.env'

if (-not $ApiKey) { $ApiKey = Read-Host 'Paste Zotero API key and press Enter' }
if (-not $UserId) { $UserId = Read-Host 'Enter Zotero userID (number) and press Enter' }

if (-not $ApiKey -or -not $UserId) {
  Write-Error 'Both API key and userID are required. Example: set_zotero_key.ps1 -ApiKey KEY -UserId 1234567'
  exit 1
}

$content = "ZOTERO_API_KEY=$ApiKey`r`nZOTERO_USER_ID=$UserId`r`nZOTERO_LIBRARY_TYPE=user`r`n"
Set-Content -Path $envFile -Value $content -Encoding ASCII -NoNewline
Write-Host "Saved: $envFile (gitignored). Key length $($ApiKey.Length), userID $UserId."
