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
    
    if (Test-Path "www") {
        # --- Change Detection Engine ---
        $sourceLatest = (Get-ChildItem -Path "www" -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        $targetLatest = (Get-ChildItem -Path "$androidRoot/app/src/main/assets/www" -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        
        if ($null -eq $targetLatest -or $sourceLatest -gt $targetLatest) {
            Write-Host "`n🔊 Code change detected in www/ directory! Syncing assets..." -ForegroundColor Cyan
            Play-AudioAlert -Event "Sync"
            
            # Ensure the destination exists first
            if (!(Test-Path "$androidRoot/app/src/main/assets/www/")) { 
                 New-Item -ItemType Directory -Path "$androidRoot/app/src/main/assets/www/" -Force | Out-Null
            }

            # RELIABLE COPY: Using Get-ChildItem prevents the "leaf item" error
            Get-ChildItem -Path "www\*" | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination "$androidRoot/app/src/main/assets/www/" -Recurse -Force
            }
        } else {
            Write-Host "`n⏩ No changes detected in www/. Skipping UI file sync." -ForegroundColor DarkCyan
        }
    } # <-- End of if (Test-Path "www")

    # --- Gradle Execution ---
    if (-not (Test-Path $androidRoot)) {
        Write-Host "❌ Error: Platforms folder missing. Run Option 1 (Full Reset) first." -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    }

    # Move context into the Android platform folder
    Push-Location $androidRoot
    
    # Final check: Ensure we are standing next to gradlew.bat
    if (-not (Test-Path "gradlew.bat")) {
        Write-Host "❌ Error: gradlew.bat not found in $androidRoot. Full build required." -ForegroundColor Red
        Pop-Location
        exit 1
    }

    $gradleArgs = @(
        "assembleDebug", 
        "--parallel", 
        "--build-cache", 
        "--daemon", 
        "--configure-on-demand"
    )

    Write-Host "🛠️  Running Optimized Gradle Build..." -ForegroundColor Green
    try {
        if ($IsLinux -or $PSVersionTable.OS -like "*Linux*") {
            chmod +x gradlew 2>$null
            & sh ./gradlew $gradleArgs
        } else {
            # Use & to execute the local file explicitly
            & .\gradlew.bat $gradleArgs
        }
        
        if ($LASTEXITCODE -ne 0) { throw "Gradle failed with code $LASTEXITCODE" }
        Write-Host "✅ Build Successful!" -ForegroundColor Green
    } 
    catch {
        Write-Host "❌ Build Error: $_" -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        Pop-Location
        exit 1
    }
    
    Pop-Location 
} # <-- End of if ($BuildMode -eq "Turbo")
else {
    # ==============================================================================
    # FULL RESET
    # ==============================================================================
    Write-Host "🔄 Full Reset: Rebuilding Android Platform..." -ForegroundColor Magenta
    
    if (Test-Path "platforms/android") {
        cordova platform remove android --force | Out-Null
    }
    cordova platform add android@15.0.0
    
    Write-Host "🛠️  Running Standard Cordova Build to initialize environment..." -ForegroundColor Green
    cordova build android --debug
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Cordova Build Failed" -ForegroundColor Red
        Play-AudioAlert -Event "Error"
        exit 1
    }
}

# ==============================================================================
# ARTIFACT EXPORT & DEPLOYMENT LOGIC
# ==============================================================================

$apkPath = Get-ChildItem -Path $androidRoot -Filter "*debug*.apk" -Recurse -ErrorAction SilentlyContinue | 
           Sort-Object LastWriteTime -Descending | 
           Select-Object -First 1 -ExpandProperty FullName

if ($apkPath -and (Test-Path $apkPath)) {
    Write-Host "`n📦 Found compiled APK at: $apkPath" -ForegroundColor Cyan
    
    $exportDir = "debug"
    if (-not (Test-Path $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir | Out-Null
    }
    
    Write-Host "💾 Exporting APK to ./$exportDir/app-debug.apk..." -ForegroundColor Green
    Copy-Item -Path $apkPath -Destination "$exportDir/app-debug.apk" -Force
    
    if ($Install) {
        Write-Host "🚀 Installing via ADB to connected device..." -ForegroundColor Yellow
        & adb install -r -d -t "$exportDir/app-debug.apk"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✨ App installed and updated successfully!" -ForegroundColor Green
            Play-AudioAlert -Event "Success"
        } else {
            Write-Host "⚠️ ADB Install failed with code $LASTEXITCODE." -ForegroundColor Red
            Play-AudioAlert -Event "Error"
        }
    } else {
        Play-AudioAlert -Event "Success"
    }
} else {
    Write-Host "⚠️ APK not found in any build directory." -ForegroundColor Red
    if ($Install) {
        Write-Host "Falling back to Cordova run..." -ForegroundColor Yellow
        cordova run android --nobuild --device
        if ($LASTEXITCODE -eq 0) {
            Play-AudioAlert -Event "Success"
        } else {
            Play-AudioAlert -Event "Error"
        }
    }
}

Write-Host "`n✨ Process Complete.`n" -ForegroundColor Green
