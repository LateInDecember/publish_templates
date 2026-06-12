#requires -Version 5
# ============================================================
# set_zotero_key.ps1 - Store the Zotero API key securely in zotero.env (same folder).
#   - zotero.env is gitignored; the key is not printed to the console.
#   ASCII / English only (Windows PowerShell encoding safety).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File set_zotero_key.ps1
#   powershell -ExecutionPolicy Bypass -File set_zotero_key.ps1 -ApiKey <KEY> -UserId <ID>
# ============================================================
param([string]$ApiKey, [string]$UserId)

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $dir 'zotero.env'

if (-not $ApiKey) {
  $sec = Read-Host -AsSecureString 'Paste Zotero API key (hidden)'
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
  $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}
if (-not $UserId) { $UserId = Read-Host 'Zotero userID (number, shown at zotero.org/settings/keys)' }

if (-not $ApiKey -or -not $UserId) { Write-Error 'Both API key and userID are required.'; exit 1 }

$content = "ZOTERO_API_KEY=$ApiKey`r`nZOTERO_USER_ID=$UserId`r`nZOTERO_LIBRARY_TYPE=user`r`n"
Set-Content -Path $envFile -Value $content -Encoding ASCII -NoNewline
Write-Host "Saved: $envFile (do not commit; gitignored). Key length $($ApiKey.Length), userID $UserId."
