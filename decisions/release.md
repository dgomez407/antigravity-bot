# Release Log

This log lists major releases and their key architectural updates.

---

## v2.2.0 - Code Quality Linting

- **Linter Integration**: Added `pylint` as a dev dependency managed by `uv`.
- **Test Automation**: Integrated `pylint` execution directly into the `pytest` suite via `tests/test_pylint.py`, ensuring style and quality checks block test execution on failure.
- **Linter Configuration**: Configured custom pylint options, disabling `missing-docstring` and adjusting `max-line-length` in `pyproject.toml`.
- **ADR Publication**: Added ADR 0005 to record the code quality linting decision.

---

## v2.1.0 - Security, Portability & Public Preparation

- **Sanitization**: Removed all personal Discord bot tokens, server/guild IDs, user IDs, and local system path prefixes from `.env.example`.
- **Portability**: Updated `run.sh` to dynamically resolve the location of `%LOCALAPPDATA%` and the user profile directory rather than hardcoding user-specific paths.
- **Git Security**: Optimized `.gitignore` to robustly cover Python cache files, test coverage, logs (`*.log`), and SQLite database variations (`antigravity.db*`).
- **Documentation**: Cleaned and generalized path references in architectural decisions and user documentation to prepare the repository for public/private sharing.
- **Tests**: Re-designed test suites in `tests/test_run_script.py` to target path structures dynamically and fallback gracefully if a local `.env` file is missing.

---

## v2.0.0 - Windows Multi-Project & Session Routing Fixes

- **Multi-Project Connection**: Fixed Windows multi-project setups by forcing additional projects to open under `Antigravity IDE.exe`, linking them to the active Chrome DevTools Protocol (CDP) port.
- **Session Routing**: Corrected saved-session routing by reading the highlighted workspace row when Antigravity IDE retains the generic `Agent` header, and focused/entered options in the Past Conversations picker.
- **PR Contributions**: Set up fork branches for upstream pull requests (`fix/current-antigravity-chat-input`, `fix/windows-multi-project-routing`) and merged them into a unified `integration/pending-upstream-prs` branch pinned by the parent submodule.

---

## v1.0.0 - Launcher Consolidation & Test Coverage

- **Launcher Consolidation**: Merged all starting, stopping, diagnostics, and status monitoring flows into a single modular launcher (`run.sh`).
- **Submodule Integration**: Vendorized the LazyGravity dependency as a local submodule at `vendor/LazyGravity` to reliably apply chat-panel recovery patches.
- **Process Management**: Managed background processes cleanly by tracking active locks and adopting external PIDs dynamically.
- **Testing**: Added a `pytest` suite running under Git Bash to validate syntax, CLI options, and process adoption.
