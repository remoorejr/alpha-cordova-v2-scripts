<#
.SYNOPSIS
    Alpha Cordova Android Build Engine v2.7.8 [DEVELOPMENT]
    Fixes: High-visibility color scheme (Secondary text -> Yellow).
#>

param (
    [Switch]$Install,
    [Switch]$Quick,
    [Switch]$BatchMode
)

# Force terminal to UTF8 and create the No-BOM encoder
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Utf8NoBom = New-Object System.Text.UTF8Encoding($False)

# --- 1. CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$C_REAL = "$C_FILE.real"
$HASH_FILE = Join-Path $P_ROOT ".last_sync_hash"
$DEBUG_DIR = Join-Path $P_ROOT "debug"
$DEBUG_OUT = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk"
$DEBUG_PUBLISH = Join-Path $DEBUG_DIR "app-debug.apk"

# INJECT GRADLE OPTS AS ENV VARS
$D_OPTS = "-e CI=true -e GRADLE_OPTS='-Dorg.gradle.daemon=true -Dorg.gradle.parallel=true -Dorg.gradle.jvmargs=-Xmx2048m'"

# --- 2. AUDIO & FEEDBACK FUNCTIONS ---
function Play-Success { [console]::Beep(800, 200); [console]::Beep(1200, 400) }
function Play-Error   { [console]::Beep(300, 600) }
function Play-Chirp   { [console]::Beep(1000, 100) }
function Play-Wait    { [console]::Beep(600, 100); [console]::Beep(600, 100) }

function Get-SourceHash {
    if (-not (Test-Path "www")) { return "none" }
    $files = Get-ChildItem -Path "www" -Recurse -File | Sort-Object FullName
    if (-not $files) { return "empty" }
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashString = New-Object System.Text.StringBuilder
    foreach ($file in $files) {
        try {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            [void]$hashString.Append([System.BitConverter]::ToString($md5.ComputeHash($bytes)))
        } catch { continue }
    }
    return $hashString.ToString()
}

function Reset-Environment {
    Write-Host ">> Tearing down Docker and purging volumes..." -ForegroundColor Yellow
    docker compose down -v
    $wipeList = @("platforms", "plugins", "node_modules", "package-lock.json", $HASH_FILE)
    foreach ($f in $wipeList) {
        if (Test-Path $f) {
            try { Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

function Bridge-Artifact {
    Write-Host ">> Bridging APK to Windows..." -ForegroundColor Yellow
    $tmpName = "bridge-extractor-$((Get-Random))"
    docker compose run -d --name $tmpName --no-deps $DOCKER_SERVICE tail -f /dev/null | Out-Null
    try {
        $localDir = Split-Path $DEBUG_OUT -Parent
        if (-not (Test-Path $localDir)) { New-Item -ItemType Directory -Path $localDir -Force | Out-Null }
        docker cp "${tmpName}:/home/cordovauser/app/platforms/android/app/build/outputs/apk/debug/app-debug.apk" "$DEBUG_OUT"
    } finally { docker rm -f $tmpName | Out-Null }
}

# --- 3. MAIN EXECUTION LOGIC ---
function Execute-Build {
    $BuildTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $SkipCompile = $false

    try {
        if (-not $Quick) {
            # --- FULL INITIALIZATION ---
            if (-not (Test-Path $C_FILE) -and (Test-Path $C_REAL)) { Rename-Item $C_REAL (Split-Path $C_FILE -Leaf) }
            [xml]$xml = Get-Content $C_FILE
            $ID = $xml.widget.id; $NAME = $xml.widget.name
            
            Reset-Environment
            
            $manifest = '{"name":"alpha-app","version":"1.0.0","dependencies":{"cordova-android":"15.0.0"}}'
            [System.IO.File]::WriteAllText((Join-Path $P_ROOT "package.json"), $manifest, $Utf8NoBom)
            
            Write-Host ">> Bootstrapping Platform..." -ForegroundColor Yellow
            Rename-Item $C_FILE (Split-Path $C_REAL -Leaf)
            $skelTemplate = '<?xml version="1.0" encoding="utf-8"?><widget id="{0}" version="1.0.0" xmlns="http://www.w3.org/ns/widgets"><name>{1}</name></widget>'
            $skeleton = $skelTemplate -f $ID, $NAME
            [System.IO.File]::WriteAllText($C_FILE, $skeleton, $Utf8NoBom)

            docker compose run --rm -u root $D_OPTS $DOCKER_SERVICE sh -c "npm install && cordova platform add android --nosave && chmod -R +x platforms/android/cordova"
            
            Remove-Item $C_FILE; Rename-Item $C_REAL (Split-Path $C_FILE -Leaf)
            docker compose run --rm -u root $D_OPTS $DOCKER_SERVICE sh -c "cordova prepare android && chown -R cordovauser:cordovauser ."
        } else {
            # --- TURBO CHANGE DETECTION ---
            Write-Host "🔍 Analyzing /www..." -ForegroundColor Yellow
            $curr = Get-SourceHash
            $prev = Get-Content $HASH_FILE -ErrorAction SilentlyContinue
            
            if ($curr -eq $prev -and $null -ne $prev) {
                Write-Host "✅ Code is up to date." -ForegroundColor Green
                if ($Install) {
                    Write-Host ">> Skipping build, proceeding to installation..." -ForegroundColor Yellow
                    $SkipCompile = $true
                } elseif ($BatchMode) {
                    Write-Host ">> Nothing to do. Skipping build." -ForegroundColor Yellow
                    return
                } else {
                    $confirm = Read-Host "👉 Force sync anyway? (y/N)"
                    if ($confirm.Trim().ToLower() -ne "y") { return }
                }
            } else {
                Play-Chirp
                Write-Host "✨ Changes detected in /www! Syncing files..." -ForegroundColor Yellow
            }
        }

        # --- COMPILATION (Only if not skipped) ---
        if (-not $SkipCompile) {
            Write-Host "`n☕ Starting Gradle Daemon..." -ForegroundColor Cyan
            Write-Host ">> (Initialization can take 10-20s on some machines. Hang tight!)" -ForegroundColor Yellow
            Play-Wait

            if ($Quick) {
                $turboCmd = "cordova prepare android && cd platforms/android && ./gradlew assembleDebug"
                docker compose run --rm $D_OPTS $DOCKER_SERVICE sh -c "$turboCmd"
            } else {
                docker compose run --rm $D_OPTS $DOCKER_SERVICE cordova build android --debug
            }
            
            if ($LASTEXITCODE -ne 0) { throw "Gradle build failed." }
            
            Get-SourceHash | Out-File $HASH_FILE -Encoding ASCII
            Bridge-Artifact
        }

        # --- POST-BUILD / INSTALL PHASE ---
        $FileExistsOnHost = Test-Path $DEBUG_OUT
        $FileExistsInVolume = (docker compose run --rm --no-deps $DOCKER_SERVICE sh -c "test -f /home/cordovauser/app/platforms/android/app/build/outputs/apk/debug/app-debug.apk && echo 'true'") -eq 'true'

        if ($FileExistsOnHost -or $FileExistsInVolume) {
            
            if ($SkipCompile -or (-not $FileExistsOnHost)) { Bridge-Artifact }

            if (-not (Test-Path $DEBUG_DIR)) { New-Item -ItemType Directory -Path $DEBUG_DIR | Out-Null }
            Copy-Item -Path $DEBUG_OUT -Destination $DEBUG_PUBLISH -Force
            Write-Host "📦 Debug APK Published to: \debug\app-debug.apk" -ForegroundColor Green

            if ($Install) {
                $device = adb devices | Select-String -Pattern "\tdevice$" | Select-Object -First 1
                if ($null -ne $device) { 
                    Write-Host "📲 Installing to device..." -ForegroundColor Magenta
                    $log = adb install -r "$DEBUG_OUT" 2>&1
                    if ($log -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE") {
                        Write-Host "⚠️ Signing mismatch. Reinstalling..." -ForegroundColor Yellow
                        [xml]$xml = Get-Content $C_FILE
                        adb uninstall $xml.widget.id | Out-Null
                        adb install -r "$DEBUG_OUT" | Out-Null
                    }
                    Write-Host "✅ Install complete." -ForegroundColor Green
                } else {
                    Write-Host "⚠️ No device found for installation." -ForegroundColor Yellow
                }
            }
            
            Play-Success
            Write-Host "`n🚀 DONE ($([Math]::Round($BuildTimer.Elapsed.TotalSeconds, 2))s)" -ForegroundColor Green
        } else {
            throw "Debug APK not found. Please run a Full Reset."
        }

    } catch {
        Play-Error; Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
        if (-not (Test-Path $C_FILE) -and (Test-Path $C_REAL)) { Rename-Item $C_REAL (Split-Path $C_FILE -Leaf) }
        return
    }
}

# --- 4. ENTRY POINT ---
if ($BatchMode) { 
    Execute-Build
} else {
    while ($true) {
        Clear-Host
        Write-Host "--- Alpha Engine v2.7.8 [DEV] ---"
        Write-Host "[1] Full Build"
        Write-Host "[2] Turbo Sync"
        Write-Host "[3] Exit"
        $choice = (Read-Host "Selection").Trim()
        if ($choice -eq "1") { $Quick = $false; Execute-Build }
        elseif ($choice -eq "2") { $Quick = $true; Execute-Build }
        elseif ($choice -eq "3") { return }
        Write-Host "`nPress any key..."
        $null = [Console]::ReadKey()
    }
}