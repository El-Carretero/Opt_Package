@echo off
cd /d "%~dp0"
echo CPU KLM build. CUDA Maxwell-Bloch diode modes are UNSUPPORTED: do not use GPU diode modes.
echo Open http://127.0.0.1:8000 after startup. Ctrl+C stops the server.
".venv\Scripts\python.exe" -m uvicorn app:app --host 127.0.0.1 --port 8000
pause
