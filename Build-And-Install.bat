@echo off
setlocal enabledelayedexpansion
:: Set code page to UTF-8 for emoji support
chcp 65001 > nul
title Alpha Cordova Android: DEBUG BUILD AND INSTALL

:: Check specifically for the android platform folder
set "CAN_TURBO=0"
if exist "platforms\android" set "CAN_TURBO=1"

echo ===================================================
echo 📱 CORDOVA: Debug Build Tool (API 36)
echo ===================================================
echo.
echo  [1] 🔄 Full Reset: Wipe, Re-init, Build and Install

:: Logical jump to prevent double-printing
if "%CAN_TURBO%"=="1" goto :menu_turbo
echo  [2] 🚫 Turbo Sync: (Locked - Run Option 1 first)
goto :menu_cancel

:menu_turbo
echo  [2] 🚀 Turbo Sync: UI/JS/CSS Updates + Install (Fast)

:menu_cancel
echo  [3] ❌ Cancel
echo.

:input
set /p choice="👉 Select an option (1-3): "

:: Define the base command
set PS_CMD=powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1"

if "%choice%"=="1" goto :full
if "%choice%"=="2" goto :check_turbo
if "%choice%"=="3" goto :cancel
:: Loop back on invalid input
goto :input

:check_turbo
if "%CAN_TURBO%"=="0" (
    echo.
    echo ⚠️  [WARN] Turbo Sync requires an existing build. Please run Option 1.
    echo.
    goto :input
)
goto :turbo

:full
echo.
echo 🛠️  Initializing Full Environment Reset, Build, and Install...
:: Force a clean slate before the engine starts
if exist "platforms" rd /s /q "platforms"
%PS_CMD% -Install
goto :end

:turbo
echo.
echo ⚡ Initializing Turbo Sync and Install...
%PS_CMD% -Install -Quick
goto :end

:cancel
echo.
echo 🛑 Build aborted.
echo.
goto :end

:end
echo ===================================================
echo ✅ Process Complete.
echo ===================================================
pause