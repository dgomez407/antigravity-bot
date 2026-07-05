# 0016: Add npm Test Support to Launcher

## Status

Accepted

## Context

The `./run.sh test` command was previously introduced to run the Python test suite via `uv run pytest`. However, the project also contains a `vendor/LazyGravity` submodule which has its own npm test suite (`jest`). The launcher's test command did not execute these tests, leading to incomplete test coverage during development.

## Decision

We have updated the `run_tests` function in `run.sh` to execute the npm tests located within the `vendor/LazyGravity` submodule, in addition to the existing Python tests.

When `./run.sh test` is executed, the following actions occur:
1. Python tests are run using `uv run pytest`.
2. The script checks if the `vendor/LazyGravity` directory exists.
3. If the directory exists, it changes into that directory, ensures dependencies are installed via `npm ci` (if `node_modules` is not present), and then executes `npm test`.

## Consequences

- **Improved Test Coverage**: The `test` command now runs tests for both the Python and Node.js parts of the stack.
- **Dependency Execution**: Requires `npm` to be installed and available in the environment to run the Node.js tests.
- **Workflow Uniformity**: Running `test` gives full assurance that both python logic and submodule logic tests are passing in a single command.
