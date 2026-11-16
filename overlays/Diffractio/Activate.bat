@echo off
set "MPLCONFIGDIR=%~dp0.runtime\matplotlib"
cd /d "%~dp0work"
call "%~dp0.venv\Scripts\activate.bat"
cmd /k
