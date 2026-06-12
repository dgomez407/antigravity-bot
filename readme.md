# Antigravity Discord bot

This project operates as a Discord control plane to remotely orchestrate and control local installations of Google's **Antigravity IDE** on Windows. By enabling a Chrome DevTools Protocol (CDP) WebSocket endpoint in the IDE, developers can send natural language prompts and instructions (e.g. from a mobile phone via Discord) to control the IDE, run code, and analyze workspaces remotely using local machine resources.

### Compatibility & Submodule Focus
To run reliably with modern builds of the Antigravity IDE, the standard out-of-the-box LazyGravity package requires critical updates for session-routing and chat-panel recovery. This repository bundles a patched, compatible version of the engine as a local Git submodule at [vendor/LazyGravity](./vendor/LazyGravity).

For details on the core engine and its original installation prerequisites, refer to the:
- Local setup instructions: [vendor/LazyGravity/README.md#quick-setup](./vendor/LazyGravity/README.md#quick-setup)
- Upstream documentation: [tokyoweb3/LazyGravity Setup Guide](https://github.com/tokyoweb3/LazyGravity#quick-setup)

---

Run the complete stack from Git Bash with the explicit `start` command:

```bash
./run.sh start
```

The launcher opens the installed `Antigravity IDE.exe` with Chrome DevTools
Protocol (CDP) enabled, waits until port `DEBUGGING_PORT` (default `9222`)
responds with a usable IDE workbench target, then starts LazyGravity in verbose
mode.

`run.sh` is the only launch script. It is organized into documented functions
for dependency checks, colored logging, CDP health checks, IDE startup, and the
readiness wait. Set `NO_COLOR=1` to disable colored output.

Use the built-in help menu to see launcher and diagnostic commands:

```bash
./run.sh --help
```

Running `./run.sh` without arguments shows the help menu. Common commands:

```bash
./run.sh start
./run.sh stop
./run.sh status
./run.sh repair-sessions
./run.sh build-lazygravity
./run.sh doctor
./run.sh cdp-status
./run.sh start --no-color
```


`start` runs LazyGravity as a managed background process. Its PID is stored in
`.lazy-gravity.pid`, and output is appended to `lazy-gravity.log`. `stop`
terminates that managed bot and the Antigravity process listening on the
configured CDP port. `status` reports the bot process, CDP endpoint, and usable
workbench target; it exits nonzero when any component is unavailable.

`repair-sessions` backs up `antigravity.db` and resets only stale renamed chat
bindings that have no persisted Antigravity conversation ID. Use it when
Discord reports that the activated chat title does not match the bound session,
then restart the bot and send the prompt again.

`build-lazygravity` installs dependencies when needed and builds the local
`vendor/LazyGravity` submodule. When message injection cannot find a chat
textbox, the locally modified LazyGravity recovery opens the Antigravity chat
panel with `Ctrl+L` before retrying. `start` builds and runs this local checkout
instead of the globally installed package.

Pending upstream LazyGravity fixes are combined on the fork branch
`integration/pending-upstream-prs`. The parent repository pins the exact tested
integration commit through the `vendor/LazyGravity` submodule pointer, so a
fresh checkout should include submodules:

```bash
git clone --recurse-submodules <parent-repository-url>
```

Keep each upstream pull request on its own branch. When upstream accepts one,
rebuild the integration branch from upstream `main`, merge only the remaining
pending pull-request branches, retest, push with `--force-with-lease`, and
update the parent repository's submodule pointer. See
`decisions/0004-integrate-pending-lazygravity-prs.md`.

The launcher also reads LazyGravity's own Windows temporary lock file. This
allows `start`, `status`, and `stop` to adopt a bot that was started outside
`run.sh`.

Set `ANTIGRAVITY_EXE` in `.env` if Antigravity is installed somewhere else;
use a Git Bash path such as
`/c/Users/name/AppData/Local/Programs/Antigravity IDE/Antigravity IDE.exe`.
Set `ANTIGRAVITY_PATH` to the equivalent Windows path when overriding the
executable LazyGravity uses to open additional project windows. Additional
projects must be opened by `Antigravity IDE.exe` so their workbench targets
join the existing CDP endpoint; the separate `Antigravity.exe` application is
not compatible with this multi-project flow.

If startup reports that CDP did not become available, close every existing
Antigravity window and run `./run.sh start` again. Chromium applications must be
started with the remote-debugging flag on their first process.

Use this diagnostic from the repository directory:

```bash
lazy-gravity doctor
```

`lazy-gravity doctor` confirms that a CDP endpoint is available. You can also
inspect its targets directly:

```bash
curl http://127.0.0.1:9222/json/list
```

## Understanding the Discord CDP status

The startup dashboard may say `CDP: Not connected` while CDP is healthy. In
LazyGravity 0.8.1, that field means that no project has an active connection in
LazyGravity's in-memory connection pool. The pool is intentionally lazy and is
populated only when a message is sent in a project-bound channel or `/join` is
used.

The expected startup sequence is:

1. Run `./run.sh start`.
2. Confirm `lazy-gravity doctor` reports `CDP port 9222 is responding`.
3. Use `/project` to select a project and create or bind its Discord channel.
4. Send a normal prompt in that project channel, or use `/join`.
5. Use `/status`; it should then show the project as connected.

The number of registered projects is a filesystem scan. It does not indicate
that those projects currently have active CDP sessions.

## Testing

Launcher changes follow a focused TDD workflow:

```bash
uv run pytest
```

The tests validate Bash syntax, the command/help contract, unknown-command
handling, stale-lock cleanup, and adoption of LazyGravity's final Node PID
after the pnpm wrapper exits. Live Discord and desktop lifecycle behavior still
requires an operator check with:

```bash
./run.sh stop
./run.sh start
./run.sh status
```

The repository explicitly targets the LazyGravity-compatible IDE at
`%LOCALAPPDATA%\Programs\Antigravity IDE\Antigravity IDE.exe`.
The separate `Programs\Antigravity\Antigravity.exe` application exposes a
generic web page rather than a VS Code workbench target and cannot be controlled
by LazyGravity 0.8.1.
