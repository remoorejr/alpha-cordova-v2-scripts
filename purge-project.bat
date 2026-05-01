@echo off
@cls
chcp 65001 > nul
setlocal enabledelayedexpansion

set "TARGET_DIR=%~dp0"
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"

echo ─────────────────────────────────────────────────────────────────
echo ⚠️  WARNING: PERMANENT DELETION OF BUILD ASSETS
echo ─────────────────────────────────────────────────────────────────
echo This script will execute a Deep Clean:
echo   1. Shut down the background Dev Container.
echo   2. Destroy all Docker Named Volumes (Gradle/SDK caches).
echo   3. Force-remove Docker-locked folders (/platforms, /plugins).
echo.
echo This action is required if you want to completely reset the
echo environment or delete the project without "Access Denied" errors.
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
echo 🛑 [SHUTDOWN] Stopping persistent Dev Container and wiping volumes...
docker compose down -v

echo.
echo 🔥 [PURGE] Initializing Docker Janitor to clean host files...
docker run --rm -v "%TARGET_DIR%:/work" alpine sh -c "rm -rf /work/platforms /work/plugins /work/node_modules /work/debug /work/.turbo_ready /work/android_cache"

echo.
echo ✅ [SUCCESS] Environment destroyed and host files unlocked.
echo 📁 You can now safely run a Full Reset or delete the project directory.
echo.
pause