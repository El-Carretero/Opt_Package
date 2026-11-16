@echo off
setlocal
set "PYTHONUTF8=1"
set "PYTHONDONTWRITEBYTECODE=1"
cd /d "%~dp0"
set "PYTHON_EXE=%~dp0..\.venv\Scripts\python.exe"
if not exist "%PYTHON_EXE%" (
  echo Project virtual environment is missing. Run ..\install\install.bat first.
  if /I not "%~1"=="--no-pause" pause
  exit /b 1
)
"%PYTHON_EXE%" "01_gaussian_propagation.py"
if errorlevel 1 goto failed
"%PYTHON_EXE%" "02_double_slit.py"
if errorlevel 1 goto failed
echo.
echo Both examples passed. Open the output folder for PNG, CSV, JSON and logs.
if /I not "%~1"=="--no-pause" pause
exit /b 0
:failed
echo.
echo A check failed. Read the output validation.log and parameter values.
if /I not "%~1"=="--no-pause" pause
exit /b 1
