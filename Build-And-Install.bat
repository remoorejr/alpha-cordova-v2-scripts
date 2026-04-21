@echo off
@cls
chcp 65001 > nul
setlocal enabledelayedexpansion
title Alpha Cordova Android: Debug Build Tool (API 36)

:menu
cls
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