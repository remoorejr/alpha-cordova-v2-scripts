<#
.SYNOPSIS
    Alpha Cordova Production Build Engine v2.8.1
    Features: Zero-Install ADB Tunneling, Keystore Validation, Volume Extraction, and Hybrid Deployment.
#>

param (
    [Switch]$Release,
    [Switch]$Install,
    [Parameter(Mandatory=$true)]
    [ValidateSet("apk", "aab")]
    [string]$PackageType
)

# Force terminal to UTF8 and create the No-BOM encoder
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Utf8NoBom = New-Object System.Text.UTF8Encoding($False)

# --- 1. CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$RELEASE_DIR = Join-Path $P_ROOT "release"

# --- 2. FUNCTIONS ---
function Play-Success { [console]::Beep(800, 200); [console]::Beep(1200, 400) }
function Play-Error   { [console]::Beep(300, 600) }

function Increment-Version {
    Write-Host ">> Step 1/5: Incrementing Version..." -ForegroundColor Cyan
    [xml]$config = Get-Content $C_FILE
    $parts = $config.widget.version -split '\.'
    if ($parts.Count -ge 3) { $parts[2] = [int]$parts[2] + 1; $newV = $parts -join '.' } 
    else { $newV = "$($config.widget.version).1" }
    $config.widget.version = $newV
    
    # Save WITHOUT BOM to ensure Linux/Docker compatibility
    $sw = New-Object System.IO.StreamWriter($C_FILE, $false, $Utf8NoBom)
    $config.Save($sw)
    $sw.Close()
    
    Write-Host "++ New Version: $newV" -ForegroundColor Green
}

function Reset-Environment {
    Write-Host ">> Step 2/5: Deep Cleaning & Purging Volumes..." -ForegroundColor Yellow
    # 1. Kill any background Dev Containers and wipe the high-speed caches
    docker compose down -v | Out-Null
    
    # 2. Use the Docker Janitor to bypass Windows file-locking issues
    $targetDir = $P_ROOT -replace "\\", "/"
    docker run --rm -v "$($P_ROOT):/work" alpine sh -c "rm -rf /work/platforms /work/plugins /work/node_modules /work/package-lock.json /work/.last_sync_hash /work/.turbo_ready"
}

# --- 3. EXECUTION ---
try {
    # PRE-FLIGHT CHECK: Verify Signing Assets
    Write-Host "🔍 Verifying Signing Assets..." -ForegroundColor Cyan
    $keystore = Get-ChildItem -Path $P_ROOT -Filter "*.keystore" -Recurse | Select-Object -First 1
    if ($null -eq $keystore) {
        throw "Missing .keystore file. Production builds require a signing key in the project root."
    }

    Increment-Version
    Reset-Environment
    
    [xml]$xml = Get-Content $C_FILE
    $ID = $xml.widget.id
    
    Write-Host ">> Step 3/5: Bootstrapping Clean Platform (Containerized)..." -ForegroundColor Yellow
    
    # 1. Create package.json (BOM-LESS)
    $manifestObj = [PSCustomObject]@{
        name = "alpha-release"
        version = "1.0.0"
        dependencies = @{ "cordova-android" = "15.0.0" }
    }
    $manifestJson = $manifestObj | ConvertTo-Json
    [System.IO.File]::WriteAllText((Join-Path $P_ROOT "package.json"), $manifestJson, $Utf8NoBom)
    
    # 2. Spin up the Production Build Container
    docker compose up -d $DOCKER_SERVICE | Out-Null
    docker compose exec $DOCKER_SERVICE sh -c "npm install && cordova platform add android --nosave && chmod -R +x platforms/android/cordova"
    
    Write-Host ">> Step 4/5: Compiling Signed Release $PackageType..." -ForegroundColor Cyan
    $pkgFlag = if ($PackageType -eq "aab") { "-- --packageType=bundle" } else { "-- --packageType=apk" }

    Write-Host "`n☕ Production builds are highly optimized and fully signed." -ForegroundColor Yellow
    Write-Host "   Gradle compile can take 2 to 5 minutes..." -ForegroundColor Cyan
    
    # Execute Build inside container
    docker compose exec $DOCKER_SERVICE sh -c "cordova prepare android && cordova build android --release --buildConfig=build.json $pkgFlag"
    
    if ($LASTEXITCODE -eq 0) {
        # --- 5. PUBLISH & EXTRACT ---
        Write-Host ">> Step 5/5: Extracting Artifact..." -ForegroundColor Yellow
        if (-not (Test-Path $RELEASE_DIR)) { New-Item -ItemType Directory -Path $RELEASE_DIR | Out-Null }
        
        $src = if ($PackageType -eq "aab") { 
            "platforms/android/app/build/outputs/bundle/release/app-release.aab" 
        } else { 
            "platforms/android/app/build/outputs/apk/release/app-release.apk" 
        }
        $destName = "app-release.$PackageType"

        # Tunnel into the Named Volume and copy the asset to the Windows-facing release folder
        docker compose exec $DOCKER_SERVICE sh -c "cp $src release/$destName 2>/dev/null || true"
        $hostArtifactPath = Join-Path "release" $destName

        if (Test-Path $hostArtifactPath) {
            Write-Host "++ RELEASE READY: $hostArtifactPath" -ForegroundColor Green 
            Play-Success

            # ------------------------------------------------------------------
            # HYBRID DEPLOYMENT (APK ONLY)
            # ------------------------------------------------------------------
            if ($Install -and $PackageType -eq "apk") {
                Write-Host "`n🚀 Initiating Smart Production Deployment..." -ForegroundColor Yellow
                $deployed = $false
                
                # ROUTE A: LOCAL ADB
                $localAdb = Get-Command adb -ErrorAction SilentlyContinue
                if ($localAdb) {
                    Write-Host "🔍 Local ADB detected. Checking for USB devices..." -ForegroundColor Gray
                    $adbDevices = & adb devices | Select-String -Pattern "\bdevice\b"
                    
                    if ($adbDevices) {
                        Write-Host "🔗 USB Device found! Installing..." -ForegroundColor Magenta
                        & adb install -r -d -t $hostArtifactPath
                        if ($LASTEXITCODE -eq 0) { $deployed = $true; Write-Host "✅ Install complete." -ForegroundColor Green }
                    }
                }
                
                # ROUTE B: WIRELESS ZERO-INSTALL
                if (-not $deployed) {
                    Write-Host "`n📱 [Wireless Deployment] - Zero Install Mode" -ForegroundColor Cyan
                    $deviceIp = Read-Host "Enter Device IP and Port (e.g., 192.168.1.55:12345) or press Enter to skip"
                    
                    if (-not [string]::IsNullOrWhiteSpace($deviceIp)) {
                        Write-Host "🔗 Connecting directly via Wi-Fi..." -ForegroundColor Gray
                        docker compose exec $DOCKER_SERVICE adb connect $deviceIp | Out-Null
                        
                        Write-Host "📲 Installing Release APK..." -ForegroundColor Magenta
                        docker compose exec $DOCKER_SERVICE adb -s $deviceIp install -r -d -t "release/app-release.apk"
                        
                        if ($LASTEXITCODE -eq 0) { Write-Host "✅ Install complete." -ForegroundColor Green } 
                        else { Write-Host "⚠️ Wireless Install failed." -ForegroundColor Red }
                        
                        docker compose exec $DOCKER_SERVICE adb disconnect $deviceIp | Out-Null
                    } else { Write-Host "⏭️ Skipped installation." -ForegroundColor DarkGray }
                }
            }
        } else { Write-Host "❌ Failed to extract artifact from volume." -ForegroundColor Red }
    } else { throw "Build failed." }

} catch {
    Play-Error
    Write-Host "`n!! PRODUCTION ERROR: $_" -ForegroundColor Red
}