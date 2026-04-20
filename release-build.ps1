<#
.SYNOPSIS
    Alpha Cordova Android Build Engine v2.3.5 (Titanium Edition)
    Features: Byte-level Turbo Sync, Permission Shield, and Automated Changelogs.
#>

param (
    [Switch]$Install,
    [Switch]$Release,
    [Switch]$Quick,
    [string]$ResetVersion,   
    [Switch]$SkipConfirm     
)

# Force UTF8 Encoding for Emoji Support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- HELPER: AUDIO ENGINE ---
function Play-Success { [console]::Beep(800, 200); [console]::Beep(1200, 400) }
function Play-Error   { [console]::Beep(300, 600) }
function Play-Prompt  { [System.Media.SystemSounds]::Asterisk.Play() }
function Play-ChangeDetected { 
    [console]::Beep(1000, 100)
    [console]::Beep(1200, 100)
    [console]::Beep(1400, 250) 
}

# --- 1. CONFIGURATION ---
$DOCKER_SERVICE = "builder" 
$P_ROOT = Get-Location
$C_FILE = Join-Path $P_ROOT "config.xml"
$CHANGELOG_FILE = Join-Path $P_ROOT "CHANGELOG.md"
$SIGNING_FILE = "build.json" 

$AAB_OUT    = Join-Path $P_ROOT "platforms/android/app/build/outputs/bundle/release/app-release.aab"
$APK_OUT    = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/release/app-release.apk"
$DEBUG_OUT  = Join-Path $P_ROOT "platforms/android/app/build/outputs/apk/debug/app-debug.apk"
$FINAL_OUT  = if ($Release) { $AAB_OUT } else { $DEBUG_OUT }

# --- 2. PERMISSION SHIELD & CACHE ALIGNMENT ---
Write-Host "🛡️  Initializing Environment Shield v2.3.5..." -ForegroundColor Cyan

$env:HOME = "/home/cordovauser"
$env:GRADLE_USER_HOME = "/home/cordovauser/.gradle"
$env:NPM_CONFIG_CACHE = "/home/cordovauser/.npm"

$SUPPRESS_FLAGS = "-e HOME=$env:HOME -e GRADLE_USER_HOME=$env:GRADLE_USER_HOME -e NPM_CONFIG_CACHE=$env:NPM_CONFIG_CACHE -e CI=true -e INSIGHT_FORCE_NO_USAGE=true"

# Clean local config noise
$configPath = Join-Path $P_ROOT ".config"
if (Test-Path $configPath) { Remove-Item -Path $configPath -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $configPath -Force | Out-Null

# --- 3. VERSIONING & CHANGELOG LOGIC ---
$isGitRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
$newV = ""
$NeedsCommit = $false

if ($Release -and -not $Quick -and $isGitRepo) {
    if (Test-Path $C_FILE) {
        [xml]$xml = Get-Content $C_FILE
        $root = $xml.DocumentElement
        $oldV = $root.version
        
        if ($ResetVersion) { $newV = $ResetVersion } 
        else {
            $vParts = $oldV.Split('.')
            $vParts[2] = [int]$vParts[2] + 1
            $newV = $vParts -join '.'
        }

        if (-not $SkipConfirm) {
            Play-Prompt
            Write-Host "`n🏷️  Target Version: v$newV" -ForegroundColor Yellow
            $confirmation = Read-Host "👉 Proceed? (Y/N)"
            if ($confirmation -ne "Y") { Write-Host "🛑 Aborted."; exit 0 }
        }

        $vCode = [int]$root.'android-versionCode' + 1
        $root.version = $newV
        $root.'android-versionCode' = "$vCode"
        $xml.Save($C_FILE)
        
        $lastTag = git describe --tags --abbrev=0 2>$null
        $logs = if ($null -eq $lastTag) { git log --pretty=format:"* %s (%h)" -n 10 } else { git log "$($lastTag)..HEAD" --pretty=format:"* %s (%h)" }
        $header = "## [$newV] - $(Get-Date -Format 'yyyy-MM-dd')`n$logs`n"
        if (Test-Path $CHANGELOG_FILE) {
            $oldContent = Get-Content $CHANGELOG_FILE -Raw
            Set-Content $CHANGELOG_FILE -Value ($header + "`n" + $oldContent)
        } else {
            Set-Content $CHANGELOG_FILE -Value ("# Changelog`n`n" + $header)
        }
        $NeedsCommit = $true
    }
}

# --- 4. PLATFORM INITIALIZATION ---
$P_DIR = Join-Path $P_ROOT "platforms"
$ANDROID_DIR = Join-Path $P_DIR "android"

if (-not $Quick) {
    if (Test-Path $P_DIR) { Remove-Item -Path $P_DIR -Recurse -Force -ErrorAction SilentlyContinue }
}

if (-not (Test-Path $ANDROID_DIR)) {
    Write-Host "🏗️  Initializing Android Platform..." -ForegroundColor Yellow
    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova platform add android --nosave"
}

# --- 5. BUILD ENGINE ---
$BuildTimer = [System.Diagnostics.Stopwatch]::StartNew()
$ShouldBuild = $false

if ($Quick) {
    Write-Host "🔍 Analyzing /www (Strict Byte-Level Check)..." -ForegroundColor Gray
    
    # Define strictly what influences the UI/Logic
    $includeList = @("*.html", "*.js", "*.css", "*.json", "*.xml")
    $excludeList = @("version.json", "config.xml", "package.json")

    # Get files with a stable sort order
    $fileList = Get-ChildItem -Path "www" -Recurse -Include $includeList -Exclude $excludeList | 
                Where-Object { $_.FullName -notmatch "\\\." } | 
                Sort-Object FullName
    
    # Use .NET StringBuilder and MD5 to ensure zero PowerShell string formatting interference
    $sb = New-Object System.Text.StringBuilder
    $md5 = [System.Security.Cryptography.MD5]::Create()

    foreach ($file in $fileList) {
        try {
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $hashBytes = $md5.ComputeHash($fileBytes)
            [void]$sb.Append($file.Name)
            [void]$sb.Append([System.BitConverter]::ToString($hashBytes))
        } catch { continue }
    }

    $currentHash = $sb.ToString()
    $hashFile = Join-Path $P_ROOT ".last_sync_hash"
    $storedHash = if (Test-Path $hashFile) { Get-Content $hashFile -Raw -ErrorAction SilentlyContinue } else { "" }
    if ($currentHash -eq $storedHash -and $storedHash -ne "") {
        Play-Prompt
        Write-Host "🟦 No UI/Logic changes detected. Environment stable." -ForegroundColor Cyan
        $choice = Read-Host "👉 Force re-compile anyway? (Y/N)"
        if ($choice -eq "Y") { $ShouldBuild = $true }
    } else {
        [System.IO.File]::WriteAllText($hashFile, $currentHash)
        Play-ChangeDetected
        Write-Host "✨ UI Changes detected!" -ForegroundColor Green
        $ShouldBuild = $true
    }
    
    if ($ShouldBuild) {
        Write-Host "⚡ >>> TURBO SYNC..." -ForegroundColor Magenta
        Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova prepare android"
        
        Write-Host "🔨 Assembling APK via Gradlew..." -ForegroundColor Gray
        Invoke-Expression "docker compose run --rm --workdir /home/cordovauser/app/platforms/android $SUPPRESS_FLAGS $DOCKER_SERVICE ./gradlew assembleDebug"
        if ($LASTEXITCODE -ne 0) { Play-Error; throw "Turbo build failed." }
    } else {
        Write-Host "⏭️  Skipping build. Proceeding to Deployment..." -ForegroundColor Yellow
    }

} elseif ($Release) {
    Write-Host "💎 >>> PRODUCTION RELEASE: v$newV" -ForegroundColor Yellow
    $signingArg = if (Test-Path $SIGNING_FILE) { "--buildConfig=$SIGNING_FILE" } else { "" }

    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --release $signingArg -- --packageType=bundle"
    if ($LASTEXITCODE -ne 0) { Play-Error; throw "Bundle build failed." }
    
    if ($Install) {
        Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --release $signingArg -- --packageType=apk"
        if ($LASTEXITCODE -ne 0) { Play-Error; throw "APK build failed." }
    }
    $ShouldBuild = $true
} else {
    Write-Host "🛠️  >>> DEBUG BUILD" -ForegroundColor Cyan
    Invoke-Expression "docker compose run --rm $SUPPRESS_FLAGS $DOCKER_SERVICE cordova build android --debug --nosearch"
    if ($LASTEXITCODE -ne 0) { Play-Error; throw "Debug build failed." }
    $ShouldBuild = $true
}

$BuildTimer.Stop()
$Elapsed = [Math]::Round($BuildTimer.Elapsed.TotalSeconds, 2)

# --- 6. DEPLOYMENT ---
if ($Install) {
    adb start-server > $null
    $deviceLine = adb devices | Select-String -Pattern "\tdevice$" | Select-Object -First 1
    if ($null -ne $deviceLine) {
        $deviceID = $deviceLine.ToString().Split("`t")[0].Trim()
        $targetFile = if ($Release) { $APK_OUT } else { $DEBUG_OUT }
        Start-Sleep -Seconds 1 
        if (Test-Path $targetFile) {
            Write-Host "📲 Installing to device [$deviceID]..." -ForegroundColor Magenta
            adb -s $deviceID install -r "$targetFile"
        }
    }
}

# --- 7. FINALIZING ---
if ($ShouldBuild) {
    Write-Host "`n🚀 BUILD SUCCESSFUL (Time: $Elapsed seconds)" -ForegroundColor Green
} else {
    Write-Host "`n✅ Ready for Deployment (Saved: $Elapsed seconds)" -ForegroundColor Green
}

if (-not $Quick) {
    if (Test-Path $FINAL_OUT) {
        Play-Success
        if ($NeedsCommit) {
            git add $C_FILE $CHANGELOG_FILE; git commit -m "release v$newV"; git tag "v$newV"
        }
    }
} else {
    Play-Success
    Write-Host "✅ Turbo Sync Complete." -ForegroundColor Green
}