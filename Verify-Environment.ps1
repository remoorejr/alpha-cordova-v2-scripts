<#
.SYNOPSIS
    Alpha Cordova Environment Diagnostic v2.3.0
#>

Write-Host "--- Alpha Cordova v2.3.0 Environment Check ---" -ForegroundColor Cyan

$ready = $true

# 1. PowerShell Check
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[!] PowerShell 5.1 detected. v2.3.0 is compatible, but PS 7+ is faster." -ForegroundColor Yellow
} else {
    Write-Host "[OK] PowerShell $($PSVersionTable.PSVersion.Major) detected." -ForegroundColor Green
}

# 2. Docker Check
$dockerCheck = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Docker is not running or not installed." -ForegroundColor Red
    $ready = $false
} else {
    $dVer = (docker version --format '{{.Server.Version}}')
    Write-Host "[OK] Docker Engine is running (v$dVer)." -ForegroundColor Green
}

# 3. WSL Check (CRITICAL)
$wslStatus = wsl -l -v 2>$null | Out-String
if ($wslStatus -match "1\s*$") {
    Write-Host "[FAIL] WSL 1 detected. v2.3.0 REQUIRES WSL 2 for Named Volumes." -ForegroundColor Red
    Write-Host "       Run: 'wsl --set-default-version 2'" -ForegroundColor Gray
    $ready = $false
} elseif ($wslStatus -match "2\s*$") {
    Write-Host "[OK] WSL 2 detected (High Performance Mode)." -ForegroundColor Green
} else {
    Write-Host "[WARN] Could not verify WSL version. Ensure WSL 2 is installed." -ForegroundColor Yellow
}

# 4. JDK Check
try {
    $javaVer = java -version 2>&1 | Out-String
    if ($javaVer -match 'version "17') {
        Write-Host "[OK] JDK 17 detected." -ForegroundColor Green
    } else {
        Write-Host "[FAIL] JDK 17 is required for Android 15 (API 36)." -ForegroundColor Red
        $ready = $false
    }
} catch {
    Write-Host "[FAIL] Java not found." -ForegroundColor Red
    $ready = $false
}

# --- Final Summary ---
Write-Host "`n------------------------------------"
if ($ready) {
    Write-Host " READY FOR ALPHA CORDOVA v2.3.0: YES " -BackgroundColor Green -ForegroundColor White
} else {
    Write-Host " READY FOR ALPHA CORDOVA v2.3.0: NO  " -BackgroundColor Red -ForegroundColor White
    Write-Host " (Please fix [FAIL] items above) " -ForegroundColor Yellow
}
Write-Host "------------------------------------"