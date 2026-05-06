# ==============================================================================
# Script: pair-device.ps1
# Description: One-time interactive ADB pairing for new Android 11+ devices.
# Execution: Runs entirely via Docker exec to strictly enforce container isolation.
# ==============================================================================

param (
    [Parameter(Mandatory=$false)]
    [string]$PairingAddress
)

Write-Host "`n📱 [Android Wireless Debugging Initial Setup]" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Ensure your Android device is on the same Wi-Fi network."
Write-Host "Navigate to Developer Options -> Wireless Debugging -> Pair device with pairing code."
Write-Host "==================================================`n"

if (-not $PairingAddress) {
    $PairingAddress = Read-Host "Enter the Device IP and Pairing Port (e.g., 192.168.1.55:43210)"
}

if (-not [string]::IsNullOrWhiteSpace($PairingAddress)) {
    Write-Host "`nBridging interactive terminal to the container..." -ForegroundColor Yellow
    
    # The -it flags are strictly required here to pass stdin (the pairing code) 
    # from the Windows host directly into the container's adb process.
    docker compose exec -it builder adb pair $PairingAddress
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Device paired successfully!" -ForegroundColor Green
        Write-Host "The ADB RSA key is now persistently stored in the container's mapped volume." -ForegroundColor Green
        Write-Host "You may now use the standard build scripts for automated deployment without pairing again.`n" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Pairing failed. Verify the IP and Port are exactly as shown on the pairing screen and try again.`n" -ForegroundColor Red
    }
} else {
    Write-Host "`nOperation cancelled.`n" -ForegroundColor Yellow
}