@echo off
REM ============================================================
REM   Manuscript pipeline setup launcher (Windows) - double-click this file.
REM   Installs tools (Quarto, R, Obsidian, Zotero) via winget, then creates
REM   the project folder + format. Asks for a project name/location.
REM
REM   (ASCII/English on purpose: cmd.exe code page is not UTF-8.)
REM ============================================================
title Manuscript pipeline setup (Windows)
echo ===================================================
echo   Manuscript pipeline setup (Windows)
echo ===================================================
echo.

set "DIR=%~dp0"
set "BOOT=%DIR%skills\setup-manuscript-pipeline\references\install\bootstrap.ps1"

if not exist "%BOOT%" (
  echo ERROR: bootstrap.ps1 not found. Make sure this file is at the top of the publish_templates folder.
  pause
  exit /b 1
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%BOOT%"

echo.
echo ===================================================
echo   Done. Follow the "Next" steps shown above (Zotero / Obsidian).
echo ===================================================
pause
