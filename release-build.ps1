# ==============================================================================
# Alpha Cordova V2 Build Engine
# Optimized for Turbo Sync, ADB Deployment, Artifact Export, and Audio
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

# Ensure the background Dev Container is running
docker compose up -d builder | Out-Null

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
                "Sync"    { 
                    [System.Console]::Beep(1000, 100) 
                    [System.Console]::Beep(1200, 150) 
                }
                "Success" { 
                    [System.Console]::Beep(800, 200)
                    [System.Console]::Beep(1000, 200)
                    [System.Console]::Beep(1200, 400) 
                }
                "Error"   { 
                    [System.Console]::Beep(400, 400)
                    [System.Console]::Beep(300, 600) 
                }
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
    
    # 2. Recreate www and copy all files from temp
    New-Item -ItemType Directory -Path "www" -Force | Out-Null
    Copy-Item -Path "temp\*" -Destination "www" -Recurse -Force
    
    # 3. Safely sanitize config.xml
    $tempConfig = Join-Path "www" "config.xml"
    if (Test-Path $tempConfig) {
        
        # Read the entire file as a single raw string (immune to line-break formatting)
        $xmlText = [System.IO.File]::ReadAllText($tempConfig)
        
        # Strip outdated AndroidX plugins/preferences by targeting the XML tags directly
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
        $Utf8NoBom = New-Object System.Text.UTF8Encoding($False)
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

$androidRoot = "platforms/android"

Write-Host "`n🚀 Starting $BuildMode Build Engine..." -ForegroundColor Cyan

if ($BuildMode -eq "Turbo") {
    Write-Host "⚡ Turbo Sync: UI Assets Only + Fast Gradle..." -ForegroundColor Yellow
    
    # Check our state flag
    if (-not (Test-Path ".turbo_ready")) {
        Write-Host "❌ Error: Environment not initialized. Run Option 1 (Full Reset) first." -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    }

    $gradleArgs = "assembleDebug --parallel --build-cache --daemon --configure-on-demand"
    
    # We combine the Sync and the Build into ONE single command to avoid the 15-second Docker startup penalty
    $combinedCmd = "mkdir -p platforms/android/app/src/main/assets/www && cp -a www/. platforms/android/app/src/main/assets/www/ && cd platforms/android && chmod +x gradlew && ./gradlew $gradleArgs"

    Write-Host "🛠️ Running Unified Fast-Sync & Build..." -ForegroundColor Green
    Play-AudioAlert -Event "Sync"
    
    try {
        # Execute everything inside a single container lifecycle using 'exec'
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
    # FULL RESET
    # ==============================================================================
    Write-Host "🔄 Full Reset: Rebuilding Android Platform..." -ForegroundColor Magenta

    Write-Host "🗑️ Removing old platform (Container Execution)..." -ForegroundColor Gray
    # We execute this blindly inside the container since Windows can't see the volume
    # '|| true' ensures the script doesn't crash if the platform doesn't exist yet
    docker compose exec builder sh -c "cordova platform remove android --force 2>/dev/null || true"

    Write-Host "➕ Adding Android 15.0.0..." -ForegroundColor Gray
    docker compose exec builder cordova platform add android@15.0.0

    Write-Host "🛠️ Running Standard Cordova Build to initialize environment..." -ForegroundColor Green
    docker compose exec builder cordova build android --debug

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Cordova Build Failed" -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    } else {
        # ✅ NEW: Create a state flag in the project root (which Windows CAN see)
        Write-Host "✅ Initialization Complete. Unlocking Turbo Sync..." -ForegroundColor DarkGray
        New-Item -ItemType File -Path ".turbo_ready" -Force | Out-Null
    }
}

# ==============================================================================
# ARTIFACT EXPORT & HYBRID DEPLOYMENT LOGIC
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
                } else {
                    Write-Host "⚠️ Local ADB Install failed. Falling back to Wireless..." -ForegroundColor Yellow
                }
            } else {
                Write-Host "⚠️ Local ADB found, but no USB devices connected. Falling back to Wireless..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "🛡️ Zero-Install mode active (No local ADB detected)." -ForegroundColor Cyan
        }
        
        # ----------------------------------------------------------------------
        # ROUTE B: WIRELESS ZERO-INSTALL (For Clean Machines)
        # ----------------------------------------------------------------------
        if (-not $deployed) {
            Write-Host "`n📱 [Wireless Deployment]" -ForegroundColor Cyan
            Write-Host "Please check your phone's 'Wireless Debugging' settings." -ForegroundColor Gray
            $deviceIp = Read-Host "Enter Device IP and Port (e.g., 192.168.1.55:12345) or press Enter to skip"
            
            if (-not [string]::IsNullOrWhiteSpace($deviceIp)) {
                Write-Host "🔗 Connecting container directly to phone via Wi-Fi..." -ForegroundColor Gray
                
                # 1. Connect the Container's ADB to the Phone
                docker compose exec builder adb connect $deviceIp | Out-Null
                
                # 2. Install the APK (Explicitly targeting the IP)
                Write-Host "📲 Installing APK..." -ForegroundColor Magenta
                docker compose exec builder adb -s $deviceIp install -r -d -t "debug/app-debug.apk"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✨ App installed successfully (Wireless)!" -ForegroundColor Green
                    Play-AudioAlert -Event "Success"
                } else {
                    Write-Host "⚠️ Wireless Install failed." -ForegroundColor Red
                    Play-AudioAlert -Event "Error"
                }
                
                # 3. Clean up the connection to prevent ghost devices on the next run
                docker compose exec builder adb disconnect $deviceIp | Out-Null
            } else {
                Write-Host "⏭️ Skipped installation." -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host "❌ FATAL: APK was not generated or could not be extracted from the volume." -ForegroundColor Red
    Play-AudioAlert -Event "Error"
}
Write-Host "`n✨ Process Complete.`n" -ForegroundColor Green
