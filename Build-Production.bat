@echo off
setlocal
title Alpha Cordova Android: Production Build

echo ===================================================
echo 💎 CORDOVA: Generating Production Release (.aab)
echo ===================================================
echo.
echo [!] This process will:
echo     1. Increment version in config.xml
echo     2. Generate a fresh CHANGELOG.md
echo     3. Build a signed/unsigned Release Bundle
echo     4. Create a Git Commit and Tag
echo.
set /p confirm="Are you ready to proceed? (Y/N): "
if /i "%confirm%" neq "Y" goto :cancel

echo 🚀 Starting Build Engine...
powershell -ExecutionPolicy Bypass -File .\release-build.ps1
goto :end

:cancel
echo.
echo ❌ Build cancelled by user.
echo.

:end
echo ===================================================
pause
