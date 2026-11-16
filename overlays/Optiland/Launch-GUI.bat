@echo off
set "MPLCONFIGDIR=%~dp0.runtime\matplotlib"
cd /d "%~dp0"
set "MPLBACKEND="
"%~dp0.venv\Scripts\optiland.exe"
