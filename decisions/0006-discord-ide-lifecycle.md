# ADR 0006: Manage the Antigravity IDE Lifecycle from Discord

## Status

Accepted

## Context

LazyGravity's `/stop` command interrupts active generation. Remote operators
also need to shut down the IDE while keeping the Discord bot available to
start it again later.

The existing `./run.sh stop` command cannot serve this purpose because it
intentionally stops both LazyGravity and the IDE.

## Decision

LazyGravity owns IDE-only lifecycle operations:

- `/shutdown` disconnects LazyGravity's CDP pool and terminates the process
  owning the configured CDP port.
- `/stop` continues to interrupt active LLM generation.
- `/project list` ensures the IDE is running before displaying projects.
- LazyGravity remains online while the IDE is stopped.
- `./run.sh stop` remains the full-stack shutdown command.

IDE shutdown is scoped to the process owning the configured CDP port. Startup
uses the configured `ANTIGRAVITY_PATH` and waits for CDP readiness.

## Consequences

Remote operators can stop and restart the IDE without local terminal access.
Existing project and session bindings remain persisted, while CDP connections
are recreated lazily after restart.

The new command avoids changing the established `/stop` contract.
