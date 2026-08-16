@echo off
setlocal
cd /d "%~dp0"

fltmc >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator permission...
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

title Codex Remote Control Kit - Lenovo Installer
echo ============================================================
echo  Codex Remote Control Kit for Lenovo - Version 1.0.0
echo ============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-lenovo.ps1"
set "INSTALL_RESULT=%ERRORLEVEL%"
echo.
if not "%INSTALL_RESULT%"=="0" (
  echo INSTALLATION FAILED. Please photograph or copy the error above.
) else (
  echo Installation finished successfully.
)
echo.
pause
exit /b %INSTALL_RESULT%

