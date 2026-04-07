@echo off
@cls
@echo off
chcp 65001 > nul
echo ========================================================
echo   Launching Environment Sanity Check...
echo ========================================================
powershell -ExecutionPolicy Bypass -File .\Verify-Environment.ps1
echo.
pause