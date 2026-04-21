@echo off
@cls
chcp 65001 > nul
setlocal enabledelayedexpansion
title Alpha Cordova Android Build Engine

:menu
cls
set "CAN_TURBO=0"
if exist "platforms\android" set "CAN_TURBO=1"

echo ===================================================
echo 📱 CORDOVA Android: Debug Build Tool (API 36)
echo ===================================================
echo.
echo  [1] 🔄 Full Reset: Wipe, Re-init, Build and Install

if "%CAN_TURBO%"=="1" goto :draw_turbo
echo  [2] 🚫 Turbo Sync: (Locked - Run Option 1 first)
goto :draw_cancel

:draw_turbo
echo  [2] 🚀 Turbo Sync: UI/JS/CSS Updates + Install (Fast)

:draw_cancel
echo  [3] ❌ Cancel
echo.

set /p choice="👉 Select an option (1-3): "

set PS_CMD=powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -BatchMode

if "%choice%"=="1" goto :full
if "%choice%"=="2" goto :check_turbo
if "%choice%"=="3" goto :quit
goto :menu

:check_turbo
if "%CAN_TURBO%"=="0" (
    echo.
    echo ⚠️  [WARN] Turbo Sync requires an existing build.
    pause
    goto :menu
)
goto :turbo

:full
%PS_CMD% -Install
goto :end

:turbo
%PS_CMD% -Install -Quick
goto :end

:end
echo.
echo ✅ Process Complete.
pause
goto :menu

:quit
echo.
echo 🛑 Script terminated. Returning to prompt...
echo.
:: goto :eof returns to the command prompt without closing the window
goto :eof