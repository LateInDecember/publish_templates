@echo off
REM ============================================================
REM  Render the manuscript (DOCX + HTML) on Windows.
REM  Double-click, or run in a terminal. Requires R + Quarto on PATH.
REM  Runs from 01_source\ , so it cd's up to 01_manuscript\ .
REM ============================================================
cd /d "%~dp0.."
echo Rendering manuscript...
Rscript _scripts\render_with_insertions.R
echo.
if %ERRORLEVEL%==0 (
  echo Done. Output: 05_output\manuscript.docx and 05_output\manuscript.html
) else (
  echo Render FAILED ^(see messages above^).
)
echo.
pause
