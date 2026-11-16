@echo off
set "MPLCONFIGDIR=%~dp0.runtime\matplotlib"
set "MPLBACKEND=Agg"
"%~dp0.venv\Scripts\python.exe" -I "%~dp0install\smoke_test.py"
set "result=%errorlevel%"
if /I not "%~1"=="--no-pause" pause
exit /b %result%
