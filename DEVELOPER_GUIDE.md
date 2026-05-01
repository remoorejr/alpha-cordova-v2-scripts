## 🏗️ Architecture Overview (v2.8.2)
This project utilizes a **Zero-Install, Persistent Docker Pipeline**. By wrapping the Android SDK, Gradle, and Cordova inside a Docker container, we eliminate "it works on my machine" issues caused by local environment drift. You do not need to install the Android SDK, Java, Gradle, or ADB on your local Windows machine.

### The Background Dev Container
To achieve lightning-fast build times, the pipeline uses a Persistent Dev Container. When you start a build, Docker boots a headless Linux environment (`alpha-cordova-dev`) that stays awake in the background (`docker compose up -d`). This keeps the Gradle Daemon "warm" in memory and caches the massive Android SDKs on a high-speed internal volume, dropping sequential build times from minutes down to seconds.

### The "Brain": `release-build.ps1` & `production-build.ps1`
The PowerShell engine handles the orchestration between your Windows host and the Linux container:
1.  **Asset Triage:** Automatically detects and sanitizes raw Alpha Anywhere exports.
2.  **Turbo Execution:** Bypasses standard wrappers to execute direct, highly optimized native Gradle builds inside the awake container.
3.  **Deployment & Export:** Interfaces with smart deployment routes to force-push signed artifacts to physical hardware.

---

## 📂 The Alpha Anywhere Workflow (Asset Triage)
When you are ready to test a new UI update from Alpha Anywhere, you do not need to manually configure the files. 

1. Export your Cordova assets from Alpha Anywhere.
2. The Alpha Anywhere Cordova App Builder will place the generated **`temp`** folder directly into the root of this project. If you are manually updating your Cordova Android app, move all of the revised HTML, JavaScript and CSS files into the temp folder.
3. Run the Build Script.

**What happens next:** The pipeline features an automated **Asset Triage Engine**. It intercepts the `temp` folder, wipes your old `www` directory, migrates the new assets, and uses Regex to safely inject Android 15 (API 36) compliance into your `config.xml` file while stripping outdated plugins. It then deletes the `temp` folder to keep your workspace clean.

---

## ⚡ Ultra-Fast Turbo Sync Engine
To achieve near-instant UI updates (<4 seconds), v2.8.2 utilizes **Persistent Container Execution** combined with **Unified Command Chaining**.

### 1. Persistent `exec` Routing
Instead of destroying the container after every build (`run --rm`), Turbo Sync uses `docker compose exec`. This pushes your UI updates instantly into the awake background container. Because Java and Gradle are already loaded into RAM, the "Cold Boot" penalty is completely eliminated.

### 2. Unified Command Chaining
Turbo Sync treats the asset copy and the Gradle build as a single chained command (`&&`). The container instantly copies the `www` files internally, runs the fast Gradle cache, and cleanly exits the command sequence without restarting.

### 3. The `.turbo_ready` State Flag
To prevent developers from running a Turbo Sync on a broken or uninitialized platform, Option 1 (Full Reset) drops a hidden `.turbo_ready` file into the project root upon success. Option 2 will remain disabled until this flag proves the environment is sterile and ready.

---

## 📲 Smart Hybrid Deployment & Export
Google Play requires **Android App Bundles (`.aab`)**, but rapid local development requires **APKs**. The engine extracts artifacts from Docker's internal volumes to a `debug/` or `release/` folder, then uses a smart fallback system for deployment:

* **Route A: Local USB (Power User Route):** If you have ADB installed on your Windows machine and a phone plugged in, the script detects it and instantly installs the app over the cable, completely bypassing manual prompts.
* **Route B: Wireless Debugging (Zero-Install Route):** If you do not have a local ADB environment, the script will prompt you for your phone's Wi-Fi IP address and pairing port. The Docker container will reach out over your local network, tunnel into your phone, install the app, and disconnect.

By passing the `-r` (replace), `-d` (downgrade), and `-t` (test package) flags during deployment, it forces Android to overwrite existing applications, permanently eliminating debug signature mismatch errors.

---

## 🛑 Project Maintenance: The "Kill Switch"
Because the Dev Container stays awake in the background, it will consume a small amount of RAM while Docker Desktop is open. Furthermore, sometimes you need to completely wipe the caches to guarantee a pristine state.

If you experience "Access Denied" errors in Windows, or if a build acts strangely, use the Kill Switch:
1. Run **`purge-project.bat`**.
2. This script executes `docker compose down -v`. It safely shuts down the background container and permanently destroys the high-speed Docker caches to reclaim disk space.
3. It then initializes an Alpine Linux Janitor to unlock and force-delete the Docker-locked `platforms`, `plugins`, and `node_modules` folders from your Windows host.
4. After a purge, simply run **Option 1 (Full Reset)** to rebuild your environment from scratch.

*(Note: `Production-Build.ps1` runs this deep-clean automatically before every build to guarantee a 100% sterile release artifact).*

---

## 🛡️ The Permission Shield & Security Bridge
One of the primary challenges in WSL2/Docker development is the mismatch between Windows ACLs and Linux UIDs. The engine implements a dual-layer shield:

### 1. HOME Redirection
We force the container's `$HOME` to the project root (`/home/cordovauser/app`). This prevents the container from trying to write to protected or non-existent system folders in the WSL backend.

### 2. The ".bat" Security Wrapper
To resolve `SecurityError: UnauthorizedAccess` issues for team members, we use Batch wrappers (e.g., `Build-And-Install.bat`). These files use a specific flag to bypass Windows execution policies for the session without requiring system-wide changes:
```batch
powershell -ExecutionPolicy Bypass -File .\release-build.ps1
```

---

## 📈 Advanced Release Automation
The engine introduces "Zero-Touch" management for production deployments (`Production-Build.ps1`):

* **Version Bumping:** Automatically reads `config.xml`, increments the `version` string (e.g., 2.3.0 -> 2.4.0).
* **Git Log Injection:** Scrapes all commit messages since the last Git tag and prepends them to the top of `CHANGELOG.md` with a datestamp.
* **Automatic Tagging:** Once a build is successful, the script automatically runs `git commit` and `git tag` to lock the release into your repository history.

---

## 🔊 Audio Notifications 
The build engine includes a `[System.Console]::Beep` audio feedback system, allowing for "eyes-free" monitoring of the build process across Windows and WSL environments.

* **Sync Chime (Short Double High-Tone):** Plays when code changes are successfully detected and synced.
* **Success Melody (Rising Three-Tone):** Plays when a build finishes and successfully installs to the device.
* **Error Alarm (Low Double-Tone):** Plays if a build step fails, ADB deployment fails, or the container crashes.

---

## 🔐 Signing Configuration (`build.json`)
Standardizing on `build.json` is required for production builds. Unlike `.properties` files, JSON allows the Cordova CLI to accurately parse complex signing arguments for both Bundles and APKs.

**Example `build.json`:**
```json
{
    "android": {
        "release": {
            "keystore": "alpha-release.keystore",
            "storePassword": "your_password",
            "alias": "your_alias",
            "password": "your_password",
            "keystoreType": "jks",
            "packageType": "bundle"
        }
    }
}
```

---

## 🔍 Troubleshooting
| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `Parsing config.xml failed` | Raw Alpha Export | Ensure the Alpha export is placed in `temp/` so the Asset Triage engine can sanitize the XML properly. |
| `EACCES: permission denied` | Host/Container locked files | Run `purge-project.bat` to trigger the Alpine Janitor and wipe Docker caches. |
| `WSL 1 detected` | Incompatible filesystem. | v2.8.2 REQUIRES WSL 2. Run `wsl --set-default-version 2`. |
| `SecurityError` | PS Execution Policy. | Always launch using the provided `.bat` wrapper files. |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Signature mismatch | Delete the app manually from the physical device once, then run a build. Future updates will overwrite perfectly. |