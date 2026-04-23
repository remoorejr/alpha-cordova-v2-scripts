@echo off
@cls
chcp 65001 > nul
setlocal enabledelayedexpansion
title Alpha Cordova Android: Debug Build Tool (API 36)

:menu
cls
:: ============================================================================
:: ALPHA CORDOVA SUITE - VERSION CHECK
:: ============================================================================
set "CURRENT_VERSION=2.8.0"
set "VERSION_URL=https://raw.githubusercontent.com/remoorejr/alpha-cordova-v2-scripts/main/CHANGELOG.md"

echo 🔄 [INFO] Checking for build suite updates...

:: Added -TimeoutSec 3 to ensure this fails fast if the user is offline, preventing hanging
powershell -Command "$remote = (Invoke-WebRequest -Uri '%VERSION_URL%' -UseBasicParsing -TimeoutSec 3).Content; $latest = [regex]::Match($remote, '(\d+\.\d+\.\d+)').Value; if ($latest -and $latest -ne '%CURRENT_VERSION%') { exit 1 } else { exit 0 }" >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo 📢 [NOTICE] A newer version of the Alpha Cordova Suite is available!
    echo 💡 [TIP] Run your installation script to pull the latest features and fixes.
    echo.
    :: Pause briefly so they actually see the message, but don't force a hard stop
    timeout /t 4 >nul
)
:: ============================================================================

echo ===================================================
echo 📱 CORDOVA Android: Debug Build Tool (API 36)
echo ===================================================
echo.
echo  [1] 🔄 Full Reset: Wipe, Re-init, Build and Install
echo  [2] 🚀 Turbo Sync: UI/JS/CSS Updates + Install (Fast)
echo  [3] ❌ Cancel
echo.

set "choice="
set /p choice="👉 Select an option (1-3): "

if "%choice%"=="1" goto :full_build
if "%choice%"=="2" goto :turbo_sync
if "%choice%"=="3" goto :eof

:: Error Handling for Invalid Input
echo.
echo ❌ "%choice%" is not a valid selection. Please choose 1, 2, or 3.
timeout /t 2 > nul
goto :menu

:full_build
echo.
echo 🛠️  Running Full Reset Build...
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -Install -BatchMode
goto :end

:turbo_sync
echo.
echo ⚡ Running Turbo Sync...
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -Quick -Install -BatchMode
goto :end

:end
echo.
echo ✅ Process Complete.
pause
goto :menu