# 🚀 Alpha Cordova Android Automation Suite v2.1.0

A high-performance, Dockerized development pipeline for **Cordova** targeting **Android 15 (API 36 / Baklava)**. This suite provides instant UI syncing, automated versioning, and professional release management via the [alpha-cordova-android-build](https://hub.docker.com/r/remoorejr/alpha-cordova-android-build) Docker image.

## 📂 Project Structure
Place these automation scripts in your **Cordova Project Root**:
```text
My-Cordova-App/
├── config.xml                 # REQUIRED (API 36 settings)
├── www/                       # REQUIRED (Your source code)
├── docker-compose.yml         # Docker orchestration
├── release-build.ps1          # PowerShell Build Engine (The "Brain")
├── Build-And-Install.bat      # Daily Dev: Debug & Turbo Sync
├── Production-Release.bat     # Deployment: AAB, Signing, & Tagging
└── DEVELOPER_GUIDE.md         # Detailed technical documentation
```

## 💎 Key Features in v2.1.0
* **Android 15 (Baklava) Support:** Fully optimized for **API 36** builds.
* **Cross-Platform Compatibility:** Enforced `.gitattributes` ensure scripts work seamlessly across **Windows, WSL, and Linux**.
* **Git-Aware Intelligence:** Automatically handles versioning and tagging if a Git repo is detected; otherwise, it performs a "Production-Lite" build.
* **Turbo Sync:** Update UI/JS changes on physical devices in **<10 seconds** by bypassing the Gradle overhead.
* **Pre-Flight Diagnostics:** Automatically verifies the host environment (JDK 17+) before starting the container.

## 🛠️ Quick Start

1.  **Prepare Your Device:** Enable **Developer Options** and **USB Debugging** on your Android device. Connect it via USB and verify it appears when running `adb devices` on your host.
2.  **Configure Identity:** Update your Git name/email in [docker-compose.yml](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/docker-compose.yml) to ensure release tags are authored correctly.
3.  **Initial Build:** Run `Build-And-Install.bat` and select **Option 1**. This initializes the Android platform, performs a full Gradle build, and installs the debug app to your device.
4.  **Turbo Sync:** After editing files in `www/`, run `Build-And-Install.bat` and select **Option 2** for a near-instant UI update on the device.
5.  **Production:** Run `Production-Release.bat` to generate a signed `.aab`, auto-increment your version, and create a Git tag.

## 📖 Documentation
For a deep dive into advanced configuration, environment variables, and troubleshooting, please refer to the [DEVELOPER_GUIDE.md](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/DEVELOPER_GUIDE.md).

## 🤝 Credits
* **Lead Developer:** [remoorejr](https://github.com/remoorejr)
* **Automation Architecture:** Gemini AI

---
