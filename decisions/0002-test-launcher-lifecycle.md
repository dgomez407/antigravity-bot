# ADR 0002: Test the Launcher Lifecycle Contract

## Status

Accepted on 2026-06-11.

## Context

The repository launcher now owns command parsing and Windows process lifecycle
behavior. Regressions in no-argument behavior, command names, syntax, or stale
LazyGravity lock handling can prevent remote operation.

## Decision

Use pytest to validate the launcher command contract, Bash syntax, and the
stale-lock cleanup regression. Keep live Discord and GUI lifecycle checks as
operator validation because they require local credentials and desktop access.

## Consequences

Run `uv run pytest` after launcher changes. Tests require Git Bash for dynamic
command checks and skip those checks when Bash is unavailable.
