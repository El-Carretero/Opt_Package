@echo off
setlocal
set "ELMER_HOME=%~dp0runtime\elmerfem-nompi-devel-26.2-11c118114-20260917_Windows-AMD64"
set "PATH=%ELMER_HOME%\bin;%PATH%"
cd /d "%ELMER_HOME%\bin"
start "ElmerGUI" ElmerGUI.exe
