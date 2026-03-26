# 🚀 Alpha Cordova Android Automation Suite v2.0

A high-performance, Dockerized development pipeline for **Cordova** targeting **Android 15 (API 36)**. 

This suite works in tandem with the [remoorejr/alpha-cordova-android-build](https://hub.docker.com/repository/docker/remoorejr/alpha-cordova-android-build) Docker image to provide instant UI syncing, automated versioning, and professional release management.

Tested with Windows 11 Pro

---

## 📂 Required Project Structure
The automation scripts must be placed in your **Cordova Project Root**. The container expects to find your configuration and web assets at the top level.

```yaml
My-Cordova-App/
├── config.xml              # REQUIRED (Project settings & versioning)
├── www/                    # REQUIRED (Your HTML/JS/CSS source)
├── docker-compose.yml      # (From this suite)
├── release-build.ps1       # (From this suite)
├── .gitignore              # (From this suite)
├── release-signing.properties.example
└── ... (all .bat files)
```

---

## 💎 Key Features
* **Turbo Sync:** Update your app on a physical device in <10 seconds by bypassing Gradle for `www/` changes.
* **Persistent Caching:** Uses Docker Named Volumes to cache Gradle and NPM dependencies, slashing build times.
* **API 36 Ready:** Pre-configured with Android 15 SDK, Node.js 22, and Gradle 8.12.
* **Auto-Versioning:** Automatically increments `config.xml` versions and `android-versionCode`.
* **Smart Changelogs & Tagging:** Generates a `CHANGELOG.md` and creates Git tags (e.g., `v2.0.1`) for every release.

---

## 🛠️ Installation & Setup

### 1. Prerequisites
* **PowerShell** installed.
* **Docker Desktop** installed and running.
* **ADB (Android Debug Bridge)** installed on your host machine and in your System PATH.
* A physical Android device with **USB Debugging** enabled.

### 2. Configuration
Open the included `docker-compose.yml` and update your Git identity. This is required for the automated tagging system to function inside the container:

```yaml
    environment:
      - GIT_AUTHOR_NAME=Your Name
      - GIT_AUTHOR_EMAIL=your@email.com
      - GIT_COMMITTER_NAME=Your Name
      - GIT_COMMITTER_EMAIL=your@email.com
```

### 3. Initialization
Connect your device and run **`Build-And-Install.bat`**. This will pull the v2.0 image, initialize the Android 15 platform, and deploy a debug build to your phone.

---

## 🎮 Command Reference

| Script | Action | Version Bump? | Use Case |
| :--- | :--- | :--- | :--- |
| **`Quick-Update.bat`** | Turbo Sync | No | Rapid UI/JS/CSS iteration (10s sync). |
| **`Build-Debug-Only.bat`** | Build `.apk` | No | Generating a test file for QA. |
| **`Build-And-Install.bat`** | Full Install | **Yes** | Testing native plugins or new releases. |
| **`Build-Production.bat`** | Build `.aab` | **Yes** | **Final Play Store submission.** |

---

## 🚀 Quick Start Guide (Testing the Template)

To verify your environment is set up correctly, follow these steps to run the included "Hello World" app:

1. **Connect your Android Device** via USB and ensure "USB Debugging" is enabled.
2. **Open a Terminal** in the project root folder.
3. **Run the Initial Build**:
   ```batch
   .\Build-And-Install.bat
   ```
   *This will pull the Docker image, initialize the Android platform, and install the app on your device.*
4. **Verify the App**: 
   * On your phone, the app should open with a dark background.
   * The status should change from **"Connecting..." (Blinking Yellow)** to **"Device is Ready" (Solid Green)**. This confirms the Cordova bridge is active.
5. **Test "Turbo Sync"**:
   * Open `www/index.html` in your editor.
   * Change `<h1>🚀 Alpha Cordova</h1>` to `<h1>🔥 It Works!</h1>`.
   * Run the sync script:
     ```batch
     .\Quick-Update.bat
     ```
   * Your app should refresh on the device in ~10 seconds with the new text!

---

## 🔐 Signing Your Production Build
To generate a signed `.aab` for the Google Play Store:

1. Locate **`release-signing.properties.example`** in the project root and rename it to **`release-signing.properties`**.
2. Update the values with your keystore path and passwords.
   > **Note:** The `keyStore` path must be relative to the **Docker container's internal filesystem**. If your keystore is in your project root, use: `keyStore=/app/my-release.keystore`
3. Place your `.keystore` file in the project root.
4. Run **`Build-Production.bat`**.

---

## ❓ Troubleshooting
* **ADB Connection:** If the container cannot find your phone, ensure your host ADB server is running: `adb devices`.
* **Permissions:** If you encounter "Permission Denied" on Linux/WSL2, ensure your user has a UID/GID of 1000 (default in `docker-compose.yml`).
* **Clean Build:** If the environment becomes unstable, delete the `platforms/` folder and run `Build-And-Install.bat` again.

---
---
### 🤝 Credits
* **Lead Developer:** [remoorejr](https://github.com/remoorejr)
* **Architecture & Automation Assistant:** [Gemini AI](https://gemini.google.com)

