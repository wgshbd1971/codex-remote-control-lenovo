@echo off
setlocal
cd /d "%~dp0"
title Codex Remote Control Kit - Diagnostics
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0diagnose-lenovo.ps1"
echo.
pause

