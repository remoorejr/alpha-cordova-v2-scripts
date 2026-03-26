@echo off
setlocal
title Alpha Cordova Android: Standalone Debug APK

echo ===================================================
echo 📦 CORDOVA: Generating Debug APK (No Install)
echo ===================================================
echo [!] Note: This build will NOT bump the version.
echo.

powershell -ExecutionPolicy Bypass -File .\release-build.ps1 -Debug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build Successful!
    echo 📂 Location: platforms\android\app\build\outputs\apk\debug\
) else (
    echo.
    echo ❌ Build Failed. Check the logs above for errors.
)

echo ===================================================
pause