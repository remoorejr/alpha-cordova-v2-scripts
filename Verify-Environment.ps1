<#
.SYNOPSIS
    Alpha Cordova Environment Diagnostic v2.8.1
    Optimized for Dockerized API 36 Workflows.
#>

Write-Host "--- Alpha Cordova v2.8.1 Environment Check ---" -ForegroundColor Cyan

$ready = $true

# 1. PowerShell Check
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[!] PowerShell 5.1 detected. v2.8.1 is compatible, but PS 7+ is faster." -ForegroundColor Yellow
} else {
    Write-Host "[OK] PowerShell $($PSVersionTable.PSVersion.Major) detected." -ForegroundColor Green
}

# 2. Docker Check
$dockerCheck = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Docker Engine is not running. Please launch Docker Desktop." -ForegroundColor Red
    $ready = $false
} else {
    $dVer = (docker version --format '{{.Server.Version}}')
    Write-Host "[OK] Docker Engine is running (v$dVer)." -ForegroundColor Green
}

# 3. Docker Compose Check (Critical for .env and Volume caching)
$composeCheck = docker compose version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Docker Compose V2 is not detected. Please update Docker Desktop." -ForegroundColor Red
    $ready = $false
} else {
    Write-Host "[OK] Docker Compose V2 is available." -ForegroundColor Green
}

# 4. WSL Check (Critical for performance)
$wslStatus = wsl -l -v 2>$null | Out-String
if ($wslStatus -match "1\s*$") {
    Write-Host "[FAIL] WSL 1 detected. v2.8.1 REQUIRES WSL 2 for high-speed Named Volumes." -ForegroundColor Red
    Write-Host "       Run: 'wsl --set-default-version 2'" -ForegroundColor Gray
    $ready = $false
} elseif ($wslStatus -match "2\s*$") {
    Write-Host "[OK] WSL 2 detected (High Performance Mode)." -ForegroundColor Green
} else {
    Write-Host "[WARN] Could not verify WSL version. Ensure WSL 2 is installed." -ForegroundColor Yellow
}

# 5. Local Variable Conflict Check (Informational)
# We alert the user if they have local SDKs that might conflict with the container isolation
if ($env:JAVA_HOME -or $env:ANDROID_HOME) {
    Write-Host "`n[INFO] Local SDK variables detected (JAVA_HOME/ANDROID_HOME)." -ForegroundColor Cyan
    Write-Host "       The Docker container will ignore these to ensure a clean API 36 build." -ForegroundColor Gray
}

# --- Final Summary ---
Write-Host "`n------------------------------------"
if ($ready) {
    Write-Host " READY FOR ALPHA CORDOVA v2.8.1: YES " -BackgroundColor Green -ForegroundColor White
} else {
    Write-Host " READY FOR ALPHA CORDOVA v2.8.1: NO  " -BackgroundColor Red -ForegroundColor White
    Write-Host " (Please fix [FAIL] items above before building) " -ForegroundColor Yellow
}
Write-Host "------------------------------------"
