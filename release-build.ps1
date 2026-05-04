# ==============================================================================
# Alpha Cordova V2 Build Engine (v2.8.5)
# Features: Asset Triage, Zero-Install Turbo Sync, Pre-Warming, Smart Deploy
# ==============================================================================

param (
    [Parameter(Position=0)]
    [string]$BuildMode = "",
    
    [switch]$Install,
    [switch]$BatchMode,
    [switch]$Production,
    [switch]$Quick,
    [string]$Version = "1.0.0"
)

# ==============================================================================
# ENGINE MANAGEMENT TASKS
# ==============================================================================

# TASK: SHUTDOWN (Standard Stop)
if ($BuildMode -eq "Shutdown") {
    Write-Host "`n🛑 Shutting down Alpha Cordova Build Engine..." -ForegroundColor Cyan
    docker compose down
    if (Test-Path ".turbo_ready") { 
        Remove-Item ".turbo_ready" -Force 
        Write-Host "🧹 Cleared Turbo state flags." -ForegroundColor Gray
    }
    Write-Host "✅ All containers stopped. Resources released." -ForegroundColor Green
    exit 0
}

# TASK: PRUNE (Docker Housekeeping)
if ($BuildMode -eq "Prune") {
    Write-Host "`n🧹 Initiating Docker System Prune..." -ForegroundColor Cyan
    Write-Host "This will remove all stopped containers and unused images." -ForegroundColor Gray
    docker system prune -f
    Write-Host "✅ Cleanup complete." -ForegroundColor Green
    exit 0
}

# TASK: DEEP PURGE (The "Nuclear" Option)
if ($BuildMode -eq "Purge") {
    Write-Host "`n🔥 Starting Deep Purge..." -ForegroundColor Red
    Write-Host "🛑 Destroying Docker volumes and containers..." -ForegroundColor Gray
    docker compose down -v
    
    Write-Host "🧹 Unlocking host folders via Docker Janitor..." -ForegroundColor Gray
    $currentDir = Get-Location
    $foldersToWipe = "platforms plugins node_modules debug .turbo_ready android_cache"
    docker run --rm -v "${currentDir}:/work" alpine sh -c "rm -rf $foldersToWipe"
    
    Write-Host "✨ Environment successfully nuked." -ForegroundColor Green
    exit 0
}

# TASK: VOLPRUNE (Global Disk Cleanup)
if ($BuildMode -eq "VolPrune") {
    Write-Host "`n🗄️  Initiating Heavy Global Volume Wipe..." -ForegroundColor Red
    Write-Host "🛑 Stopping all local containers to unlock volumes..." -ForegroundColor Gray
    $running = docker ps -q
    if ($running) { docker stop $running 2>$null }
    
    Write-Host "🧹 Scrubbing all unused volumes..." -ForegroundColor Gray
    docker volume prune -a -f
    
    $volumes = docker volume ls -q
    if ($volumes) { docker volume rm $volumes 2>$null }
    
    Write-Host "✅ Global disk cleanup complete." -ForegroundColor Green
    exit 0
}

# ==============================================================================
# SMART CONFLICT RESOLUTION (Turbo-Friendly)
# ==============================================================================
$conflictName = "alpha-cordova-dev"
$containerStatus = docker inspect --format='{{.State.Status}}' $conflictName 2>$null

if ($containerStatus) {
    if ($containerStatus -eq "running") {
        # Active and healthy - leave it alone for Turbo Sync!
    } else {
        Write-Host "`n🟡 Stale container '$conflictName' found (Status: $containerStatus). Reviving..." -ForegroundColor Yellow
        docker rm -f $conflictName | Out-Null
    }
}

# Ensure the background Dev Container is running
docker compose up -d builder | Out-Null

# Force terminal to UTF8 and create the No-BOM encoder
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Utf8NoBom = New-Object System.Text.UTF8Encoding($False)

# ==============================================================================
# AUDIO INTERFACE
# ==============================================================================
function Play-AudioAlert {
    param([string]$Event)
    try {
        if ($IsLinux -or $PSVersionTable.OS -like "*Linux*") {
            [console]::beep() 
        } else {
            switch ($Event) {
                "Sync"    { [System.Console]::Beep(1000, 100); [System.Console]::Beep(1200, 150) }
                "Success" { [System.Console]::Beep(800, 200); [System.Console]::Beep(1000, 200); [System.Console]::Beep(1200, 400) }
                "Error"   { [System.Console]::Beep(400, 400); [System.Console]::Beep(300, 600) }
            }
        }
    } catch { } 
}

# ==============================================================================
# ALPHA ANYWHERE ASSET TRIAGE
# ==============================================================================
if (Test-Path "temp") {
    Write-Host "`n📂 Alpha Anywhere export detected in 'temp' directory. Migrating assets..." -ForegroundColor Cyan
    
    # 1. Erase existing www directory
    if (Test-Path "www") { Remove-Item -Path "www" -Recurse -Force }
    
    # 2. Recreate www and use bulletproof copy logic
    New-Item -ItemType Directory -Path "www" -Force | Out-Null
    Get-ChildItem -Path "temp" | Copy-Item -Destination "www" -Recurse -Force
    
    # 3. Safely sanitize config.xml using Regex
    $tempConfig = Join-Path "www" "config.xml"
    if (Test-Path $tempConfig) {
        
        # Read the entire file as a single raw string
        $xmlText = [System.IO.File]::ReadAllText($tempConfig)
        
        # Strip outdated AndroidX plugins/preferences
        $xmlText = $xmlText -replace '(?i)<preference[^>]*name="AndroidXEnabled"[^>]*>', ''
        $xmlText = $xmlText -replace '(?i)<plugin[^>]*name="cordova-plugin-androidx-adapter"[^>]*>', ''
        
        # Fix Alpha Anywhere resource paths
        $xmlText = $xmlText -replace 'src="res/', 'src="www/res/'
        $xmlText = $xmlText -replace "src='res/", "src='www/res/"
        $xmlText = $xmlText -replace 'value="res/', 'value="www/res/'
        $xmlText = $xmlText -replace "value='res/", "value='www/res/"
        
        # Enforce SDK Version 36
        if ($xmlText -match 'android-compileSdkVersion') {
            $xmlText = $xmlText -replace 'name="android-compileSdkVersion"\s+value=["'']\d+["'']', 'name="android-compileSdkVersion" value="36"'
        } else {
            # Safely inject right before the closing widget tag
            $xmlText = $xmlText -replace '</widget>', "    <preference name=`"android-compileSdkVersion`" value=`"36`" />`n</widget>"
        }
        
        # Save the sanitized file to the project root using No-BOM UTF-8
        [System.IO.File]::WriteAllText((Join-Path (Get-Location) "config.xml"), $xmlText, $Utf8NoBom)
        
        # Remove the original temp config
        Remove-Item -Path $tempConfig -Force
        Write-Host "📄 Moved and Sanitized config.xml for Android 15 (API 36)." -ForegroundColor Gray
    }
    
    # 4. Clean up temp folder so it doesn't trigger again until a new export
    Remove-Item -Path "temp" -Recurse -Force
    Write-Host "✅ Asset migration complete." -ForegroundColor Green
}

# ==============================================================================
# AIRTIGHT TURBO DETECTION
# ==============================================================================
if ($Quick -or $BuildMode -match "Turbo" -or $args -match "Turbo") {
    $BuildMode = "Turbo"
} else {
    $BuildMode = "Full" 
}

Write-Host "`n🚀 Starting $BuildMode Build Engine..." -ForegroundColor Cyan

if ($BuildMode -eq "Turbo") {
    Write-Host "⚡ Turbo Sync: UI Assets Only + Fast Gradle..." -ForegroundColor Yellow
    
    # Check our state flag
    if (-not (Test-Path ".turbo_ready")) {
        Write-Host "❌ Error: Environment not initialized. Run Option 1 (Full Reset) first." -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    }

    # ==========================================================================
    # SMART ASSET DETECTION
    # ==========================================================================
    $wwwFiles = Get-ChildItem -Path "www" -Recurse -File
    if ($wwwFiles.Count -gt 0) {
        # Find the timestamp of the most recently modified file in www
        $wwwNewest = ($wwwFiles | Measure-Object -Property LastWriteTime -Maximum).Maximum
        $lastSyncFile = ".last_sync_time"
        
        # Load the timestamp of the last successful Turbo Sync
        $lastSync = if (Test-Path $lastSyncFile) { [datetime](Get-Content $lastSyncFile) } else { [datetime]::MinValue }
        
        if ($wwwNewest -gt $lastSync) {
            Write-Host "🔍 Code changes detected in 'www' directory!" -ForegroundColor Magenta
            Write-Host "📂 Syncing updated assets to container..." -ForegroundColor Gray
            $syncCmd = "mkdir -p platforms/android/app/src/main/assets/www && cp -a www/. platforms/android/app/src/main/assets/www/"
            
            # Save the new timestamp for the next run (using ISO 8601 format for safety)
            $wwwNewest.ToString("o") | Set-Content $lastSyncFile -Force
        } else {
            Write-Host "⏭️ No UI changes detected in 'www'. Skipping asset copy..." -ForegroundColor Yellow
            $syncCmd = "true"
        }
    } else { $syncCmd = "true" }

    $gradleArgs = "assembleDebug --parallel --build-cache --daemon --configure-on-demand"
    
    # We combine the Sync (if any) and the Build into ONE single command
    $combinedCmd = "$syncCmd && cd platforms/android && chmod +x gradlew && ./gradlew $gradleArgs"

    Write-Host "🛠️ Running Fast Gradle Build..." -ForegroundColor Green
    Play-AudioAlert -Event "Sync"
    
    try {
        # Execute everything inside the awake container
        docker compose exec builder sh -c $combinedCmd
        if ($LASTEXITCODE -ne 0) { throw "Gradle failed with code $LASTEXITCODE" }
        Write-Host "✅ Build Successful!" -ForegroundColor Green
    } 
    catch {
        Write-Host "❌ Build Error: $_" -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    }
}

else {
    # ==============================================================================
    # FULL RESET & CACHE PRE-WARMING
    # ==============================================================================
    Write-Host "🔄 Full Reset: Rebuilding Android Platform..." -ForegroundColor Magenta

    # 🔥 NEW: The Automated Permission Shield
    # Force root to hand over the freshly created Docker volumes to our user
    Write-Host "🔐 Aligning Volume Permissions for new environment..." -ForegroundColor Gray
    $chownCmd = "chown -R cordovauser:cordovauser /home/cordovauser/app/platforms /home/cordovauser/app/plugins /home/cordovauser/app/node_modules /home/cordovauser/.gradle /home/cordovauser/.npm /home/cordovauser/.android 2>/dev/null || true"
    docker compose exec -u root builder sh -c $chownCmd

    Write-Host "🗑️ Removing old platform (Container Execution)..." -ForegroundColor Gray
    # Execute blindly inside the container since Windows can't see the volume
    docker compose exec builder sh -c "cordova platform remove android --force 2>/dev/null || true"

    Write-Host "➕ Adding Android 15.0.0..." -ForegroundColor Gray
    docker compose exec builder cordova platform add android@15.0.0

    Write-Host "🛠️ Running Standard Cordova Build..." -ForegroundColor Green
    docker compose exec builder cordova build android --debug

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Cordova Build Failed" -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    } else {
        # Create a state flag in the project root
        Write-Host "✅ Initialization Complete. Unlocking Turbo Sync..." -ForegroundColor Green
        New-Item -ItemType File -Path ".turbo_ready" -Force | Out-Null
        Write-Host "🔥 Pre-Warming Turbo Cache..." -ForegroundColor Yellow
        $gradleArgs = "assembleDebug --parallel --build-cache --daemon --configure-on-demand"
        docker compose exec builder sh -c "cd platforms/android && chmod +x gradlew && ./gradlew $gradleArgs > /dev/null 2>&1"
        Write-Host "✨ Cache Ready!" -ForegroundColor Green
    }
}

# ==============================================================================
# ARTIFACT EXPORT & HYBRID DEPLOYMENT
# ==============================================================================
Write-Host "`n📦 Extracting APK from Container Volume..." -ForegroundColor Cyan

# 1. Create a local debug folder if it doesn't exist
if (-not (Test-Path "debug")) { New-Item -ItemType Directory -Path "debug" | Out-Null }

# 2. Tell the container to copy the file from its internal high-speed volume 
#    out to the host-mapped 'debug' directory so Windows can see it.
docker compose exec builder sh -c "cp platforms/android/app/build/outputs/apk/debug/app-debug.apk debug/app-debug.apk 2>/dev/null || true"

$apkPath = "debug\app-debug.apk"
if (Test-Path $apkPath) {
    Write-Host "✅ APK successfully exported to ./$apkPath" -ForegroundColor Green
    if ($Install) {
        Write-Host "🚀 Initiating Smart Deployment..." -ForegroundColor Yellow
        $deployed = $false
        
        # ----------------------------------------------------------------------
        # ROUTE A: LOCAL ADB (For Power Users)
        # ----------------------------------------------------------------------
        $localAdb = Get-Command adb -ErrorAction SilentlyContinue
        if ($localAdb) {
            Write-Host "🔍 Local ADB detected. Checking for connected USB devices..." -ForegroundColor Gray
            $adbDevices = & adb devices | Select-String -Pattern "\bdevice\b"
            if ($adbDevices) {
                Write-Host "🔗 USB Device found! Installing via Local ADB..." -ForegroundColor Magenta
                & adb install -r -d -t $apkPath
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✨ App installed successfully (Local USB)!" -ForegroundColor Green
                    Play-AudioAlert -Event "Success"
                    $deployed = $true
                }
            }
        }
        if (-not $deployed) {
            Write-Host "`n📱 [Wireless Deployment]" -ForegroundColor Cyan
            $deviceIp = Read-Host "Enter Device IP and Port (e.g., 192.168.1.55:12345) or press Enter to skip"
            if (-not [string]::IsNullOrWhiteSpace($deviceIp)) {
                docker compose exec builder adb connect $deviceIp | Out-Null
                docker compose exec builder adb -s $deviceIp install -r -d -t "debug/app-debug.apk"
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✨ App installed successfully (Wireless)!" -ForegroundColor Green
                    Play-AudioAlert -Event "Success"
                }
                docker compose exec builder adb disconnect $deviceIp | Out-Null
            }
        }
    }
} else {
    Write-Host "❌ FATAL: APK was not generated." -ForegroundColor Red
    Play-AudioAlert -Event "Error"
}
Write-Host "`n✨ Process Complete.`n" -ForegroundColor Green
