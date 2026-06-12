# Gemini Agent Guidance

See [AGENTS.md](./AGENTS.md) for repository guidelines and [readme.md](./readme.md)
for operator instructions.

This repository launches LazyGravity as a Discord control plane for Antigravity
IDE. LazyGravity 0.8.1 creates project CDP sessions lazily, so its startup
dashboard can report `CDP: Not connected` even while port `9222` and the
Antigravity workbench target are healthy.

Use `./run.sh` as the only launcher. Run `./run.sh start` to start the stack,
and `./run.sh --help` for its command menu.
