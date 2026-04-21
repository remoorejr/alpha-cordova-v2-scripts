<#
.SYNOPSIS
    Alpha Cordova Production Build Engine v2.6.0
    Features: AAB/APK Support, Auto-Versioning, and Signed Publishing.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("apk", "aab")]
    [string]$PackageType
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- 1. CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$C_REAL = "$C_FILE.real"
$RELEASE_DIR = Join-Path $P_ROOT "release"
$SUPPRESS_FLAGS = "-e CI=true -e INSIGHT_FORCE_NO_USAGE=true"

function Play-Success { [console]::Beep(800, 200); [console]::Beep(1200, 400) }
function Play-Error   { [console]::Beep(300, 600) }

# --- 2. LOGIC ---
function Increment-Version {
    Write-Host "🔢 Step 1/6: Incrementing Version..." -ForegroundColor Cyan
    [xml]$config = Get-Content $C_FILE
    $parts = $config.widget.version -split '\.'
    if ($parts.Count -ge 3) { $parts[2] = [int]$parts[2] + 1; $newV = $parts -join '.' } 
    else { $newV = "$($config.widget.version).1" }
    $config.widget.version = $newV
    $config.Save($C_FILE)
    Write-Host "✅ New Version: $newV" -ForegroundColor Green
}

function Reset-Environment {
    Write-Host "🗑️  Step 2/6: Deep Cleaning..." -ForegroundColor Gray
    Invoke-Expression "docker compose down -v"
    $wipeList = @("platforms", "plugins", "node_modules", "package-lock.json", ".last_sync_hash")
    foreach ($f in $wipeList) { if (Test-Path $f) { Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Publish-Artifact {
    Write-Host "🌉 Step 6/6: Bridging Signed $PackageType to \release folder..." -ForegroundColor Gray
    if (-not (Test-Path $RELEASE_DIR)) { New-Item -ItemType Directory -Path $RELEASE_DIR | Out-Null }
    
    # Logic for different internal container paths
    if ($PackageType -eq "aab") {
        $src = "/home/cordovauser/app/platforms/android/app/build/outputs/bundle/release/app-release.aab"
        $dest = Join-Path $RELEASE_DIR "app-release.aab"
    } else {
        $src = "/home/cordovauser/app/platforms/android/app/build/outputs/apk/release/app-release.apk"
        $dest = Join-Path $RELEASE_DIR "app-release.apk"
    }

    $tmpName = "bridge-extractor-$((Get-Random))"
    docker compose run -d --name $tmpName --no-deps $DOCKER_SERVICE tail -f /dev/null | Out-Null
    try {
        docker cp "${tmpName}:$src" "$dest"
        if (Test-Path $dest) { Write-Host "📦 RELEASE READY: $dest" -ForegroundColor Green }
    } finally { docker rm -f $tmpName | Out-Null }
}

# --- 3. EXECUTION ---
try {
    Increment-Version
    Reset-Environment
    
    [xml]$xml = Get-Content $C_FILE
    $ID = $xml.widget.id; $NAME = $xml.widget.name
    
    Write-Host "🏗️  Step 3/6: Bootstrapping..." -ForegroundColor Yellow
    $manifest = '{"name":"alpha-release","version":"1.0.0","dependencies":{"cordova-android":"15.0.0"}}'
    [System.IO.File]::WriteAllText((Join-Path $P_ROOT "package.json"), $manifest, (New-Object System.Text.UTF8Encoding($False)))
    Rename-Item $C_FILE (Split-Path $C_REAL -Leaf)
    Set-Content $C_FILE -Value "<?xml version='1.0' encoding='utf-8'?><widget id='$ID' version='1.0.0' xmlns='http://www.w3.org/ns/widgets'><name>$NAME</name></widget>" -Encoding UTF8
    
    Invoke-Expression "docker compose run --rm -u root $SUPPRESS_FLAGS $DOCKER_SERVICE sh -c 'npm install && cordova platform add android --nosave && chmod -R +x platforms/android/cordova'"
    
    Write-Host "🔌 Step 4/6: Plugins..." -ForegroundColor Gray
    Remove-Item $C_FILE; Rename-Item $C_REAL (Split-Path $C_FILE -Leaf)
    Invoke-Expression "docker compose run --rm -u root $SUPPRESS_FLAGS $DOCKER_SERVICE sh -c 'cordova prepare android && chown -R cordovauser:cordovauser .'"

    Write-Host "🔨 Step 5/6: Compiling Signed $PackageType..." -ForegroundColor Cyan
    # Target flag logic for AAB
    $targetFlag = if ($PackageType -eq "aab") { "-- --packageType=bundle" } else { "" }
    
    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --release --buildConfig=build.json $targetFlag"
    
    if ($LASTEXITCODE -eq 0) {
        Publish-Artifact
        Play-Success
    } else { throw "Build failed." }
} catch {
    Play-Error; Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
    if (-not (Test-Path $C_FILE) -and (Test-Path $C_REAL)) { Rename-Item $C_REAL (Split-Path $C_FILE -Leaf) }
}