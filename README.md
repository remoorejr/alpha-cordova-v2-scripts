# 🚀 Alpha Cordova Android Automation Suite v2.2.0

A high-performance, Dockerized development pipeline for **Cordova** targeting **Android 15 (API 36 / Baklava)**. This suite provides instant UI syncing, hybrid release management, and cross-machine permission stability via the [alpha-cordova-android-build](https://hub.docker.com/r/remoorejr/alpha-cordova-android-build) Docker image.

## 📂 Project Structure

Place these automation scripts in your **Cordova Project Root**:

```text
My-Cordova-App/
├── config.xml                 # REQUIRED (API 36 settings)
├── www/                       # REQUIRED (Your source code)
├── build.json                 # NEW: Centralized signing configuration
├── docker-compose.yml         # Docker orchestration & Caching
├── release-build.ps1          # PowerShell Build Engine (The "Brain")
├── Build-And-Install.bat      # Daily Dev: Debug & Turbo Sync
├── Production-Release.bat     # Deployment: AAB, APK, & Manual Versioning
├── Verify-Environment.ps1     # NEW: Host Readiness Diagnostic
└── DEVELOPER_GUIDE.md         # Detailed technical documentation
```

## 💎 Key Features in v2.2.0

  * **Hybrid Release Builds:** Automatically generates both a Store Bundle (`.aab`) and a signed Testing APK (`.apk`) in a single pass during deployment.
  * **Permission Shield:** Resolves `EACCES` and `Permission Denied` errors common in WSL/Docker by redirecting the container `HOME` path and sanitizing host config permissions.
  * **Turbo-Charged Caching:** Restores high-speed Gradle and NPM caching using native **Docker Named Volumes**, bypassing slow Windows/WSL file-system bridges.
  * **Version Control 2.0:** Includes an interactive version preview and a manual `-ResetVersion` override (e.g., forcing `2.2.0`) directly from the batch file.
  * **Cross-Version Compatibility:** Refactored engine to support both **PowerShell 5.1** (Standard Windows) and **PowerShell 7.0+**.

## 🛠️ Quick Start

1.  **Sanity Check:** Run [Verify-Environment.ps1](https://www.google.com/search?q=https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/Verify-Environment.ps1) to ensure your WSL 2, Docker, and JDK 17+ settings are optimized for API 36.
2.  **Configure Signing:** Place your `.keystore` in the root and update [build.json](https://www.google.com/search?q=https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/build.json) with your credentials.
3.  **Initial Build:** Run [Build-And-Install.bat](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/Build-And-Install.bat) and select **Option 1**. This initializes the platform and performs a full Gradle build.
4.  **Turbo Sync:** After editing files in `www/`, run `Build-And-Install.bat` and select **Option 2** for a near-instant UI update on your device.
5.  **Production:** Run [Production-Release.bat](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/Production-Release.bat). Type a specific version (e.g., `2.2.0`) or hit Enter to auto-increment.

## 📖 Documentation

For a deep dive into the Permission Shield, Named Volume configuration, and troubleshooting, please refer to the [DEVELOPER\_GUIDE.md](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/DEVELOPER_GUIDE.md).

## 🤝 Credits

  * **Lead Developer:** [remoorejr](https://github.com/remoorejr)
  * **Automation Architecture:** Gemini AI

-----
