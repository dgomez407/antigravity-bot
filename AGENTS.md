# Repository Guidelines

## Purpose

This repository operates LazyGravity as a Discord control plane for the local
Antigravity IDE installation on Windows.

## Project Structure

- `.env`: Local LazyGravity and Discord configuration. Keep secrets here only.
- `run.sh`: Single modular launcher with a help menu and diagnostics. Starts
  Antigravity with CDP, validates a workbench target, then starts LazyGravity.
- `vendor/LazyGravity`: Git submodule containing local-only LazyGravity fixes.
- `antigravity.db`: LazyGravity channel, workspace, and session bindings.
- `readme.md`: Operator setup, startup, status interpretation, and diagnostics.
- `decisions/`: Architecture decisions and required release log.

## Operating Commands

Run from Git Bash in the repository root:

```bash
./run.sh
./run.sh --help
./run.sh start
./run.sh stop
./run.sh status
./run.sh repair-sessions
./run.sh build-lazygravity
./run.sh doctor
./run.sh cdp-status
lazy-gravity doctor
curl http://127.0.0.1:9222/json/list
```

## CDP Behavior

LazyGravity 0.8.1 uses lazy per-project CDP connections. Its Discord startup
dashboard reports `CDP: Not connected` until a prompt is sent in a bound
project channel or `/join` connects a project. This does not by itself mean
that port `9222` is unavailable. Use `lazy-gravity doctor` and `/json/list` to
diagnose the transport.

## Testing

Run `uv run pytest` after launcher changes. Add or update a regression test
before fixing lifecycle bugs. Live `stop`/`start`/`status` validation is
required when process-management behavior changes.

## Development Conventions

- Keep environment-specific values and all secrets in `.env`.
- Do not commit or document real Discord tokens or other credentials.
- Do not use absolute `file:///` paths in markdown links within persistent repository files (e.g., READMEs, ADRs). Always use relative paths (e.g., `./relative/path`) to avoid leaking personal directory paths in Git history.
- Keep startup behavior in the documented functions within `run.sh` and
  preserve compatibility with Git Bash on Windows.
- Use the existing colored log helpers for operator-facing launcher messages.
- Keep process management scoped to the PID recorded by `run.sh` and the
  process owning the configured CDP port.
- Update `readme.md` whenever operator behavior changes.
- Keep `vendor/LazyGravity` changes as local submodule commits only. Do not
  push, fork, or open upstream pull requests.

## Mandatory Closing Step

Before concluding any changes, update `decisions/release.md`.

Any change to filesystem layout or core tooling requires a new ADR in
`decisions/` and a reference from the release log.
