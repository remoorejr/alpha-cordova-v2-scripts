<#
.SYNOPSIS
    Alpha Cordova Android Build Engine v2.4.5
    Target: Android 15 (API 36 / Baklava)
#>

param (
    [Switch]$Install,
    [Switch]$Release,
    [Switch]$Quick,
    [string]$ResetVersion,   
    [Switch]$SkipConfirm     
)

# --- CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$CHANGELOG_FILE = Join-Path $P_ROOT "CHANGELOG.md"
$SIGNING_FILE = "build.json" 

# PRE-DEFINE PATHS (Ensures variables are never null during verification)
$AAB_OUT    = Join-Path $P_ROOT "platforms/android/app/build/outputs/bundle/release/app-release.aab"
$APK_OUT    = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/release/app-release.apk"
$DEBUG_OUT  = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk"

# Set the primary target to watch for the final report
$FINAL_OUT = if ($Release) { $AAB_OUT } else { $DEBUG_OUT }

# Suppression and Home Path Redirection
$SUPPRESS_FLAGS = "-e CI=true -e INSIGHT_FORCE_NO_USAGE=true -e NPM_CONFIG_UPDATE_NOTIFIER=false -e HOME=/home/cordovauser/app"

# --- PERMISSION & TELEMETRY SANITIZATION ---
Write-Host "Checking environment permissions..." -ForegroundColor Cyan
$configPath = Join-Path $PSScriptRoot ".config"
if (Test-Path $configPath) { Remove-Item -Path $configPath -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $configPath -Force | Out-Null
icacls $configPath /grant Everyone:F /T /q
Write-Host "Permissions sanitized and Home Path redirected." -ForegroundColor Green

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

# --- 2. VERSIONING & PREVIEW LOGIC ---
if ($Release -and -not $Quick -and $isGitRepo) {
    if (Test-Path $C_FILE) {
        [xml]$xml = Get-Content $C_FILE
        $root = $xml.DocumentElement
        $oldV = $root.version
        
        # Calculate New Version
        if ($ResetVersion) {
            $newV = $ResetVersion
            $actionText = "MANUAL RESET"
        } else {
            $vParts = $oldV.Split('.')
            $vParts[2] = [int]$vParts[2] + 1
            $newV = $vParts -join '.'
            $actionText = "AUTO-INCREMENT"
        }

        # --- VERSION PREVIEW PROMPT ---
        if (-not $SkipConfirm) {
            Write-Host "`n--- VERSION PREVIEW ---" -ForegroundColor Cyan
            Write-Host "Current Version: " -NoNewline; Write-Host $oldV -ForegroundColor Gray
            Write-Host "New Version:     " -NoNewline; Write-Host $newV -ForegroundColor Yellow
            Write-Host "Action:          " -NoNewline; Write-Host $actionText -ForegroundColor Magenta
            
            $confirmation = Read-Host "`nProceed with this version? (Y/N)"
            if ($confirmation -ne "Y") {
                Write-Host "Build cancelled by user." -ForegroundColor Red
                exit 0
            }
        }

        # Apply changes to XML
        $vCode = [int]$root.'android-versionCode' + 1
        $root.version = $newV
        $root.'android-versionCode' = "$vCode"
        $xml.Save($C_FILE)
        
        # Update Changelog
        $lastTag = git describe --tags --abbrev=0 2>$null
        $logs = if ($null -eq $lastTag) { git log --pretty=format:"* %s (%h)" -n 10 } else { git log "$($lastTag)..HEAD" --pretty=format:"* %s (%h)" }
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
    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova platform add android --nosave"
}

# --- CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$CHANGELOG_FILE = Join-Path $P_ROOT "CHANGELOG.md"
$SIGNING_FILE = "build.json"  # UPDATED: Now points to the JSON file

# ... [Keep Sanitization and Versioning blocks the same] ...

# --- 4. BUILD LOGIC ---
if ($Release) {
    Write-Host "Mode: Production Release (v$newV)" -ForegroundColor Yellow
    
    $signingArg = if (Test-Path $SIGNING_FILE) { "--buildConfig=$SIGNING_FILE" } else { "" }

    # STEP A: Build the Store Bundle (.aab)
    Write-Host "Generating Signed Production Bundle (.aab)..." -ForegroundColor Gray
    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --release $signingArg -- --packageType=bundle"
    if ($LASTEXITCODE -ne 0) { Write-Error "Bundle build failed."; exit 1 }

    # STEP B: If -Install is requested, build the Signed APK (.apk)
    if ($Install) {
        Write-Host "Generating Signed APK for device testing..." -ForegroundColor Gray
        Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --release $signingArg -- --packageType=apk"
        if ($LASTEXITCODE -ne 0) { Write-Error "APK build failed."; exit 1 }
    }
} else {
    Write-Host "Mode: Debug Build (.apk)" -ForegroundColor Cyan
    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --debug --nosearch"
    if ($LASTEXITCODE -ne 0) { Write-Error "Debug build failed."; exit 1 }
}

# --- 5. DEVICE CHECK & INSTALL ---
if ($Install) {
    Write-Host "Checking for devices..." -ForegroundColor Gray
    adb start-server > $null
    $deviceLine = adb devices | Select-String -Pattern "\tdevice$" | Select-Object -First 1
    
    if ($null -eq $deviceLine) {
        Write-Host "No device found. Skipping install." -ForegroundColor Yellow
    } else {
        $deviceID = $deviceLine.ToString().Split("`t")[0].Trim()
        
        # Path Correction: Release APKs are usually just named 'app-release.apk' when signed
        $targetFile = if ($Release) { 
            Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/release/app-release.apk" 
        } else { 
            Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk" 
        }
        
        # Force a small wait for WSL file sync
        Start-Sleep -Seconds 1

        if (Test-Path $targetFile) {
            Write-Host "Installing $targetFile to device [$deviceID]..." -ForegroundColor Magenta
            adb -s $deviceID install -r "$targetFile"
        } else {
            # Check for common alternative naming convention
            $altFile = $targetFile.Replace(".apk", "-signed.apk")
            if (Test-Path $altFile) {
                adb -s $deviceID install -r "$altFile"
            } else {
                Write-Error "Cannot install: Signed artifact not found at $targetFile"
            }
        }
    }
}

# --- 6. VERIFY & FINALIZING ---
if (-not $Quick) {
    Write-Host "Finalizing artifacts..." -ForegroundColor Gray
    Start-Sleep -Seconds 2 # Wait for WSL file sync

    # Check if the variable exists AND the file is physically there
    if ($null -ne $FINAL_OUT -and (Test-Path $FINAL_OUT)) {
        Write-Host "`n========================================================" -ForegroundColor Green
        Write-Host "🚀 BUILD SUCCESSFUL: v$newV" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Green
        
        $rawSize = (Get-Item $FINAL_OUT).Length / 1MB
        $prettySize = "{0:N2}" -f $rawSize
        Write-Host "Primary Artifact (Store): $FINAL_OUT ($prettySize MB)"
        
        if ($Release -and (Test-Path $APK_OUT)) {
            Write-Host "Testing Artifact (APK):   $APK_OUT"
        }

        if ($NeedsCommit) {
            Write-Host "`nUpdating Repository..." -ForegroundColor Cyan
            git add $C_FILE $CHANGELOG_FILE
            git commit -m "release v$newV"
            git tag -a "v$newV" -m "Automated release v$newV"
            Write-Host "Git Tag v$newV Created and Committed." -ForegroundColor Green
        }
    } else {
        # Final safety check if Windows is just slow to sync
        if ($null -ne $FINAL_OUT) {
            Write-Host "Waiting for file system sync..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            if (Test-Path $FINAL_OUT) {
                 Write-Host "Artifact verified after sync delay." -ForegroundColor Green
            } else {
                 Write-Warning "Build finished, but the artifact could not be verified at: $FINAL_OUT"
            }
        } else {
            Write-Error "Variable `$FINAL_OUT` is not defined. Check Section 4 of the script."
        }
    }
} else {
    Write-Host "Turbo Sync Complete." -ForegroundColor Green
}

Write-Host "`n--- Build Script Finished ---"
[System.Media.SystemSounds]::Asterisk.Play()