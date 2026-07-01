# Release Log

This log lists major releases and their key architectural updates.

---

## v2.4.0 - Structured Discord Rendering & Attachments

- **Submodule Feature**: Added structured DOM extraction for Antigravity 2.0 to properly identify plan cards, file changes, and action buttons.
- **Submodule Feature**: Implemented a native Discord renderer to parse extracted Antigravity responses into rich Discord Embeds, avoiding flattened markdown clutter.
- **Submodule Feature**: Supported Discord message replies by dynamically prepending the replied-to message content into the prompt context for the LLM.
- **Submodule Feature**: Supported Discord text attachments (under 50KB), fetching and injecting their contents into the prompt.
- **ADR Publication**: Added [ADR 0007](./0007-structured-discord-rendering.md) to record the switch from regex extraction to structured DOM extraction and Discord Rendering.

---

## v2.3.7 - Custom Channel Naming

- **Enhancement**: Implemented `/new <name>` slash command option to allow users to specify a custom name for the Discord channel. The custom name is additionally injected into the IDE conversation UI (see [ADR 0010](./0010-custom-channel-naming-for-new-command.md)).

---

## v2.3.6 - Strict File Change Channel Isolation & Discord File Open Support

- **Security Fix**: Fixed cross-project command bleeding by updating `fileChangeButtonAction` to enforce strict channel scoping, preventing legacy IDs from triggering commands in the wrong context (see [ADR 0008](./0008-enforce-strict-channel-isolation-for-file-changes.md)).
- **Bug Fix**: Removed the `getLatestConversationWithArtifacts()` fallback to ensure Discord strictly binds to the active IDE session's artifacts, preventing past implementation plans from bleeding into unrelated projects (see [ADR 0009](./0009-strict-artifact-resolution.md)).
- **Bug Fix**: Added `review` to `PROCEED_PATTERNS` so that the "Review" button in the IDE planning UI correctly propagates to Discord (see [ADR 0011](./0011-discord-review-button-detection.md)).
- **Enhancement**: The `/new` slash command now explicitly signals the IDE to start a new chat session via CDP, ensuring the active page correctly matches the newly created Discord channel (see [ADR 0012](./0012-synchronized-new-chat-session-lifecycle.md)).
- **ADR Publication**: Added ADR 0008 to document the strict channel isolation requirement for file changes.
- **Submodule Feature**: Implemented `fileOpenCache` to map file hashes to URLs, allowing users to click Discord buttons to open cited files (such as implementation plans) in the Antigravity IDE via CDP.
- **Submodule Security**: Explicitly disabled the "reject" action for planning dialogs on Discord and Telegram, responding with a message that plan rejection is not allowed.

---

## v2.3.5 - Secure Workspace Interaction Routing & Shutdown Command Bug Fix

- **Submodule Fix**: Updated `vendor/LazyGravity` to completely eliminate the global `lastActiveWorkspace` fallback for Discord button and modal interactions.
- **Security Update**: Actions are now strictly routed and bounded to the specific workspace paired with the originating Discord `channel.id` via the injected `WorkspaceCommandHandler`.
- **ADR Publication**: Added ADR 0007 to record the strict workspace interaction routing decision.
- **Submodule Fix**: Fixed the `/shutdown` command in `vendor/LazyGravity` to properly detect the Antigravity IDE by checking the CDP `User-Agent` string, as the `Browser` string sometimes reports generic Chrome versions.

---

## v2.3.4 - Question Modal Support

- **Submodule Feature**: Created `feature/question-modal-support` in `vendor/LazyGravity` to add robust CDP detection and Discord select-menu interactions for Antigravity's new multiple-choice Question Modal UI.
- **Submodule Fix**: Bypassed Electron DOM click limitations by resolving specific CDP interaction coordinates for dropdown options and submit buttons.

---

## v2.3.3 - Robust Action UI Detectors

- **Submodule Fix**: Updated `vendor/LazyGravity` to handle changes in Antigravity's UI. `planningDetector.ts` was relaxed to detect implementation plans when only a "Proceed" button is present (removing the strict requirement for an "Open" button).
- **Submodule Fix**: `runCommandDetector.ts` was updated to recognize "command execution" as a valid card header for intercepting command execution permission prompts.

---

## v2.3.2 - Robust Chat Session Activation Matching

- **Submodule Fix**: Created `fix/robust-session-activation-matching` in `vendor/LazyGravity` to implement token prefix/word matching fallbacks in chat activation scripts, resolving routing failures from title variations.
- **UI Unblocking Fix**: Ensured the IDE's "Past Conversations" Quick Pick panel is reliably closed via Escape key when a session match fails, preventing subsequent command injections from being absorbed by the search box.
---

## v2.3.1 - LazyGravity Submodule Update

- **Submodule Update**: Updated `vendor/LazyGravity` to include PR 178 and PR 179, addressing cross-platform process termination and OS dependency fixes in tests.

---

## v2.3.0 - Discord IDE Lifecycle Control

- **Remote IDE Shutdown**: Added Discord `/shutdown` to shut down the
  Antigravity IDE while leaving LazyGravity online.
- **Command Compatibility**: Preserved `/stop` for interrupting active LLM
  generation.
- **Lazy Restart**: Changed `/project list` to start Antigravity when CDP is not
  available before displaying projects.
- **Process Scope**: IDE shutdown targets only the process owning the configured
  CDP port; `./run.sh stop` remains the full-stack shutdown command.
- **ADR Publication**: Added ADR 0006 to record the Discord IDE lifecycle
  boundary.

---

## v2.2.0 - Code Quality Linting

- **Linter Integration**: Added `pylint` as a dev dependency managed by `uv`.
- **Test Automation**: Integrated `pylint` execution directly into the `pytest` suite via `tests/test_pylint.py`, ensuring style and quality checks block test execution on failure.
- **Linter Configuration**: Configured custom pylint options, disabling `missing-docstring` and adjusting `max-line-length` in `pyproject.toml`.
- **ADR Publication**: Added ADR 0005 to record the code quality linting decision.

---

## v2.1.0 - Security, Portability & Public Preparation

- **Sanitization**: Removed all personal Discord bot tokens, server/guild IDs, user IDs, and local system path prefixes from `.env.example`.
- **Portability**: Updated `run.sh` to dynamically resolve the location of `%LOCALAPPDATA%` and the user profile directory rather than hardcoding user-specific paths.
- **Git Security**: Optimized `.gitignore` to robustly cover Python cache files, test coverage, logs (`*.log`), and SQLite database variations (`antigravity.db*`).
- **Documentation**: Cleaned and generalized path references in architectural decisions and user documentation to prepare the repository for public/private sharing.
- **Tests**: Re-designed test suites in `tests/test_run_script.py` to target path structures dynamically and fallback gracefully if a local `.env` file is missing.

---

## v2.0.1 - Submodule PR Synchronization & Validation

- **PR Integration**: Pulled and synchronized accepted suggestions/changes for PR #178 (`fix/windows-multi-project-routing`) and PR #179 (`feature/discord-ide-lifecycle`) in `vendor/LazyGravity`.
- **Validation**: Executed the full unit test suite (108 suites, 1416 tests) to verify functionality.
- **Branch Merges**: Pushed the updated branches to `fork` and merged the validated changes into the submodule's `integration/pending-upstream-prs` and `main` branches.

---

## v2.0.0 - Windows Multi-Project & Session Routing Fixes

- **Multi-Project Connection**: Fixed Windows multi-project setups by forcing additional projects to open under `Antigravity IDE.exe`, linking them to the active Chrome DevTools Protocol (CDP) port.
- **Session Routing**: Corrected saved-session routing by reading the highlighted workspace row when Antigravity IDE retains the generic `Agent` header, and focused/entered options in the Past Conversations picker.
- **PR Contributions**: Set up fork branches for upstream pull requests (`fix/current-antigravity-chat-input`, `fix/windows-multi-project-routing`) and merged them into a unified `integration/pending-upstream-prs` branch pinned by the parent submodule.

---

## v1.0.0 - Launcher Consolidation & Test Coverage

- **Launcher Consolidation**: Merged all starting, stopping, diagnostics, and status monitoring flows into a single modular launcher (`run.sh`).
- **Submodule Integration**: Vendorized the LazyGravity dependency as a local submodule at `vendor/LazyGravity` to reliably apply chat-panel recovery patches.
- **Process Management**: Managed background processes cleanly by tracking active locks and adopting external PIDs dynamically.
- **Testing**: Added a `pytest` suite running under Git Bash to validate syntax, CLI options, and process adoption.
