<#
.SYNOPSIS
    Alpha Cordova Android Build Engine v2.0.0
    Target: Android 15 (API 36)
    Registry: remoorejr/alpha-cordova-android-build
#>

param (
    [Switch]$Install, # Full Build + Install to device
    [Switch]$Debug,   # Generate standalone Debug APK (No version bump)
    [Switch]$Quick    # Turbo Sync: UI/JS/CSS updates only (Fast)
)

$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$CHANGELOG_FILE = Join-Path $P_ROOT "CHANGELOG.md"
$SIGNING_FILE = "release-signing.properties"

# --- 1. VERSION BUMP & CHANGELOG (Production/Install only) ---
$newV = ""
$NeedsCommit = $false

if (-not $Quick -and -not $Debug) {
    Write-Host "🚀 Production Build: Bumping Version..." -ForegroundColor Magenta
    if (Test-Path $C_FILE) {
        [xml]$xml = Get-Content $C_FILE
        $vParts = $xml.widget.version.Split('.')
        $vParts[2] = [int]$vParts[2] + 1
        $newV = $vParts -join '.'
        $vCode = [int]$xml.widget.'android-versionCode' + 1
        
        $xml.widget.version = $newV
        $xml.widget.'android-versionCode' = "$vCode"
        $xml.Save($C_FILE)
        
        Write-Host "New Version: $newV (Code: $vCode)" -ForegroundColor Green

        # Generate Changelog from Git History
        Write-Host "📝 Updating Changelog..." -ForegroundColor Gray
        $lastTag = git describe --tags --abbrev=0 2>$null
        $logs = if ($null -eq $lastTag) { git log --pretty=format:"* %s (%h)" -n 10 } 
               else { git log "$($lastTag)..HEAD" --pretty=format:"* %s (%h)" }
        
        $header = "## [$newV] - $(Get-Date -Format 'yyyy-MM-dd')`n$logs`n"
        if (Test-Path $CHANGELOG_FILE) {
            $oldContent = Get-Content $CHANGELOG_FILE -Raw
            $header + "`n" + $oldContent | Set-Content $CHANGELOG_FILE
        } else {
            "# Changelog`n`n" + $header | Set-Content $CHANGELOG_FILE
        }
        $NeedsCommit = $true
    } else {
        Write-Error "config.xml not found! Skipping version bump."
    }
}

# --- 2. CLEAN & RESTORE ---
if (-not $Quick) {
    Write-Host "🔄 Full Reset: Cleaning platforms..." -ForegroundColor Cyan
    $P_DIR = Join-Path $P_ROOT "platforms"
    if (Test-Path $P_DIR) { 
        Remove-Item -Path $P_DIR -Recurse -Force -ErrorAction SilentlyContinue 
    }
    Write-Host "Initializing Android platform (API 36)..." -ForegroundColor Gray
    docker compose run --rm builder cordova platform add android --nosave
} else {
    Write-Host "⚡ Turbo Mode: Keeping existing platform..." -ForegroundColor Yellow
}

# --- 3. BUILD & DEPLOY LOGIC ---
$FINAL_OUT = ""

if ($Quick) {
    Write-Host "🚀 Fast Syncing UI changes..." -ForegroundColor Green
    docker compose run --rm builder cordova prepare android
    
    if ($Install) {
        Write-Host "Installing to device via Turbo Sync..."
        adb kill-server
        Start-Process adb -ArgumentList "-a nodaemon server start" -WindowStyle Hidden
        docker compose run --rm -e ADB_SERVER_SOCKET=tcp:host.docker.internal:5037 builder cordova run android --debug --nobuild --nosearch
    }
}
else {
    if ($Install) {
        Write-Host "Mode: Debug Install" -ForegroundColor Cyan
        adb kill-server
        Start-Process adb -ArgumentList "-a nodaemon server start" -WindowStyle Hidden
        docker compose run --rm -e ADB_SERVER_SOCKET=tcp:host.docker.internal:5037 builder cordova run android --debug --nosearch
    }
    elseif ($Debug) {
        Write-Host "Mode: Standalone Debug APK" -ForegroundColor Cyan
        Write-Host "Note: Version remains unchanged for Debug builds." -ForegroundColor Gray
        docker compose run --rm builder cordova build android --debug --nosearch
        $FINAL_OUT = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk"
    }
    else {
        Write-Host "💎 Mode: Production Release (.aab)" -ForegroundColor Yellow
        
        # Security Audit: Check for signing credentials
        if (Test-Path $SIGNING_FILE) {
            $props = Get-Content $SIGNING_FILE
            if ($props -match "your_password" -or $props -match "your-key-alias") {
                Write-Host "⚠️  WARNING: Placeholder values detected in $SIGNING_FILE." -ForegroundColor Yellow
            }
            Write-Host "🔐 Signed bundle requested..." -ForegroundColor Green
            docker compose run --rm builder cordova build android --release -- --buildConfig=$SIGNING_FILE
        } else {
            Write-Host "ℹ️  No '$SIGNING_FILE' found. Generating UNSIGNED bundle." -ForegroundColor Cyan
            docker compose run --rm builder cordova build android --release --nosearch
        }
        $FINAL_OUT = Join-Path $P_ROOT "platforms/android/app/build/outputs/bundle/release/app-release.aab"
    }
}

# --- 4. VERIFY, COMMIT & TAG ---
if ($NeedsCommit) {
    if ($Install -or (Test-Path $FINAL_OUT)) {
        Write-Host "✅ Build Successful! Committing and Tagging..." -ForegroundColor Green
        git add $C_FILE $CHANGELOG_FILE
        git commit -m "release v$newV"
        git tag -a "v$newV" -m "Automated release v$newV"
        
        if ($FINAL_OUT) { Write-Host "📦 Artifact: $FINAL_OUT" }
        Write-Host "🚀 Version $newV is locked and tagged." -ForegroundColor Green
    } else {
        Write-Error "Build failed. Version bump and Tagging aborted."
        exit 1
    }
}
elseif (-not $Install -and $FINAL_OUT) {
    if (Test-Path $FINAL_OUT) {
        Write-Host "✅ Debug Build Complete (No version change)." -ForegroundColor Green
        Write-Host "📦 Artifact: $FINAL_OUT"
    } else {
        Write-Error "Build artifact not found at $FINAL_OUT"
        exit 1
    }
}

Write-Host "--- Build Script Finished ---"
[System.Media.SystemSounds]::Asterisk.Play()