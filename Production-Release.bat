@echo off
setlocal EnableDelayedExpansion
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

:: --- Existing Step 1: Confirmation ---
set /p confirm="Proceed with Production Release? (Y/N): "
if /i "%confirm%" neq "Y" goto :cancel

:: --- New Step 2: Manual Version Input ---
echo.
echo [?] To auto-increment (e.g. 2.1.0 -> 2.1.1), press ENTER.
echo [?] To force a version (e.g. 2.2.0), type it below.
set /p manual_version="Target Version: "

:: --- Existing Step 3: Install Prompt ---
echo.
echo [?] Would you like to install to the device after the build?
set /p install="Install to device? (Y/N): "

:: --- Construction: Build the Command ---
set ARGS=-Release

:: Add ResetVersion if provided
if not "%manual_version%"=="" (
    set ARGS=!ARGS! -ResetVersion "%manual_version%"
)

:: Add Install if requested
if /i "%install%"=="Y" (
    set ARGS=!ARGS! -Install
    echo.
    echo 🚀 Initializing Signed Release + Install...
) else (
    echo.
    echo 📦 Initializing Signed Release Bundle only...
)

:: --- Execution ---
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" !ARGS!
goto :end

:cancel
echo.
echo ❌ Release aborted by user.
echo.

:end
echo ===================================================
echo ✅ Process Complete.
pause