@echo off
setlocal
set "PYTHONUTF8=1"
set "PYTHONDONTWRITEBYTECODE=1"
cd /d "%~dp0"
if not exist "..\.venv\Scripts\python.exe" (
  echo Optiland environment is missing. Run ..\install\install.bat first.
  if /I not "%~1"=="--no-pause" pause
  exit /b 1
)
set "PYTHONUTF8=1"
set "PYTHONDONTWRITEBYTECODE=1"
"..\.venv\Scripts\python.exe" "single_lens.py"
set "result=%errorlevel%"
if "%result%"=="0" echo Open output\single_lens_rays.png to view the result.
if /I not "%~1"=="--no-pause" pause
exit /b %result%
