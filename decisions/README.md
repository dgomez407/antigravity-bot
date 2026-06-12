# Architectural Decisions

This document consolidates the active architectural decisions for the LazyGravity-based Discord control plane.

---

## 1. Single Launcher & Process Control (`run.sh`)

- **Decision**: All startup, shutdown, and status diagnostics are routed through a single modular Bash launcher (`run.sh`).
- **Antigravity Execution**: Reuses or starts `Antigravity IDE.exe` with CDP enabled (remote debugging port `9222`). Startup blocks until a VS Code-style `workbench/workbench.html` target is active.
- **Process Management**:
  - LazyGravity is run as a managed background process.
  - The launcher reads and writes `.lazy-gravity.pid` and `lazy-gravity.log` to track the bot.
  - On shutdown (`stop`), native Windows/PowerShell utility calls (`Stop-Process`) are used to ensure the recorded bot PID and the process listening on the CDP port are cleanly terminated.

---

## 2. Test Strategy (`pytest` Integration)

- **Decision**: Validate the shell launcher's contract programmatically instead of relying on manual operator checks for command-line parsing.
- **Implementation**: A pytest suite (`tests/test_run_script.py`) asserts:
  - Syntactic validity under Git Bash.
  - Command contract compliance (e.g. `--help`, `--version`, and unknown command exits).
  - Background PID-file adoption and stale lock-file removal.
- **Execution**: Run `uv run pytest` to execute the validation.

---

## 3. Submodule & Contributing Workflow (`vendor/LazyGravity`)

- **Decision**: Maintain modified version of LazyGravity as a local submodule at `vendor/LazyGravity`.
- **Branch Management**:
  - Specific feature fixes are maintained on dedicated local-only branches (e.g., `fix/current-antigravity-chat-input`, `fix/windows-multi-project-routing`).
  - Combined fixes are merged into the local `integration/pending-upstream-prs` branch of the submodule fork.
  - The parent repository pins the exact combined tested commit via the submodule pointer.
- **Contributions**: PRs to the upstream repository are initiated from independent branches of the fork, keeping the parent repository's default branch clean and secure.
