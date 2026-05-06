# ==============================================================================
# Script: pair-device.ps1
# Description: One-time interactive ADB pairing for new Android 11+ devices.
# Execution: Runs entirely via Docker exec to strictly enforce container isolation.
# ==============================================================================

param (
    [Parameter(Mandatory=$false)]
    [string]$PairingAddress
)

# Force PowerShell console to render UTF-8 characters (emojis) correctly
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ''
Write-Host '📱 [Android Wireless Debugging Initial Setup]' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan

# Pre-flight Check: Ensure the target container is actively running
$containerStatus = (docker compose ps --services --filter 'status=running' 2>&1) -join ' '
if ($containerStatus -notmatch 'builder') {
    Write-Host '❌ ERROR: The Docker environment is offline.' -ForegroundColor Red
    Write-Host 'The "builder" container must be actively running to establish an ADB bridge.' -ForegroundColor Yellow
    Write-Host 'Please start your environment (e.g., via option [1] Full Reset) and try again.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

Write-Host 'Ensure your Android device is on the same Wi-Fi network.'
Write-Host 'Navigate to Developer Options -> Wireless Debugging -> Pair device with pairing code.'
Write-Host '=================================================='
Write-Host ''

if (-not $PairingAddress) {
    $PairingAddress = Read-Host 'Enter the Device IP and Pairing Port (e.g., 192.168.1.55:43210)'
}

if (-not [string]::IsNullOrWhiteSpace($PairingAddress)) {
    Write-Host ''
    Write-Host 'Bridging interactive terminal to the container...' -ForegroundColor Yellow
    
    # The -it flags are strictly required here to pass stdin (the pairing code) 
    # from the Windows host directly into the containers adb process.
    docker compose exec -it builder adb pair $PairingAddress
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ''
        Write-Host '✅ Device paired successfully!' -ForegroundColor Green
        Write-Host 'The ADB RSA key is now persistently stored in the mapped volume.' -ForegroundColor Green
        Write-Host 'You may now use the standard build scripts for automated deployment without pairing again.' -ForegroundColor Cyan
        Write-Host ''
    } else {
        Write-Host ''
        Write-Host '❌ Pairing failed. Verify the IP and Port are exactly as shown on the pairing screen and try again.' -ForegroundColor Red
        Write-Host ''
    }
} else {
    Write-Host ''
    Write-Host 'Operation cancelled.' -ForegroundColor Yellow
    Write-Host ''
}