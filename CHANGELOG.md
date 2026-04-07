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

### 📝 Documentation
* Updated the main [README.md](https://github.com/remoorejr/alpha-cordova-v2-scripts/blob/main/README.md) to reflect the new versioning and added a "Quick Start" checklist for new users.

---
