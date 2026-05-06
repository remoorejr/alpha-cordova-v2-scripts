@echo off
REM ==============================================================================
REM Script: pair-device.bat
REM Description: Windows Batch wrapper to securely invoke pair-device.ps1.
REM Execution: Bypasses local execution policies to bridge the host into the container.
REM ==============================================================================

REM Execute the PowerShell script located in the same directory as this batch file
REM -NoProfile: Speeds up execution by skipping the loading of user profiles
REM -ExecutionPolicy Bypass: Prevents standard Windows security blocks for unsigned local scripts
REM -File "%~dp0pair-device.ps1": Dynamically resolves the absolute path to the ps1 file
REM %*: Passes any arguments provided to the .bat file directly into the .ps1 file

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0pair-device.ps1" %*