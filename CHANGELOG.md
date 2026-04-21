# Changelog

All notable changes to the **Alpha Cordova Android Build Engine** will be documented in this file.

## [2.6.1] - 2026-04-21
### Added
- **Production Track:** New `Production-Release.bat` and `production-build.ps1` workflow.
- **App Bundle Support:** Added ability to generate signed `.aab` files for Google Play Store submission via `--packageType=bundle`.
- **Signed APKs:** Support for signed release `.apk` files for manual sideloading and testing.
- **Auto-Versioning:** Automatic patch-level version incrementing in `config.xml` during production runs.

## [2.5.8] - 2026-04-20
### Fixed
- **CLI Flow:** Replaced `exit` calls with `return` and `goto :eof` to ensure the terminal returns to the command prompt instead of closing the window.
- **Menu Synchronization:** Resolved "Double Menu" display issues by implementing a `-BatchMode` switch for PowerShell.

## [2.5.7] - 2026-04-19
### Added
- **Persistent Signing Shield:** Implemented `android_cache` volume mapping in `docker-compose.yml` to preserve `debug.keystore`.
- **Signing Mismatch Recovery:** Added logic to detect signature discrepancies on-device and perform an automated `uninstall/install` cycle.

## [2.5.6] - 2026-04-18
### Changed
- **Hammer Reset:** Enhanced `Reset-Environment` with an aggressive 15-second retry loop to overcome Windows "Delete-Pending" filesystem locks.
- **Windows Indexer Breather:** Added a mandatory 2-second cooldown after volume wipes to allow the host OS to stabilize.

## [2.5.0] - 2026-04-16
### Added
- **Turbo Sync Intelligence:** Introduced byte-level MD5 hashing for the `/www` directory to skip redundant Gradle compilations when no source changes are detected.
### Changed
- **Volume Architecture:** Optimized `docker-compose.yml` with named volumes for `platforms`, `node_modules`, and `plugins` to bypass WSL2/Windows file sync latency.

## [2.4.8] - 2026-04-14
### Added
- **API 36 Support:** Stabilized Docker image and environment variables for Android 15 (API 36).
- **Direct-Stream Bridging:** Implemented `docker cp` via a temporary detached container to reliably move APKs from Linux volumes to the Windows host.

## [2.3.3] - 2026-04-07

### Added
- **Smart Sync Engine**: Added MD5 file hashing in `release-build.ps1` to prevent redundant builds when no `/www` changes exist.
- **Audio Cues**: Added `Play-ChangeDetected` (trill) and updated success/error beeps for eyes-free status updates.
- **Performance Tracking**: New "Build Timer" displays elapsed seconds for both Full and Turbo builds.

### Changed
- **Turbo Sync Optimization**: Swapped `cordova compile` for direct `gradlew` execution, reducing build overhead by ~10 seconds.
- **Docker Workflow**: Updated execution to use `--workdir /home/cordovauser/app/platforms/android` for better build stability.
- **UX Improvements**: Changed `Build-And-Install.bat` to use a 5-second `timeout` instead of a manual `pause`.
- **Refactoring**: Converted Batch-style `goto` labels in PowerShell to native `if/else` blocks to resolve `CommandNotFoundException`.

### Fixed
- Resolved "Directory does not contain a Gradle build" errors by anchoring Docker commands to the platform root.
- Updated `.gitignore` to exclude `.last_sync_hash` state files.

## [2.3.2] - 2026-04-07

### Fixed
- **Terminal Encoding:** Implemented a "BOM-shield" header in all `.bat` files to prevent command echoing caused by UTF-8 Byte Order Mark (BOM) collisions in Windows CMD.
- **Emoji Rendering:** Added explicit `chcp 65001` switching to ensure UI icons (📱, 🔄, 🚀) render correctly across different Windows terminal configurations.

### Changed
- **Script Initialization:** Updated `Build-And-Install.bat`, `Verify-Environment.bat`, and `Production-Release.bat` with a standardized 4-line silent boot sequence for improved console professionality.

## [2.3.1] - 2026-04-06

### ✨ Added
* **Visual Build Status:** Integrated a full suite of emojis (🚀, ⚡, 💎, 🏗️) across all Batch and PowerShell scripts to provide immediate visual feedback on build states.
* **Permission Shield v2.3.1:** Enhanced automated `EACCES` resolution and `.config` sanitization to ensure cross-machine stability.
* **Docker Health Check:** Added a pre-flight Docker Engine verification to the loader to prevent "Service not found" errors.
* **vscode/settings.json:** Ensures UTF-8 BOM file encoding when any edits are done. See Encoding Standard below.

### 🛠️ Changed
* **Encoding Standard:** Migrated all core scripts to **UTF-8 with BOM** to ensure PowerShell 5.1 correctly renders iconography without syntax "terminator" errors.
* **Dynamic Build Menu:** The `Build-And-Install.bat` now intelligently locks the **Turbo Sync** option if the Android platform has not been initialized.
* **Output Encoding:** Forced `[Console]::OutputEncoding` to UTF8 within the PowerShell engine to synchronize with the Windows `chcp 65001` code page.

### 🧹 Fixed
* **Ghosting Menu Items:** Resolved a Batch parser bug where multiple menu options would print simultaneously due to `IF/ELSE` block instability.
* **Path Conflicts:** Fixed an issue where localized `.config` folders could interfere with Docker volume mounting.

---

## [2.3.0] - 2026-03-31
### 🚀 Added
* **Master Edition Consolidation:** Merged high-performance caching with advanced release automation into a single robust engine.
* **Verify-Environment.bat:** Added a one-click batch wrapper to launch diagnostics without needing to manually bypass PowerShell execution policies.
* **Folder Shadowing Technique:** Updated `docker-compose.yml` to map Named Volumes directly to `.gradle` and `.npm` sub-folders, forcing high-speed Linux performance.
* **Automated Versioning (Restored):** Automatic incrementing of `android-versionCode` and version strings in `config.xml`.
* **Git Log Injection:** The build engine now automatically scrapes recent commit history and prepends it to this changelog during release.
* **Verify-Environment v2.3.0:** Stricter diagnostic checks for WSL 2 status and PowerShell 5.1/7.0 compatibility.

### 🛡️ Fixed
* **EACCES Final Boss:** Resolved persistent permission denied errors by aligning the container `HOME` path with the project root and sanitizing `.config` permissions.
* **Turbo Sync Mismatch:** Fixed the bug where the cache was bypassing Named Volumes and writing to the slow Windows host.
* **WSL 1 Compatibility:** Added explicit warnings and blockages for WSL 1 to prevent volume-mounting failures.

---

## [2.2.0] - 2026-03-30

### Added
- **Interactive Versioning:** New prompt in `Production-Release.bat` allows manual version overrides (e.g., forcing v2.2.0).
- **Verify-Environment Script:** New diagnostic tool to validate WSL 2, Docker, and JDK 17+ status.
- **Hybrid Build Logic:** Simultaneous generation of `.aab` and `.apk` artifacts during release installs.

### Fixed
- **Permission Stability:** Implemented HOME redirection and `.config` sanitization to stop `EACCES` errors.
- **PowerShell Compatibility:** Refactored ternary operators for PS 5.1 compatibility.
- **Signing Parser:** Switched to `build.json` to resolve "Not valid JSON" errors during release builds.
- **Performance:** Re-enabled high-speed caching via Docker Named Volumes.

## [2.1.0] - 2026-03-27

### ✨ Added
* **Developer Guide:** Introduced [DEVELOPER_GUIDE.md](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/DEVELOPER_GUIDE.md) covering advanced configuration, environment variables, and manual recovery steps.
* **Linux/Windows Compatibility:** Added a [.gitattributes](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/.gitattributes) file to enforce `LF` line endings for shell scripts and `CRLF` for batch files, ensuring the suite runs seamlessly across WSL, Linux hosts, and Windows.
* **Global .gitignore:** Added a standardized [.gitignore](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/.gitignore) to prevent Docker logs, local properties, and platform artifacts from polluting the repository.

### 🛠️ Fixed
* **Shell Script Execution:** Resolved an issue where scripts cloned on Windows would fail to execute inside the Docker container due to incorrect line-ending formats.
* **Path Mapping:** Improved volume mounting logic in `docker-compose.yml` to better handle absolute paths in different terminal environments.

## [2.0.0] - [Legacy]
### Added
- Initial Dockerized build implementation.
- Basic Batch file entry point for Cordova commands.
- Support for Alpha Cordova V2 script architecture.

---

> **Note:** Versions prior to 2.4.8 refer to the legacy development branch. Versions 2.5.0 and above represent the high-performance refactor for API 36 stability.

### 📝 Documentation
* Updated the main [README.md](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/README.md) to reflect the new versioning and added a "Quick Start" checklist for new users.

---
