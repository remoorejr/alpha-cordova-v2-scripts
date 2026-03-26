@echo off
setlocal
title Alpha Cordova Android: Turbo Sync

echo ===================================================
echo ⚡ CORDOVA: Turbo Syncing UI/JS/CSS
echo ===================================================
echo [!] Bypassing Gradle for rapid deployment...
echo.

powershell -ExecutionPolicy Bypass -File .\release-build.ps1 -Quick -Install

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Sync Complete! App should be refreshing...
) else (
    echo.
    echo ❌ Sync Failed. Check if device is connected.
)

echo ===================================================
pause