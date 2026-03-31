## [2.2.0] - 2026-03-31

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
