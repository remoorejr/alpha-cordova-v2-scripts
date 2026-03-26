@echo off
setlocal
title Alpha Cordova Android: PRODUCTION RELEASE ENGINE

echo ===================================================
echo 💎  CORDOVA: Production Release (API 36)
echo ===================================================
echo [!] This will:
echo     1. Perform a Full Platform Reset
echo     2. Bump Version ^& Update Changelog (via Git)
echo     3. Generate a Signed Release Bundle (.aab)
echo     4. Verify Device and Install (Optional)
echo.

set /p confirm="Proceed with Production Release? (Y/N): "
if /i "%confirm%" neq "Y" goto :cancel

echo.
echo [?] Would you like to install to the device after the build?
set /p install="Install to device? (Y/N): "

:: Define the base command to avoid parsing issues
set PS_CMD=powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -Release

if /i "%install%"=="Y" goto :run_install
goto :run_only

:run_install
echo.
echo 🚀 Initializing Signed Release + Install...
%PS_CMD% -Install
goto :end

:run_only
echo.
echo 📦 Initializing Signed Release Bundle only...
%PS_CMD%
goto :end

:cancel
echo.
echo ❌ Release aborted by user.
echo.
goto :end

:end
echo ===================================================
echo ✅ Process Complete.
pause