@echo off
setlocal
title Alpha Cordova Android: Full Build & Install

echo ===================================================
echo 🛠️  CORDOVA: Full Platform Reset ^& Install
echo ===================================================
echo [!] This will:
echo     1. Wipe existing Android platform
echo     2. Re-initialize Android 15 (API 36)
echo     3. Increment version in config.xml
echo     4. Build and Deploy Debug APK to device
echo.
set /p confirm="Perform full environment reset? (Y/N): "
if /i "%confirm%" neq "Y" goto :cancel

echo 🚀 Initializing Heavy Build...
powershell.exe -ExecutionPolicy Bypass -File .\release-build.ps1 -Install
goto :end

:cancel
echo.
echo ❌ Build aborted.
echo.

:end
echo ===================================================
pause