@echo off
title My Wallet PWA Local Server
echo =============================================================
echo             My Wallet PWA Local Web Server
echo =============================================================
echo.
cd /d "%~dp0"
echo Building Web PWA...
call flutter build web --release
echo.
echo Starting Web Server on http://localhost:8080 ...
cd build\web
python -m http.server 8080
pause
