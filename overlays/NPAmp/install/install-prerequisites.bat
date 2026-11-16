@echo off
setlocal
echo This option permits the official Microsoft VC++2008 x86 system runtime installer if NPAmp cannot run.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -InstallPrerequisites
set "result=%errorlevel%"
pause
exit /b %result%
