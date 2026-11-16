@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0validate_native.ps1"
set "result=%errorlevel%"
if not "%result%"=="0" echo Native reZonator example validation failed.
pause
exit /b %result%
