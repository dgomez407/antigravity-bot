---
name: safeguard-testing
description: Guidelines for running safe, non-regressive coding assistant tests and code modifications.
---
# Safeguard Testing Guidelines

To guarantee that we retain all gains and do not regress the user acceptance behavior:

- **Incremental Execution**: We will apply the changes one file at a time, checking compile errors immediately.
- **Continuous Test Validation**: We will run the Jest unit tests (`npm test`) after each change to verify that all 1489 tests remain fully green.
- **Strict Localization**: We will keep every change minimal and localized, avoiding any global refactoring or restructuring of the main bot loops.
