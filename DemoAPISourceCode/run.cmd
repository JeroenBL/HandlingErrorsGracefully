@echo off
set "APP_DIR=%~dp0"
set "CONFIG_FILE=%APP_DIR%config.json"

rem Read JSON values using PowerShell
for /f %%A in ('powershell -NoProfile -Command "Get-Content %CONFIG_FILE% | ConvertFrom-Json | ForEach-Object { Write-Host $_.url; Write-Host $_.port }"') do (
    if not defined URL set "URL=%%A"
    if defined URL set "PORT=%%A"
)

rem Check if URL contains '*', and replace it with 'localhost'
rem if "%URL%"=="http://*" set "URL=http://localhost"

rem Start the application from the current directory
cd /d "%APP_DIR%"
start "" "%APP_DIR%ErrorhandlingDemoAPI.exe" --urls "%URL%:%PORT%" 

rem Wait for the server to start
timeout /t 5 >nul

rem Open Microsoft Edge to the index.html page
rem start msedge "%URL%:%PORT%/index.html"


