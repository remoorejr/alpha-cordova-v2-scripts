@echo off
echo ---------------------------------------------------
echo 💎 CORDOVA: Generating Production Release (.aab)
echo ---------------------------------------------------
echo WARNING: This will bump the version and tag the repo.
powershell -ExecutionPolicy Bypass -File .\release-build.ps1
echo ---------------------------------------------------
pause