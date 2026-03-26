@echo off
echo ---------------------------------------------------
echo ⚡ CORDOVA QUICK SYNC: Android
echo ---------------------------------------------------
powershell -ExecutionPolicy Bypass -File .\release-build.ps1 -Quick -Install
echo ---------------------------------------------------
pause