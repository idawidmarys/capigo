@echo off
title CapiGo WeeklyWalk - Podglad iPhone
cd /d "%~dp0"
echo ====================================================
echo   Uruchamianie CapiGo: WeeklyWalk w Chrome...
echo ====================================================
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:8085"
echo Serwer dziala pod adresem http://localhost:8085
echo Aby zamknac podglad, po prostu zamknij to okno konsoli.
python -m http.server 8085 --directory "build\web"
pause
