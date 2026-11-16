@echo off
set "MPLCONFIGDIR=%~dp0.runtime\matplotlib"
cd /d "%~dp0"
call "%~dp0.venv\Scripts\activate.bat"
cmd /k
