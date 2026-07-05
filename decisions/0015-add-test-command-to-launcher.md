# 15. Add Test Command to Launcher

Date: 2026-07-03

## Status

Accepted

## Context

The repository includes a Python test suite intended to be executed via `uv run pytest`. While there were instructions in `AGENTS.md` to run the tests after launcher changes, the `run.sh` launcher script itself did not provide a built-in command to run the test suite. This lack of a built-in command made the launcher less comprehensive as a unified entry point for all repository operations.

## Decision

We extended the `run.sh` script to include a `test` command. This command encapsulates the execution of `uv run pytest`, providing a clear and standardized way to run tests through the primary launcher.

## Consequences

- Operators and developers can now run the Python test suite directly via `./run.sh test`.
- The `run.sh` launcher is now a more complete tool for managing the lifecycle, building, and testing of the project.
- Reduces cognitive load by keeping all primary commands consolidated in `run.sh`.
