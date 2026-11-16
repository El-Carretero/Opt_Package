@echo off
cd /d "%~dp0"
set "PATH=%~dp0.runtime\octave-11.3.0-w64\mingw64\bin;%PATH%"
".runtime\octave-11.3.0-w64\mingw64\bin\octave-gui.exe" --gui --persist
