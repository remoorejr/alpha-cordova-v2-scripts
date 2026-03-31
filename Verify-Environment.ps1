<#
.SYNOPSIS
    Environment Validator for Alpha Cordova Automation Suite v2.2.0.
    Checks for PowerShell version, Docker, WSL 2, and JDK requirements.
#>

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   ALPHA CORDOVA ENVIRONMENT SANITY CHECK (v2.2.0)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
$report = @()

# 1. PowerShell Version Check
$psVer = $PSVersionTable.PSVersion.Major
if ($psVer -lt 7) {
    Write-Host "[!] PowerShell $psVer detected. Note: Script v2.2.0 is 5.1 compatible," -ForegroundColor Yellow
    Write-Host "    but modern PowerShell 7.0+ is recommended for performance." -ForegroundColor Yellow
    $report += "PowerShell: v$psVer (Legacy 5.1 Mode)"
} else {
    Write-Host "[OK] PowerShell $psVer detected." -ForegroundColor Green
    $report += "PowerShell: v$psVer (Modern)"
}

# 2. Docker Status Check
try {
    $dockerCheck = docker version --format '{{.Server.Version}}' 2>$null
    if ($null -ne $dockerCheck) {
        Write-Host "[OK] Docker Engine is running (v$dockerCheck)." -ForegroundColor Green
        $report += "Docker: Running"
    } else { throw }
} catch {
    Write-Host "[FAIL] Docker Engine is not running. Please start Docker Desktop." -ForegroundColor Red
    $report += "Docker: NOT FOUND/NOT RUNNING"
}

# 3. WSL Version Check
try {
    # We check specifically for the presence of version 2 in the output
    $wslList = wsl -l -v | Out-String
    if ($wslList -match " 2") {
        Write-Host "[OK] WSL 2 Backend detected." -ForegroundColor Green
        $report += "WSL: Version 2"
    } else {
        Write-Host "[FAIL] WSL 1 detected. Docker permissions and volumes will fail." -ForegroundColor Red
        Write-Host "       Run 'wsl --set-default-version 2' to upgrade." -ForegroundColor Yellow
        $report += "WSL: Version 1 (NEEDS UPGRADE)"
    }
} catch {
    Write-Host "[FAIL] WSL is not installed. Required for Docker Desktop backend." -ForegroundColor Red
    $report += "WSL: NOT FOUND"
}

# 4. JDK 17+ Check (Required for Android API 36)
try {
    $javaOut = java -version 2>&1 | Out-String
    if ($javaOut -match 'version "(\d+)') {
        $jVer = [int]$Matches[1]
        if ($jVer -ge 17) {
            Write-Host "[OK] JDK $jVer detected." -ForegroundColor Green
            $report += "JDK: v$jVer"
        } else {
            Write-Host "[FAIL] JDK $jVer detected. API 36 requires JDK 17+." -ForegroundColor Red
            $report += "JDK: v$jVer (OUTDATED)"
        }
    } else { throw }
} catch {
    Write-Host "[FAIL] Java (JDK) not found on host path." -ForegroundColor Red
    $report += "JDK: NOT FOUND"
}

# 5. Git Presence Check
try {
    $gitVer = git --version
    Write-Host "[OK] $gitVer detected." -ForegroundColor Green
    $report += "Git: Installed"
} catch {
    Write-Host "[WARNING] Git not found. Auto-versioning and tagging will be disabled." -ForegroundColor Yellow
    $report += "Git: NOT FOUND"
}

Write-Host "`n--- Final Summary ---" -ForegroundColor Cyan
foreach ($item in $report) {
    if ($item -match "FAIL|OUTDATED") {
        Write-Host " [X] $item" -ForegroundColor Red
    } elseif ($item -match "WARNING") {
        Write-Host " [!] $item" -ForegroundColor Yellow
    } else {
        Write-Host " [√] $item" -ForegroundColor Green
    }
}
Write-Host "----------------------"
Write-Host "Ready for Alpha Cordova v2.2.0?" -NoNewline
if ($report -match "FAIL") {
    Write-Host " NO (Fix the Red items above)" -ForegroundColor Red
} else {
    Write-Host " YES" -ForegroundColor Green
}
Write-Host "----------------------`n"