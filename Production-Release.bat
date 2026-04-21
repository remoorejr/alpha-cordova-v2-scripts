@echo off
@cls
chcp 65001 > nul
setlocal enabledelayedexpansion
title Alpha Cordova Android: PRODUCTION RELEASE

:menu
cls
set "P_TYPE="
set "P_INST="
echo ===================================================
echo 📱 CORDOVA: Signed Production Release Tool
echo ===================================================
echo.
echo  [1] 📦 Build Signed APK (Testing/Sideload)
echo  [2] 📲 Build + Install Signed APK to Device
echo  [3] 🚀 Build Signed AAB Bundle (Google Play)
echo  [4] ❌ Cancel
echo.

set /p choice="👉 Select option (1-4): "

if "%choice%"=="1" (set "P_TYPE=apk" & set "P_INST=" & goto :run)
if "%choice%"=="2" (set "P_TYPE=apk" & set "P_INST=-Install" & goto :run)
if "%choice%"=="3" (set "P_TYPE=aab" & set "P_INST=" & goto :run)
if "%choice%"=="4" goto :quit

:: Error Handling for Invalid Input
echo.
echo ❌ "%choice%" is not a valid selection. Please choose 1-4.
timeout /t 2 > nul
goto :menu

:run
echo.
echo 🚀 Initializing Production %P_TYPE% Release...
powershell.exe -ExecutionPolicy Bypass -File ".\production-build.ps1" -Release %P_INST% -PackageType %P_TYPE%
goto :end

:quit
echo 🛑 Release aborted.
goto :eof

:end
echo.
echo ✅ Process Complete.
pause
goto :menu