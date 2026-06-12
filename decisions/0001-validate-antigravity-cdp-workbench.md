# ADR 0001: Validate an Antigravity CDP Workbench Target

## Status

Accepted on 2026-06-11.

## Context

A responding CDP browser endpoint does not guarantee that LazyGravity can
control an Antigravity IDE workspace. LazyGravity 0.8.1 also reports only
active lazy project sessions in its Discord startup dashboard.

## Decision

The repository uses one modular launcher, `run.sh`. It validates both the CDP
version endpoint and the target list. Startup proceeds only when the target
list contains an Antigravity IDE workbench page. Operator-facing messages use
color when attached to a terminal and respect `NO_COLOR`. The launcher exposes
a help menu, explicit lifecycle commands, and non-starting diagnostic actions.
LazyGravity runs as a managed background process with a repository-local PID
file and log. Stop operations target only that PID and the process owning the
configured CDP port.

The launcher treats LazyGravity's own temporary `.bot.lock` PID as
authoritative when no repository PID exists, allowing it to adopt an existing
bot without relying on broad Node process matching.

The controlled IDE executable is the explicit `.env` value
`%LOCALAPPDATA%\Programs\Antigravity IDE\Antigravity IDE.exe`.
The launcher requires a VS Code-style `workbench/workbench.html` target because
that is the target type supported by LazyGravity 0.8.1.

## Consequences

Startup fails early when a debug port is open but no usable IDE page exists.
The Discord startup dashboard can still say `Not connected` until the first
project prompt or `/join`, which is expected LazyGravity behavior.

The former `start.sh` entry point is removed, leaving `run.sh` as the single
documented launcher.

Running `run.sh` without arguments displays help instead of starting services.

Because LazyGravity 0.8.1 does not open the chat panel when injection finds no
textbox, the local `vendor/LazyGravity` submodule contains a source-level fix
that reuses LazyGravity's existing `Ctrl+L` panel opener before retrying
injection. `run.sh start` builds and runs the submodule rather than modifying
the globally installed package.
