# 📘 Alpha Cordova Developer Guide (v2.2.0)

This guide provides a deep dive into the automation architecture of the Alpha Cordova Suite. Version 2.2.0 focuses on **Environment Stability** and **Build Performance**.

---

## 🏗️ Architecture Overview
The suite uses a **Containerized Build Pattern**. By wrapping the Android SDK, Gradle, and Cordova inside a Docker container, we eliminate "it works on my machine" issues caused by local environment drift.

### The "Brain": `release-build.ps1`
The PowerShell engine handles the orchestration between your Windows host and the Linux container. It performs four critical tasks:
1.  **Sanitization:** Preparing the host filesystem for Docker access.
2.  **Versioning:** Parsing `config.xml` and updating Git tags.
3.  **Orchestration:** Passing the correct environment variables and flags to `docker-compose`.
4.  **Deployment:** Interfacing with the host-side `adb` to push signed artifacts to physical hardware.

---

## 🛡️ The Permission Shield (`EACCES` Resolution)
One of the primary challenges in WSL2/Docker development is the mismatch between Windows ACLs and Linux UIDs. v2.2.0 implements a "Permission Shield":

* **HOME Redirection:** We force the container's `$HOME` to the project root (`/home/cordovauser/app`). This prevents the container from trying to write to protected or non-existent system folders in the WSL backend.
* **`.config` Sanitization:** Many Node.js tools (like Cordova and Insight) try to write telemetry to `~/.config`. If this folder is owned by Windows "System," the build crashes. The script now force-clears and re-grants `Everyone:F` permissions to a local `.config` directory before every build.

---

## ⚡ High-Performance Caching
To avoid the "Massive File Penalty" of syncing `node_modules` or `.gradle` folders across the WSL/Windows 9p bridge, we use **Named Volumes**.

### Why it's faster:
Standard "Bind Mounts" (mapping `C:\project` to `/app`) are slow for small files. **Named Volumes** (`gradle_cache` and `npm_cache`) live entirely within the Docker VM's native EXT4 filesystem.
* **Compile Speed:** 5x - 10x faster than host-mounted caches.
* **Stability:** Eliminates "File Lock" errors caused by Windows Indexer or Anti-Virus scanning the cache during a build.

---

## 🔐 Signing Configuration (`build.json`)
Standardizing on `build.json` is required for the v2.2.0 engine. Unlike `.properties` files, JSON allows the Cordova CLI to accurately parse complex signing arguments for both Bundles and APKs.

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

## 📦 Hybrid Release Strategy
Google Play requires **Android App Bundles (`.aab`)**, but physical devices require **APKs**. v2.2.0 solves this by performing a double-pass build when the `-Install` flag is used:

1.  **Pass 1:** Generates the signed `.aab` for production upload.
2.  **Pass 2:** Generates a signed `.apk` specifically for local testing.
3.  **Deployment:** The script bypasses Cordova's internal `run` logic and uses the **host-side `adb`** to push the signed APK directly. This ensures the app on your phone is bit-for-bit identical to the one going to the store.

---

## 🔍 Troubleshooting
| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | Unsigned APK selected. | Ensure `build.json` is present and passwords are correct. |
| `EACCES: permission denied` | WSL/Windows UID mismatch. | Run `.\Verify-Environment.ps1` to check WSL version. |
| Build artifact not found | File system sync latency. | The script now includes a 2-second "Sync Buffer" to allow Windows to see the new files. |

---
