<#
.SYNOPSIS
    Alpha Cordova Android Build Engine v2.5.8
    Features: Command-Prompt Return, Persistent Signing, and Change Intelligence.
#>

param (
    [Switch]$Install,
    [Switch]$Quick,
    [Switch]$BatchMode 
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$C_REAL = "$C_FILE.real"
$HASH_FILE = Join-Path $P_ROOT ".last_sync_hash"
$DEBUG_OUT = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk"
$SUPPRESS_FLAGS = "-e CI=true -e INSIGHT_FORCE_NO_USAGE=true"

# --- ENGINE FUNCTIONS ---
function Play-Success { [console]::Beep(800, 200); [console]::Beep(1200, 400) }
function Play-Error   { [console]::Beep(300, 600) }

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
    Write-Host "🗑️  Tearing down Docker and purging files..." -ForegroundColor Gray
    docker compose down -v
    $wipeList = @("platforms", "plugins", "node_modules", "package-lock.json", $HASH_FILE)
    foreach ($f in $wipeList) {
        if (Test-Path $f) {
            for ($i=1; $i -le 10; $i++) {
                try { Remove-Item -Path $f -Recurse -Force -ErrorAction Stop; break }
                catch { Start-Sleep -Seconds 1 }
            }
        }
    }
}

function Bridge-Artifact {
    Write-Host "🌉 Bridging APK to Windows..." -ForegroundColor Gray
    $tmpName = "bridge-extractor-$((Get-Random))"
    docker compose run -d --name $tmpName --no-deps $DOCKER_SERVICE tail -f /dev/null | Out-Null
    try {
        $localDir = Split-Path $DEBUG_OUT -Parent
        if (-not (Test-Path $localDir)) { New-Item -ItemType Directory -Path $localDir -Force | Out-Null }
        docker cp "${tmpName}:/home/cordovauser/app/platforms/android/app/build/outputs/apk/debug/app-debug.apk" "$DEBUG_OUT"
    } finally { docker rm -f $tmpName | Out-Null }
}

function Execute-Build {
    $BuildTimer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if (-not $Quick) {
            if (-not (Test-Path $C_FILE) -and (Test-Path $C_REAL)) { Rename-Item $C_REAL (Split-Path $C_FILE -Leaf) }
            [xml]$xml = Get-Content $C_FILE
            $ID = $xml.widget.id; $NAME = $xml.widget.name
            Reset-Environment
            $manifest = @'
{ "name": "alpha-app", "version": "1.0.0", "dependencies": { "cordova-android": "15.0.0" } }
'@
            [System.IO.File]::WriteAllText((Join-Path $P_ROOT "package.json"), $manifest, (New-Object System.Text.UTF8Encoding($False)))
            Write-Host "🏗️  Bootstrapping Platform..." -ForegroundColor Yellow
            Rename-Item $C_FILE (Split-Path $C_REAL -Leaf)
            $skeleton = "<?xml version='1.0' encoding='utf-8'?><widget id='$ID' version='1.0.0' xmlns='http://www.w3.org/ns/widgets'><name>$NAME</name></widget>"
            Set-Content $C_FILE -Value $skeleton -Encoding UTF8
            if (-not (Test-Path "www")) { New-Item -ItemType Directory -Path "www" | Out-Null; Set-Content "www/index.html" -Value "<html></html>" }
            Invoke-Expression "docker compose run --rm -u root $SUPPRESS_FLAGS $DOCKER_SERVICE sh -c 'npm install && cordova platform add android --nosave && chmod -R +x platforms/android/cordova'"
            Remove-Item $C_FILE; Rename-Item $C_REAL (Split-Path $C_FILE -Leaf)
            Invoke-Expression "docker compose run --rm -u root $SUPPRESS_FLAGS $DOCKER_SERVICE sh -c 'cordova prepare android && chown -R cordovauser:cordovauser .'"
        } else {
            Write-Host "🔍 Analyzing /www source files..." -ForegroundColor Gray
            $curr = Get-SourceHash
            $prev = Get-Content $HASH_FILE -ErrorAction SilentlyContinue
            if ($curr -eq $prev -and $null -ne $prev) {
                Write-Host "✅ Code is up to date." -ForegroundColor Green
                $confirm = Read-Host "👉 Force sync anyway? (y/N)"
                if ($confirm.Trim().ToLower() -ne "y") { return }
            }
        }

        Write-Host "🔨 Compiling Android Project..." -ForegroundColor Cyan
        if ($Quick) {
            Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova prepare android"
            Invoke-Expression "docker compose run --rm --workdir /home/cordovauser/app/platforms/android $SUPPRESS_FLAGS $DOCKER_SERVICE ./gradlew assembleDebug"
        } else {
            Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --debug"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Bridge-Artifact
            Get-SourceHash | Out-File $HASH_FILE -Encoding ASCII
            if (Test-Path $DEBUG_OUT) {
                Play-Success
                Write-Host "`n🚀 SUCCESS ($([Math]::Round($BuildTimer.Elapsed.TotalSeconds, 2))s)" -ForegroundColor Green
                $device = adb devices | Select-String -Pattern "\tdevice$" | Select-Object -First 1
                if ($null -ne $device) { 
                    Write-Host "📲 Installing..." -ForegroundColor Magenta
                    $log = adb install -r "$DEBUG_OUT" 2>&1
                    if ($log -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE" -or $log -match "signatures do not match") {
                        Write-Host "⚠️  Signing mismatch. Performing reinstall..." -ForegroundColor Yellow
                        [xml]$xml = Get-Content $C_FILE
                        adb uninstall $xml.widget.id | Out-Null
                        adb install -r "$DEBUG_OUT" | Out-Null
                    }
                }
            }
        } else { throw "Gradle build failed." }
    } catch {
        Play-Error; Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
        if (-not (Test-Path $C_FILE) -and (Test-Path $C_REAL)) { Rename-Item $C_REAL (Split-Path $C_FILE -Leaf) }
        return
    }
}

# --- ENTRY POINT ---
if ($BatchMode) {
    Execute-Build
    return
} else {
    while ($true) {
        Clear-Host
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "📱 CORDOVA Android: Debug Build Tool (Interactive)" -ForegroundColor Cyan
        Write-Host "===================================================" -ForegroundColor Cyan
        Write-Host "[1] Full Build"
        Write-Host "[2] Turbo Sync"
        Write-Host "[3] Exit"
        $choice = (Read-Host "Selection").Trim()
        if ($choice -eq "1") { $Quick = $false; Execute-Build }
        elseif ($choice -eq "2") { $Quick = $true; Execute-Build }
        elseif ($choice -eq "3") { return } # Breaks the loop and returns to shell
        Write-Host "`nPress any key to return to menu..."
        $null = [Console]::ReadKey()
    }
}