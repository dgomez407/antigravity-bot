# Antigravity Discord bot

Operates as a Discord control plane for Google's **Antigravity IDE** on Windows via Chrome DevTools Protocol (CDP). This allows remote control of the IDE (e.g., via mobile) using local machine resources.

### Compatibility & Submodule Focus
This repository bundles a patched version of LazyGravity at `vendor/LazyGravity` to ensure reliable session routing and UI unblocking.

- Local setup: [vendor/LazyGravity/README.md#quick-setup](./vendor/LazyGravity/README.md#quick-setup)
- Upstream docs: [LazyGravity Setup Guide](https://github.com/tokyoweb3/LazyGravity#quick-setup)

## Usage

Run the stack from Git Bash:
```bash
./run.sh start
```
This opens Antigravity IDE with CDP enabled (default port 9222) and starts LazyGravity in the background.

### Common Commands (`./run.sh --help`)
- `start`: Starts the managed IDE and background bot. (Set `NO_COLOR=1` to disable colors).
- `stop`: Terminates the bot and the IDE CDP process.
- `status`: Reports the health of the bot, CDP, and workbench.
- `repair-sessions`: Resets stale Discord chat bindings in `antigravity.db`.
- `build-lazygravity`: Builds the local `vendor/LazyGravity` submodule.
- `test`: Runs the Python (launcher) and npm (submodule) test suites.
- `doctor` / `cdp-status`: Diagnostic checks for the environment and CDP targets.

## Configuration & Troubleshooting

- **Custom Path**: Set `ANTIGRAVITY_EXE` in `.env` if not using the default `%LOCALAPPDATA%` path. Use `Antigravity IDE.exe` (not `Antigravity.exe`).
- **CDP Failures**: If CDP fails to start, close **all** existing Antigravity windows and run `./run.sh start` again. The debugging flag only applies to the first process.
- **Diagnostics**: Run `lazy-gravity doctor` or `curl http://127.0.0.1:9222/json/list` to inspect targets.

## Antigravity 2.0 Features

- **Rich Embeds**: Plans, files, and tools appear as native Discord embeds and buttons.
- **Replies & Attachments**: Replying includes the original message context. Text files under 50KB and images can be attached directly in Discord.

## Connection & Lifecycle

- **Lazy CDP Status**: The Discord dashboard may show `CDP: Not connected` even if healthy. Connections populate lazily upon sending a prompt or `/join`.
- **Startup Sequence**: 
  1. `./run.sh start`
  2. Use `/project` in Discord to select a workspace.
  3. Send a prompt or `/join` to connect.
- **Discord Commands**:
  - `/shutdown`: Closes the IDE without killing the bot or losing bindings.
  - `/project list`: Restarts the IDE if closed and shows projects.
  - `/stop`: Interrupts LLM generation.

## Submodule Workflow

Always clone with submodules: `git clone --recurse-submodules <url>`.

**Fork Rules for `vendor/LazyGravity`:**
- **Never commit directly to `main`**. It must perfectly mirror upstream.
- Keep features on `integration/*` branches.
- To sync: pull upstream `main`, push to your fork's `main`, rebase your `integration/*` branch, force push, and update the parent repo pointer.
- See [ADR 0004](decisions/0004-integrate-pending-lazygravity-prs.md).

## Testing

```bash
./run.sh test
```
Validates launcher logic, code quality (pylint), and runs submodule npm tests. 

*Note: Lifecycle behavior changes still require manual testing with `./run.sh stop`, `start`, and `status`.*
