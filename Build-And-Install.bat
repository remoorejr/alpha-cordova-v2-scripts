@echo off
setlocal
title Alpha Cordova Android: DEBUG BUILD AND INSTALL

echo ===================================================
echo CORDOVA: Debug Build Tool (API 36)
echo ===================================================
echo.
echo [1] Full Reset: Wipe platform, Re-init, Build and Install
echo [2] Turbo Sync: UI/JS/CSS updates only (Fast Sync)
echo [3] Cancel
echo.

set /p choice="Select an option (1-3): "

:: Define the base command to avoid parsing issues inside IF blocks
set PS_CMD=powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1"

if "%choice%"=="1" goto :full
if "%choice%"=="2" goto :turbo
if "%choice%"=="3" goto :cancel
goto :cancel

:full
echo.
echo Initializing Full Environment Reset and Build...
%PS_CMD% -Install
goto :end

:turbo
echo.
echo Initializing Turbo Sync...
%PS_CMD% -Install -Quick
goto :end

:cancel
echo.
echo Build aborted.
echo.
goto :end

:end
echo ===================================================
echo Process Complete.
pause