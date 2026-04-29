<#
.SYNOPSIS
    Alpha Cordova Production Build Engine v2.8.1
    Features: Zero-Install ADB Tunneling, Keystore Validation, and No-BOM UTF8 Enforcement.
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
    Write-Host ">> Step 2/5: Deep Cleaning..." -ForegroundColor Yellow
    docker compose down -v
    $wipeList = @("platforms", "plugins", "node_modules", "package-lock.json", ".last_sync_hash")
    foreach ($f in $wipeList) {
        if (Test-Path $f) {
            try { Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
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
    
    # 2. Docker Platform Init
    docker compose run --rm $DOCKER_SERVICE sh -c "npm install && cordova platform add android --nosave && chmod -R +x platforms/android/cordova"
    
    Write-Host ">> Step 4/5: Compiling Signed Release $PackageType..." -ForegroundColor Cyan
    $pkgFlag = if ($PackageType -eq "aab") { "-- --packageType=bundle" } else { "-- --packageType=apk" }

    Write-Host "`n☕ Production builds are highly optimized and fully signed." -ForegroundColor Yellow
    Write-Host "   Gradle compile can take 2 to 5 minutes..." -ForegroundColor Cyan
    
    # Execute Build inside container
    docker compose run --rm $DOCKER_SERVICE sh -c "cordova prepare android && cordova build android --release --buildConfig=build.json $pkgFlag"
    
    if ($LASTEXITCODE -eq 0) {
        # --- 5. PUBLISH ---
        Write-Host ">> Step 5/5: Publishing Artifact..." -ForegroundColor Yellow
        if (-not (Test-Path $RELEASE_DIR)) { New-Item -ItemType Directory -Path $RELEASE_DIR | Out-Null }
        
        $src = if ($PackageType -eq "aab") { 
            "platforms/android/app/build/outputs/bundle/release/app-release.aab" 
        } else { 
            "platforms/android/app/build/outputs/apk/release/app-release.apk" 
        }
        $dest = Join-Path $RELEASE_DIR "app-release.$PackageType"

        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dest -Force
            Write-Host "++ RELEASE READY: $dest" -ForegroundColor Green 
            Play-Success
        }

        # Optional Install via Containerized ADB Tunnel
        if ($Install -and $PackageType -eq "apk") {
            Write-Host "📲 Installing Production APK via Container Tunnel..." -ForegroundColor Magenta
            docker compose run --rm $DOCKER_SERVICE adb install -r "release/app-release.apk"
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️ Install failed. Attempting clean reinstall..." -ForegroundColor Yellow
                docker compose run --rm $DOCKER_SERVICE adb uninstall $ID
                docker compose run --rm $DOCKER_SERVICE adb install -r "release/app-release.apk"
            }
            Write-Host "✅ Install complete." -ForegroundColor Green
        }
    } else { throw "Build failed." }

} catch {
    Play-Error
    Write-Host "`n!! PRODUCTION ERROR: $_" -ForegroundColor Red
}