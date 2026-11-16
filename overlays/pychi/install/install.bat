@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set "result=%ERRORLEVEL%"
if /I not "%~1"=="--no-pause" pause
exit /b %result%
