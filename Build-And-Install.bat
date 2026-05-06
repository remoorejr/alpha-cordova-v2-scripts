@echo off
:: Force the code page to UTF-8 immediately for emojis
chcp 65001 > nul
cd /d "%~dp0"
@cls
setlocal enabledelayedexpansion
title Alpha Cordova Android: Debug Build Tool (API 36)

:menu
cls
:: ============================================================================
:: ALPHA CORDOVA SUITE - VERSION CHECK
:: ============================================================================
set "CURRENT_VERSION=2.8.5"
set "VERSION_URL=https://raw.githubusercontent.com/remoorejr/alpha-cordova-v2-scripts/main/CHANGELOG.md"

echo 🔄 [INFO] Checking for build suite updates...

powershell -NoProfile -Command "$OutputEncoding = [System.Text.Encoding]::UTF8; $remote = (Invoke-WebRequest -Uri '%VERSION_URL%' -UseBasicParsing -TimeoutSec 3).Content; $latest = [regex]::Match($remote, '(\d+\.\d+\.\d+)').Value; if ($latest -and $latest -ne '%CURRENT_VERSION%') { exit 1 } else { exit 0 }" >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo 📢 [NOTICE] A newer version of the Alpha Cordova Suite is available!
    echo 💡 [TIP] Run your installation script to pull the latest features and fixes.
    echo.
    timeout /t 4 >nul
)
:: ============================================================================

echo ===================================================
echo 📱 CORDOVA Android: Debug Build Tool (API 36)
echo ===================================================
echo.
echo  [1] 🔄 Full Reset: Wipe, Re-init, Build and Install

if exist ".turbo_ready" (
    echo  [2] 🚀 Turbo Sync: UI/JS/CSS Updates + Install (Fast^)
) else (
    echo  [2] 🚀 [90mTurbo Sync: (Disabled - Full Reset Required^)[0m
)

echo  [3] 🔌 Pair Android Device (Wireless)
echo  [4] 🛠️  Container ^& Cache Management...
echo  [5] ❌ Exit
echo.

set "choice="
set /p choice="👉 Select an option (1-5): "

if "%choice%"=="1" goto :full_build
if "%choice%"=="2" goto :check_turbo
if "%choice%"=="3" goto :pair_device
if "%choice%"=="4" goto :mgmt_menu
if "%choice%"=="5" goto :eof
goto :menu

:mgmt_menu
cls
echo ===================================================
echo 🛠️  Container ^& Cache Management
echo ===================================================
echo.
echo  [1] 🛑 Shutdown Engine (Stop Containers)
echo  [2] 🧹 System Prune (Clear Unused Images/Cache)
echo  [3] 🔥 Deep Purge (Wipe Project Volumes ^& Folders)
echo  [4] 🗄️  Prune ALL Volumes (Global Disk Cleanup)
echo  [5] 🔙 Back to Main Menu
echo.

set "mchoice="
set /p mchoice="👉 Select a management task (1-5): "

if "%mchoice%"=="1" goto :shutdown
if "%mchoice%"=="2" goto :prune
if "%mchoice%"=="3" goto :purge
if "%mchoice%"=="4" goto :volprune
if "%mchoice%"=="5" goto :menu
goto :mgmt_menu

:check_turbo
IF NOT EXIST ".turbo_ready" (
    echo.
    echo ⚠️  [ERROR] Turbo Sync is unavailable. 
    pause
    goto :menu
)
goto :turbo_sync

:full_build
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -Install -BatchMode
goto :end

:turbo_sync
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -Quick -Install -BatchMode
goto :end

:pair_device
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\pair-device.ps1"
goto :end

:shutdown
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -BuildMode Shutdown
goto :end

:prune
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -BuildMode Prune
goto :end

:purge
echo.
echo ⚠️  WARNING: This will destroy this project's build caches.
set /p "CONFIRM=👉 Type 'Y' to confirm Deep Purge: "
if /i "%CONFIRM%"=="Y" powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -BuildMode Purge
goto :end

:volprune
echo.
echo ⚠️  DANGER: This will delete ALL unused Docker volumes on your entire system.
set /p "CONFIRM=👉 Type 'Y' to confirm Global Volume Prune: "
if /i "%CONFIRM%"=="Y" powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -BuildMode VolPrune
goto :end

:end
echo.
echo ✅ Task Complete.
pause
goto :menu
