@echo off
setlocal
if not exist "%~dp0..\runtime\rezonator.exe" (
  echo Install reZonator first: ..\install\install.bat
  pause
  exit /b 1
)
pushd "%~dp0..\runtime"
start "" "rezonator.exe" --example "%~dp001_symmetric_cavity.rez"
popd
