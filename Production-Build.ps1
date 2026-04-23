<#
.SYNOPSIS
    Alpha Cordova Production Build Engine v2.7.8
    Features: AAB/APK Support, Auto-Versioning, and High-Visibility (Yellow) UI.
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
$C_REAL = "$C_FILE.real"
$RELEASE_DIR = Join-Path $P_ROOT "release"

# INJECT GRADLE OPTS AS ENV VARS
$D_OPTS = "-e CI=true -e GRADLE_OPTS='-Dorg.gradle.daemon=true -Dorg.gradle.parallel=true -Dorg.gradle.jvmargs=-Xmx2048m'"

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
    $config.Save($C_FILE)
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
    Increment-Version
    Reset-Environment
    
    [xml]$xml = Get-Content $C_FILE
    $ID = $xml.widget.id
    $NAME = $xml.widget.name
    
    Write-Host ">> Step 3/5: Bootstrapping Clean Platform..." -ForegroundColor Yellow
    
    # 1. Create package.json (BOM-LESS)
    $manifestObj = [PSCustomObject]@{
        name = "alpha-release"
        version = "1.0.0"
        dependencies = @{ "cordova-android" = "15.0.0" }
    }
    $manifestJson = $manifestObj | ConvertTo-Json
    [System.IO.File]::WriteAllText((Join-Path $P_ROOT "package.json"), $manifestJson, $Utf8NoBom)
    
    # 2. Create Skeleton config.xml (BOM-LESS)
    Rename-Item $C_FILE (Split-Path $C_REAL -Leaf)
    $skelTemplate = '<?xml version="1.0" encoding="utf-8"?><widget id="{0}" version="1.0.0" xmlns="http://www.w3.org/ns/widgets"><name>{1}</name></widget>'
    $skeleton = $skelTemplate -f $ID, $NAME
    [System.IO.File]::WriteAllText($C_FILE, $skeleton, $Utf8NoBom)
    
    # 3. Docker Platform Init
    $initCmd = "npm install && cordova platform add android --nosave && chmod -R +x platforms/android/cordova"
    docker compose run --rm -u root $D_OPTS $DOCKER_SERVICE sh -c "$initCmd"
    
    # 4. Restore Real Config
    if (Test-Path $C_FILE) { Remove-Item $C_FILE }
    Rename-Item $C_REAL (Split-Path $C_FILE -Leaf)

    Write-Host ">> Step 4/5: Compiling Signed Release $PackageType..." -ForegroundColor Cyan
    $pkgFlag = if ($PackageType -eq "aab") { "-- --packageType=bundle" } else { "-- --packageType=apk" }

    Write-Host "`n☕ Grab a coffee! Production builds are highly optimized and fully signed." -ForegroundColor Yellow
    Write-Host "   Please sit tight, as the Windows/WSL Gradle compile can take 2 to 5 minutes..." -ForegroundColor Cyan
    
    # Execute Build
    $buildCmd = "cordova prepare android && cordova build android --release --buildConfig=build.json $pkgFlag"
    docker compose run --rm $D_OPTS $DOCKER_SERVICE sh -c "$buildCmd"
    
    if ($LASTEXITCODE -eq 0) {
        # --- 5. PUBLISH ---
        Write-Host ">> Step 5/5: Publishing Artifact..." -ForegroundColor Yellow
        if (-not (Test-Path $RELEASE_DIR)) { New-Item -ItemType Directory -Path $RELEASE_DIR | Out-Null }
        
        $src = if ($PackageType -eq "aab") { 
            "/home/cordovauser/app/platforms/android/app/build/outputs/bundle/release/app-release.aab" 
        } else { 
            "/home/cordovauser/app/platforms/android/app/build/outputs/apk/release/app-release.apk" 
        }
        $dest = Join-Path $RELEASE_DIR "app-release.$PackageType"

        $tmpName = "bridge-extractor-$((Get-Random))"
        docker compose run -d --name $tmpName --no-deps $DOCKER_SERVICE tail -f /dev/null | Out-Null
        try {
            docker cp "${tmpName}:$src" "$dest"
            if (Test-Path $dest) { 
                Write-Host "++ RELEASE READY: $dest" -ForegroundColor Green 
                Play-Success
            }
        } finally {
            docker rm -f $tmpName | Out-Null
        }

        # Optional Install
        if ($Install -and $PackageType -eq "apk") {
            $device = adb devices | Select-String -Pattern "\tdevice$" | Select-Object -First 1
            if ($null -ne $device) {
                Write-Host "📲 Installing Production APK..." -ForegroundColor Magenta
                $log = adb install -r "$dest" 2>&1
                if ($log -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
                    Write-Host "⚠️ Signing mismatch. Reinstalling..." -ForegroundColor Yellow
                    adb uninstall $ID | Out-Null
                    adb install -r "$dest" | Out-Null
                }
                Write-Host "✅ Install complete." -ForegroundColor Green
            }
        }
    } else { throw "Build failed." }

} catch {
    Play-Error
    Write-Host "`n!! PRODUCTION ERROR: $_" -ForegroundColor Red
    if (-not (Test-Path $C_FILE) -and (Test-Path $C_REAL)) { 
        if (Test-Path $C_FILE) { Remove-Item $C_FILE -Force }
        Rename-Item $C_REAL (Split-Path $C_FILE -Leaf) 
    }
}