<#
.SYNOPSIS
    Alpha Cordova Android Build Engine v2.4.1
    Target: Android 15 (API 36 / Baklava)
#>

param (
    [Switch]$Install,
    [Switch]$Release,
    [Switch]$Quick
)

$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$CHANGELOG_FILE = Join-Path $P_ROOT "CHANGELOG.md"
$SIGNING_FILE = "release-signing.properties"

# --- 1. PRE-FLIGHT CHECKS ---
Write-Host "--- Running Pre-flight checks ---" -ForegroundColor Gray

try {
    $javaVerOutput = java -version 2>&1 | Out-String
    if ($javaVerOutput -match 'version "(\d+)') {
        $jVer = [int]$Matches[1]
        if ($jVer -lt 17) {
            Write-Host "WARNING: JDK $jVer detected. API 36 requires JDK 17+." -ForegroundColor Yellow
        } else {
            Write-Host "JDK $jVer detected." -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Java not found." -ForegroundColor Red
}

$isGitRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
$newV = ""
$NeedsCommit = $false

# --- 2. VERSIONING LOGIC ---
if ($Release -and -not $Quick -and $isGitRepo) {
    if (Test-Path $C_FILE) {
        [xml]$xml = Get-Content $C_FILE
        $root = $xml.DocumentElement
        $vParts = $root.version.Split('.')
        $vParts[2] = [int]$vParts[2] + 1
        $newV = $vParts -join '.'
        $vCode = [int]$root.'android-versionCode' + 1
        $root.version = $newV
        $root.'android-versionCode' = "$vCode"
        $xml.Save($C_FILE)
        
        Write-Host "Version Bumped: $newV" -ForegroundColor Magenta

        $lastTag = git describe --tags --abbrev=0 2>$null
        if ($null -eq $lastTag) {
            $logs = git log --pretty=format:"* %s (%h)" -n 10
        } else {
            $logs = git log "$($lastTag)..HEAD" --pretty=format:"* %s (%h)"
        }
        
        $header = "## [$newV] - $(Get-Date -Format 'yyyy-MM-dd')`n$logs`n"
        if (Test-Path $CHANGELOG_FILE) {
            $oldContent = Get-Content $CHANGELOG_FILE -Raw
            Set-Content $CHANGELOG_FILE -Value ($header + "`n" + $oldContent)
        } else {
            Set-Content $CHANGELOG_FILE -Value ("# Changelog`n`n" + $header)
        }
        $NeedsCommit = $true
    }
}

# --- 3. CLEAN & RESTORE ---
if (-not $Quick) {
    Write-Host "Cleaning platforms..." -ForegroundColor Cyan
    $P_DIR = Join-Path $P_ROOT "platforms"
    if (Test-Path $P_DIR) { 
        Remove-Item -Path $P_DIR -Recurse -Force -ErrorAction SilentlyContinue 
    }
    Write-Host "Initializing Android platform (API 36)..."
    docker compose run --rm builder cordova platform add android --nosave
}

# --- 4. BUILD LOGIC ---
# Define the expected output paths immediately so they aren't empty
if ($Release) {
    $FINAL_OUT = Join-Path $P_ROOT "platforms/android/app/build/outputs/bundle/release/app-release.aab"
} else {
    $FINAL_OUT = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk"
}

if ($Quick) {
    Write-Host "Turbo Syncing..." -ForegroundColor Yellow
    docker compose run --rm builder cordova prepare android
} elseif ($Release) {
    Write-Host "Mode: Production Release (.aab)" -ForegroundColor Yellow
    if (Test-Path $SIGNING_FILE) {
        docker compose run --rm builder cordova build android --release -- --buildConfig=$SIGNING_FILE
    } else {
        docker compose run --rm builder cordova build android --release --nosearch
    }
} else {
    Write-Host "Mode: Debug Build (.apk)" -ForegroundColor Cyan
    docker compose run --rm builder cordova build android --debug --nosearch
}

# --- 5. DEVICE CHECK & INSTALL ---
if ($Install) {
    Write-Host "Checking for devices..." -ForegroundColor Gray
    adb start-server > $null
    $devices = adb devices | Select-String -Pattern "\tdevice$"
    if ($null -eq $devices -or $devices.Count -eq 0) {
        Write-Host "No device found. Skipping install." -ForegroundColor Yellow
    } else {
        Write-Host "Installing..." -ForegroundColor Magenta
        adb kill-server
        Start-Process adb -ArgumentList "-a nodaemon server start" -WindowStyle Hidden
        $runArgs = if ($Release) { "--release" } else { "--debug" }
        # Added --nobuild to ensure Turbo stays fast
        docker compose run --rm -e ADB_SERVER_SOCKET=tcp:host.docker.internal:5037 builder cordova run android $runArgs --nobuild --nosearch
    }
}

# --- 6. VERIFY & FINALIZING ---
# Only perform the file check if it wasn't a Quick build (since Quick doesn't generate a new file)
if (-not $Quick) {
    if ($FINAL_OUT -and (Test-Path $FINAL_OUT)) {
        Write-Host "Build Successful!" -ForegroundColor Green
        $rawSize = (Get-Item $FINAL_OUT).Length / 1MB
        $prettySize = "{0:N2}" -f $rawSize
        Write-Host "Artifact: $FINAL_OUT ($prettySize MB)"
        
        if ($NeedsCommit) {
            git add $C_FILE $CHANGELOG_FILE
            git commit -m "release v$newV"
            git tag -a "v$newV" -m "Automated release v$newV"
            Write-Host "Git Tag v$newV Created." -ForegroundColor Green
        }
    } else {
        Write-Error "Build artifact not found."
    }
} else {
    Write-Host "Turbo Sync Complete. (No new artifact generated)" -ForegroundColor Green
}

Write-Host "--- Build Script Finished ---"
[System.Media.SystemSounds]::Asterisk.Play()