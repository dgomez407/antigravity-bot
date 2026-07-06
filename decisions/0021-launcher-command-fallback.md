# 21. Launcher Command Fallback for Windows Executables

Date: 2026-07-06

## Status

Accepted

## Context

LazyGravity uses `run.sh` as a single launcher and entry point. The script contains dependency validation checks via `require_command` which verifies that necessary binaries (such as `uv`, `node`, and `python`) are available in the shell's `PATH`.

When automated coding agents or environments run the launcher (frequently using shells like WSL `bash` on Windows, or mixed shell settings where user profile environments are not loaded), these tools are often only available in the `PATH` with their Windows executable extensions (`uv.exe`, `node.exe`, `python.exe`). Because Linux-style shells like WSL bash do not automatically resolve extensionless commands to `.exe` files, the `command -v <command>` check fails, resulting in a false-positive `[ERROR] Required command not found` error and aborting launcher actions.

## Decision

We have updated [run.sh](../run.sh) to dynamically detect and wrap commands that are only available with a `.exe` suffix:
1. **Fallback Checks**: After resolving the script directory, the launcher checks if core extensionless commands (`uv`, `node`, `python`) are absent from the shell, but their `.exe` equivalents exist in the `PATH`.
2. **Dynamic Wrapper Functions**: If a `.exe` version of a missing command is detected, the launcher defines a bash function wrapper of the same name (e.g. `uv() { uv.exe "$@"; }`).
3. This ensures that checks like `command -v uv` succeed (as `uv` is now recognized as a valid shell function), and subsequent calls to `uv run ...` correctly route to `uv.exe run ...`.

## Consequences

- Automated agents and cross-platform runners on Windows can successfully invoke launcher commands (like `./run.sh test`) without manual path workarounds.
- Maintained compatibility with Git Bash, where the `.exe` suffix is handled natively and wrapper functions are skipped.
- Preserved standard execution behaviors without adding overhead or external dependencies.
