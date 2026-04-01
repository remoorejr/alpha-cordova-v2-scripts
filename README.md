# 🚀 Alpha Cordova Android Automation Suite v2.3.0

A high-performance, Dockerized development pipeline for **Cordova** targeting **Android 15 (API 36 / Baklava)**. This suite provides instant UI syncing, hybrid release management, and cross-machine permission stability via the [alpha-cordova-android-build](https://hub.docker.com/r/remoorejr/alpha-cordova-android-build) Docker image.
```text
My-Cordova-App/
├── config.xml                 # REQUIRED (API 36 settings)
├── www/                       # REQUIRED (Your source code)
├── build.json                 # Centralized signing configuration
├── docker-compose.yml         # Docker orchestration & Named Volume Caching
├── release-build.ps1          # v2.3.0 Build Engine (The "Brain")
├── Build-And-Install.bat      # Daily Dev: Debug & Turbo Sync
├── Production-Release.bat     # Deployment: AAB, APK, & Auto-Versioning
├── Verify-Environment.bat     # Quick Sanity Check
└── DEVELOPER_GUIDE.md         # Detailed technical documentation
```

## 💎 Key Features in v2.3.0
* **Master Versioning:** Restored automatic `android-versionCode` bumping and `CHANGELOG.md` generation from Git logs.
* **Turbo-Charged Caching:** Optimized **Docker Named Volumes** ensure UI updates sync in <10 seconds by shadowing the slow Windows filesystem.
* **Permission Shield:** Automated `EACCES` resolution via home-path redirection and `.config` sanitization.
* **Hybrid Deployment:** Generates signed Store Bundles (`.aab`) and testing APKs (`.apk`) in a single pass.

## 🛠️ Quick Start
1.  **Sanity Check:** Run `Verify-Environment.bat` to ensure your WSL 2, Docker, and JDK 17+ settings are optimized for API 36.
2.  **Configure Signing:** Place your `.keystore` in the root and update build.json with your credentials.
3.  **Initial Build:** Run `Build-And-Install.bat` and select `**Option 1**`. This initializes the platform and performs a full Gradle build.
4.  **Turbo Sync:** After editing files in `www/`, run `Build-And-Install.bat` and select **Option 2** for a near-instant UI update on your device.
5.  **Production:** Run `Production-Release.bat`. Type a specific version (e.g., `2.3.0`) or hit Enter to auto-increment.

## 📖 Documentation

For a deep dive into the Permission Shield, Named Volume configuration, and troubleshooting, please refer to the [DEVELOPER\_GUIDE.md](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/DEVELOPER_GUIDE.md).

## 🤝 Credits

  * **Lead Developer:** [remoorejr](https://github.com/remoorejr)
  * **Automation Architecture:** Gemini AI

-----
