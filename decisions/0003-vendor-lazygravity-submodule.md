# ADR 0003: Maintain LazyGravity as a Local-Only Submodule

## Status

Accepted on 2026-06-11.

## Context

The current Antigravity IDE requires LazyGravity source changes for reliable
chat-panel recovery. Patching the globally installed package is not
reproducible.

## Decision

Track `tokyoweb3/LazyGravity` as the `vendor/LazyGravity` Git submodule. Keep
vendor modifications as local commits only. Do not push them, create an
upstream fork, or submit a pull request. Build and run the submodule from the
parent launcher.

## Consequences

Initial setup requires submodule initialization and `npm ci`. Local vendor
commits must be preserved when moving the parent repository.
