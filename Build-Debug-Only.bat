@echo off
echo ---------------------------------------------------
echo CORDOVA: Generating Debug APK (No Install)
echo ---------------------------------------------------
powershell -ExecutionPolicy Bypass -File .\release-build.ps1 -Debug
echo ---------------------------------------------------
echo APK location: platforms\android\app\build\outputs\apk\debug\
pause
