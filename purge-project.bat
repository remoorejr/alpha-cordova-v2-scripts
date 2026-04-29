@echo off
@cls
chcp 65001 > nul
setlocal enabledelayedexpansion

set "TARGET_DIR=%~dp0"
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"

echo ─────────────────────────────────────────────────────────────────
echo ⚠️  WARNING: PERMANENT DELETION OF BUILD ASSETS
echo ─────────────────────────────────────────────────────────────────
echo This script will use Docker to force-remove the following:
echo   - /platforms (Docker-locked)
echo   - /plugins   (Docker-locked)
echo   - /node_modules
echo.
echo This action is required if you want to delete the entire project
echo folder without Windows "Access Denied" errors.
echo ─────────────────────────────────────────────────────────────────
echo.

:: Confirmation Step
set /p "CONFIRM=👉 Type 'Y' and press Enter to proceed, or any other key to cancel: "

if /i "!CONFIRM!" neq "Y" (
    echo.
    echo ❌ [CANCELLED] Purge aborted. No files were removed.
    timeout /t 3 >nul
    exit /b
)

echo.
echo 🔥 [PURGE] Initializing Docker Janitor...
docker run --rm -v "%TARGET_DIR%:/work" alpine sh -c "rm -rf /work/platforms /work/plugins /work/node_modules"

echo.
echo ✅ [SUCCESS] Docker-locked folders have been removed.
echo 📁 You can now safely right-click and delete the project directory.
echo.
pause