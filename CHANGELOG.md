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