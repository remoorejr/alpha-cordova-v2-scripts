
# 🛠️ Developer Onboarding: Alpha Cordova Suite

This project uses a **Dockerized Build Pipeline** to ensure that every developer builds the app using the exact same Android SDK, Gradle, and Node versions, regardless of their local machine setup.

## 1. Local Environment Setup
To interface with the Docker container and your physical hardware, your host machine needs these four tools:

* **Docker Desktop:** Used to run the build container. Ensure it is running before starting any build script.
* **Java JDK 17+ (Tooling & Communication):** While the actual app compilation happens inside Docker, a local JDK is required for the Windows host to run Android platform tools (like `adb`, `keytool`, and `jarsigner`) and to manage the handshake between your PC and the mobile device.
* **Android SDK Platform-Tools (ADB):** Essential for deployment. You must be able to run `adb devices` in your terminal.
* **Git:** Required for the automated versioning, changelog generation, and production tagging system.

---

### 🟦 PowerShell Requirements
Our automation engine (`release-build.ps1`) requires specific configurations to run correctly on a developer's machine:

* **Version:** **PowerShell 5.1** (Standard on Windows 10/11) or **PowerShell 7+ (Core)**.
* **Execution Policy:** By default, Windows blocks the execution of local scripts. Our `.bat` files use the `-ExecutionPolicy Bypass` flag to circumvent this for the specific build session, so developers **do not** need to change their global system security settings.
* **Encoding:** If you edit the `.ps1` or `.bat` files, they **must** be saved saved using **UTF-8 encoding**. Using "UTF-16" or "ANSI" can cause the "Unexpected Token" errors.

---

## 2. The "Three-File" Workflow
We use three main entry points to manage the application lifecycle:

### A. `Build-And-Install.bat` (The Daily Driver)
Use this during active development.
* **Option 1 (Full Reset):** Use this if you have modified `config.xml`, added a new Cordova plugin, or if the environment feels "glitchy." It wipes the platform and starts fresh.
* **Option 2 (Turbo Sync):** Use this for **90% of your work**. If you only changed HTML, CSS, or JS in the `www/` folder, this will sync your changes to the device in seconds without a full re-compile.

### B. `Production-Release.bat` (The Deployment Tool)
Only use this when you are ready to ship a version to the Play Store. It handles version bumping, changelog updates, and Git tagging automatically.

### C. `release-build.ps1` (The Engine)
The "Brain" that the `.bat` files talk to. It handles the pre-flight logic, JDK verification, and device detection.

---

## 3. Targeting Android 15 (API 36)
Our environment is specifically tuned for **API 36 (Baklava)**. 
* **Compilation:** Handled entirely within the Docker container to avoid "Path" or "Environment Variable" conflicts on your local machine.
* **Host-Side Java:** The build engine will warn you if your host is below JDK 17. This is a safety check to ensure your local Android tools are modern enough to communicate with an API 36 device.

---

## 4. Best Practices
1.  **Keep it Clean:** If the build fails unexpectedly, delete the `platforms/` folder and run a **Full Reset (Option 1)**.
2.  **Commit Often:** The Production script generates changelogs based on your commit history. Better commit messages = better changelogs.
3.  **Device Connection:** If the script says "No device found," toggle "USB Debugging" off and back on on your phone.

---

## 5. Troubleshooting
* **ADB Socket Errors:** If you see `ADB server didn't ACK`, run `adb kill-server` and then try the build again. This resets the bridge between Windows and Docker.
* **Version Mismatch:** If the Play Store rejects an upload, check that your `android-versionCode` in `config.xml` is higher than the last one you uploaded.

---

## 6. Manual Troubleshooting & PowerShell Direct Access

If the `.bat` files fail with a generic error, you can run the PowerShell engine directly to see a more verbose debug output.

### A. Bypassing Execution Policies
If you receive a "scripts are disabled" error when running the `.ps1` file manually, use the following command in your terminal to run a build while bypassing local restrictions:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\release-build.ps1" -Install
```

### B. Common Manual Fixes
* **Script "Stuck" on Device Discovery:** If the script hangs at `Checking for devices...`, run `adb kill-server` followed by `adb devices`. If your device shows as `unauthorized`, check your phone's screen to "Always allow" the connection from this computer.
* **Docker Context Errors:** If you get an error like `docker-compose not found`, ensure you are running the command from the project root and that **Docker Desktop** is currently active.
* **Empty $FINAL_OUT Error:**
  If you encounter a `Test-Path` error, it usually means the Android build failed inside the container before the file could be created. Scroll up in your terminal to find the **Java/Gradle error** inside the Docker logs.

### C. Resetting the Environment
If all else fails, perform a "Deep Clean":
1. Close all terminals.
2. Run `docker system prune` (Warning: this clears unused Docker data).
3. Delete the `platforms/` and `plugins/` folders manually.
4. Re-run `Build-And-Install.bat` (Option 1).

---
