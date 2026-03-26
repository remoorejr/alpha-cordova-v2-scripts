# 🚀 Alpha Cordova Android Automation Suite v2.4.1

A high-performance, Dockerized development pipeline for **Cordova** targeting **Android 15 (API 36 / Baklava)**. 

This suite works in tandem with the [remoorejr/alpha-cordova-android-build](https://hub.docker.com/repository/docker/remoorejr/alpha-cordova-android-build) Docker image to provide instant UI syncing, automated versioning, and professional release management.

**Tested with Windows 11 Pro & PowerShell 5.1/7+**

---

## 📂 Required Project Structure
Place these automation scripts in your **Cordova Project Root**:

```yaml
My-Cordova-App/
├── config.xml              # REQUIRED (Project settings & versioning)
├── www/                    # REQUIRED (Your HTML/JS/CSS source)
├── docker-compose.yml      # Docker orchestration
├── release-build.ps1       # The "Brain" (PowerShell Build Engine)
├── Build-And-Install.bat   # Daily Dev: Debug/Turbo Sync
├── Production-Release.bat  # Deployment: AAB/Signing/Tagging
├── release-signing.properties  # (Optional) For automated AAB signing
└── ... 
```

---

## 💎 Key Features
* **Git-Aware Intelligence:** Automatically detects if the project is in a Git repo. If found, it handles versioning and tagging; if not, it performs a "Production-Lite" build without crashing.
* **Pre-Flight Diagnostics:** Automatically checks for **JDK 17+** on the host, as required by the Android 15 (API 36) build tools.
* **Turbo Sync:** Update your app on a physical device in <10 seconds by bypassing Gradle for `www/` changes.
* **Persistent Caching:** Uses Docker Named Volumes to cache Gradle and NPM dependencies, slashing build times.
* **Device Detection:** Smart ADB filtering ensures the script won't hang if your phone is unplugged.

---

## 🛠️ Installation & Setup

### 1. Prerequisites
* **Docker Desktop** installed and running.
* **JDK 17 or 21** installed on the host machine.
* **ADB (Android Debug Bridge)** in your System PATH.
* A physical Android device with **USB Debugging** enabled.

### 2. Configuration
Open `docker-compose.yml` and update your Git identity for the automated tagging system:

```yaml
    environment:
      - GIT_AUTHOR_NAME=Your Name
      - GIT_AUTHOR_EMAIL=your@email.com
```

---

## 🎮 Command Reference

| Script | Mode | Git Required? | Result |
| :--- | :--- | :--- | :--- |
| **`Build-And-Install.bat`** (Opt 1) | **Full Build** | No | Wipes platform, re-inits API 36, installs `.apk`. |
| **`Build-And-Install.bat`** (Opt 2) | **Turbo Sync** | No | Instant UI/JS sync (<10s) to device. |
| **`Production-Release.bat`** | **Release** | **Yes*** | Bumps version, updates Changelog, creates `.aab`. |

> **Note:** If `Production-Release.bat` is run outside of a Git repo, it will still generate a production `.aab` but will skip the version bump and tagging steps.

---

## 🚀 Quick Start Guide

1. **Connect your Android Device** via USB.
2. **Run the Initial Build**:
   Double-click **`Build-And-Install.bat`** and select **Option 1**.
   *This pulls the Docker image, initializes the platform, and deploys the debug app.*
3. **Test "Turbo Sync"**:
   * Change a line in `www/index.html`.
   * Run **`Build-And-Install.bat`** and select **Option 2**.
   * Your app refreshes on the device almost instantly.

---

## 🔐 Signing Your Production Build
To generate a signed `.aab` for the Google Play Store:

1. Rename `release-signing.properties.example` to **`release-signing.properties`**.
2. Update the credentials. Use the container path for your keystore:
   `keyStore=/app/my-release.keystore`
3. Run **`Production-Release.bat`**.

---

## 🏁 Pre-Flight Release Checklist
Before running **`Production-Release.bat`**, verify these settings in your `config.xml`:

1.  **Version Consistency**:
    * [ ] Is `version="x.y.z"` higher than the current version in the Play Store?
    * [ ] Is `android-versionCode` an integer higher than the last upload? (The script auto-increments this, but it's good to double-check).
2.  **API Target (Baklava/API 36)**:
    * [ ] `<preference name="android-targetSdkVersion" value="36" />` is set.
    * [ ] `<preference name="android-compileSdkVersion" value="36" />` is set (Required for Java 17+ compatibility).
3.  **App Identity**:
    * [ ] Does the `<widget id="com.your.id">` match your Play Store application ID?
    * [ ] Is the `<name>` tag exactly how you want it to appear on the user's home screen?
4.  **Signing Assets**:
    * [ ] Is your `.keystore` file present in the root directory?
    * [ ] Does `release-signing.properties` contain the correct `keyAlias` and passwords?
5.  **Git Status**:
    * [ ] Have you committed all "manual" code changes? (The script only auto-commits the version bump and changelog).

---

### 📦 After the Build
Once the script finishes:
1.  Locate the `.aab` file in `platforms/android/app/build/outputs/bundle/release/`.
2.  Upload this file to the **Internal Testing** or **Production** track in the [Google Play Console](https://play.google.com/apps/publish).
3.  Check the **Changelog.md** to ensure your recent Git commits were captured correctly in the "Logs" section.

---

## ❓ Troubleshooting
* **'Install' is not recognized:** This was a legacy CMD bug fixed in v2.4.0+. Ensure you are using the latest `.bat` files provided in the suite.
* **Missing Artifact:** If the build finishes but the file isn't found, ensure your `config.xml` has the correct `<widget id="...">` matching your expected output.
* **JDK Warning:** If you see a JDK warning, the build might still work inside Docker, but you should upgrade your host JDK to 17+ for optimal compatibility with API 36 tools.

---

### 🤝 Credits
* **Lead Developer:** [remoorejr](https://github.com/remoorejr)
* **Automation Architecture:** [Gemini AI](https://gemini.google.com)

---
