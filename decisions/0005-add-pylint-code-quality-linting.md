# ADR 0005: Add Pylint Code Quality Linting

## Status

Accepted on 2026-06-12.

## Context

As the repository grows and receives contributions, maintaining code quality and ensuring PEP 8 standards for Python files is essential to avoid runtime errors and keep the codebase clean.

## Decision

Add `pylint` to the developer dependencies and integrate it into the `pytest` test suite. Pylint will run on all Python files and block test passes if there are any linting warnings or errors. Pylint rules are configured directly in `pyproject.toml`.

## Consequences

- Running `uv run pytest` now automatically executes `pylint` checks.
- Code quality is continuously checked and enforced during testing.
- Developers can configure custom pylint rules or disable specific warning messages by editing `pyproject.toml`.
