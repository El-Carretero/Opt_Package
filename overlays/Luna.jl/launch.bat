@echo off
setlocal
cd /d "%~dp0"
set "JULIA_DEPOT_PATH=%~dp0.julia"
set "CONDA_JL_HOME=%~dp0.conda"
set "PYTHON=%~dp0.venv\Scripts\python.exe"
set "MPLCONFIGDIR=%~dp0.cache\matplotlib"
set "JULIA_NUM_THREADS=2"
"%~dp0runtime\julia-1.10.13\bin\julia.exe" --startup-file=no --project="%~dp0." %*
