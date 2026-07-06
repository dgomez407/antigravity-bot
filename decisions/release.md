# Release Log

This log lists major releases and their key architectural updates.

---

## feature/heartbeat-notification - Optional Heartbeat / Keep-Alive Notification

- **Submodule Feature**: Implemented a periodic heartbeat notification service (`HeartbeatService`) in `vendor/LazyGravity`.
- **Command Support**: Registered the `/heartbeat` slash command with `on`, `off`, and `status` subcommands to allow remote configuration of the notification interval and target Discord channel.
- **In-Place Updates**: Designed the heartbeat messages to edit themselves in-place to keep the Discord channel clean.
- **Activity Tracking**: Integrated hooks into the message creation and interaction handlers to dynamically track when the last authorized operator activity occurred.
- **Test Automation**: Added unit tests in `tests/services/heartbeatService.test.ts` to verify duration formatting, interval parsing, and active service start/stop lifecycle behavior.
- **ADR Publication**: Added [ADR 0020](./0020-optional-heartbeat-notification.md) to document the heartbeat notification design decisions.
- **Fixes & Enhancements**: Added channel type constraints to registration, implemented SendMessages permission checks, and added full command interaction tests in `tests/bot.test.ts`.

---

## dev - Rebase Schedule Service Feature Branch

- **Submodule Rebase**: Cleaned up and rebased the `feature/schedule-service` branch in `vendor/LazyGravity` onto `main`.
- **Cherry-Pick & Merge**: Cherry-picked and merged the core schedule-service baseline commit (`5c8ff76`) to resolve slash commands, DB initialization, and registration.
- **Clear Command**: Added the `/schedule clear` subcommand to clear all scheduled tasks in memory and SQLite, resetting the autoincrement sequence back to 0.
- **Backup and Restore Commands**: Added `/schedule backup` to export all schedules as a portable JSON file attachment, and `/schedule restore` to upload and import schedules, running inside an SQLite transaction and resetting crons in memory.
- **Queue Serialization**: Centralized `WorkspaceQueue` instantiation in `src/bot/index.ts` and shared it with `src/events/messageCreateHandler.ts` and the scheduler callback, ensuring scheduled prompts and user prompts execute serially per workspace path.
- **Next-Run Time Calculation**: Integrated `cron-parser` dependency and updated `/schedule list` and `/schedule add` outputs to show next localized run times.
- **Path Resolution Fix**: Resolved a path comparison bug in `scheduleJobCallback` by converting relative binding paths to absolute paths and comparing them case-insensitively, correcting the mismatch where the binding repo stored relative paths while the scheduler record stored absolute paths.
- **ADR Publication**: Added [ADR 0019](./0019-wire-lazy-scheduler-discord.md) to document the design.
- **Verification**: Built the TS compiler successfully and verified that all 1,497 tests pass cleanly.

---

## v2.4.12 - Code-Quality and Validation Improvements

- **Submodule Fix**: Exposed `getBrainBasePath()` public getter on `ArtifactService` and aligned RegExp escaping of workspace filters to reuse `cdpService`'s literal pattern, preventing errors on special folder names.
- **Submodule Fix**: Balanced curly braces in the browser template context `WORKSPACE_STATE_SCRIPT` of `cdpService.ts` to ensure it always evaluates properly.
- **Submodule Fix**: Restored the `opts.hasOpenButton !== false` check inside `notificationSender.ts`.
- **Submodule Fix**: Made `showModal` optional on the platform interface, removing Telegram's throwing stub, and updated Discord's wrapper `deferUpdate()` to check `interaction.isFromMessage()`.
- **Submodule Fix**: Checked `channelId` and early-responded if missing in `genericActionButtonAction.ts` and forwarded channel-specific resolved account names to `getConnected()`.
- **Submodule Fix**: Checked `interaction.showModal` capability in `planningButtonAction.ts` and caught modal failures, falling back to open button clicking.
- **Submodule Fix**: Localized failure comment message via `t(...)` in `planningModalSubmitAction.ts`.
- **Submodule Fix**: Fixed inverted success/error branching in `interactionCreateHandler.ts`'s CLI-open execution callback.
- **Submodule Fix**: Added `earlyConvIdInFlight` guard and gated the `1000ms` completion delay in `bot/index.ts`.
- **Submodule Fix**: Caching `/json/list` targets inside `doctor.ts` to eliminate duplicate HTTP requests.
- **Submodule Fix**: Corrected comment documentation in `fileOpenCache.ts`.
- **Submodule Test**: Added unit tests to `genericActionButtonAction.test.ts` and `planningButtonAction.test.ts`, and updated `promptDispatcher.test.ts` to mock distinct monitors.
- **Safeguard Customization**: Created a workspace custom skill in `.agents/skills/safeguard-testing/SKILL.md` to define safe testing behaviors.
- **Documentation**: Streamlined `readme.md` instructions and updated testing guidance to recommend `./run.sh test`.

---

## v2.4.11 - De-duplicate Prompt Monitoring Loops

- **Submodule Fix**: Prevented duplicate final outputs on Discord by tracking and de-duplicating active prompt monitoring loops. Added `activeMonitors` tracking to `PromptDispatcher` and supported `onMonitorCreated` to abort/stop previous active monitors on the same channel when a new prompt or resume action is triggered.
- **Submodule Test**: Added unit tests in `tests/services/promptDispatcher.test.ts` to verify monitor de-duplication and cancellation behavior.
- **ADR Publication**: Added [ADR 0018](./0018-de-duplicate-active-prompt-monitors.md) to document the solution.

---

## v2.4.10 - Walkthrough Reviews on Approval Dialogs

- **Submodule Feature**: Live response updates when paused. Added listener for `approval_required` event inside `bot/index.ts` to push the response text generated so far using `upsertLiveResponseEmbeds` when the IDE is waiting for user approvals.
- **Submodule Feature**: Walkthrough & task reviews on approval embeds. Updated `cdpBridgeManager.ts` to query active conversation artifacts and pass custom IDs for `walkthrough.md` and `task.md` to `buildApprovalNotification`.
- **Submodule Feature**: Appended a second row of review buttons directly on the `Approval Required` notification message in `notificationSender.ts`.
- **Submodule Test**: Added unit tests to `notificationSender.test.ts` to verify the new two-row buttons layout.

---

## v2.4.9 - Fix Brain Path Mismatch, Inactivity Prompts, and Workspace Isolation Loop

- **Submodule Fix**: Dynamically resolve the brain base path by checking `.gemini/antigravity-ide/brain` first, and falling back to `.gemini/antigravity/brain`. This aligns the Discord bot with the actual directory used by Antigravity IDE on Windows.
- **Submodule Fix**: Upgraded workspace regex path isolation to ignore `.gemini`, `brain`, or `antigravity` path segments, preventing feedback loops when coding assistant diagnostic commands are run.
- **Submodule Fix**: Added regex test for `Working.` status to prevent premature completion triggers during command execution approvals.
- **ADR Publication**: Added [ADR 0017](./0017-fix-brain-path-and-activity-detection.md) to record the fixes.

---

## v2.4.8 - Fix Artifact Directory Path Resolution

- **Submodule Fix**: Fixed artifact directory path resolution in the file opening interaction handler. Instead of incorrectly joining `workspaceBaseDir` with `.gemini/antigravity/brain` (which produced path mismatches like `C:\Users\dgomez\code\i\.gemini\...`), it now queries the `ArtifactService` instance's `listArtifacts()` method to resolve absolute paths, falling back to the standard home directory `os.homedir()` brain path. This ensures artifact review buttons resolve successfully on Windows without throwing `ENOENT`.
- **Submodule Feature**: Prevented showing review buttons for stale `walkthrough.md` and `task.md` files during the planning phase. The bot now compares their filesystem modification timestamps (`mtimeMs` via `fs.statSync()`) against `implementation_plan.md`; if the plan's file write time is newer than or equal to the task/walkthrough, those buttons are suppressed.
- **Submodule Fix**: Made `isReviewBtn` detection robust by checking the `art:` customId prefix and file endings, preventing review buttons from falling back to IDE-opening CLI calls if the interaction's component label is missing or undefined.
- **Submodule Fix**: Restricted the `getLatestConversationWithArtifacts` fallback search and `findConversationByTitle` lookup to the channel's active workspace folder using a precise path segment RegExp match (e.g. `[\/\\]test(?:[\/\\]|$)`). This prevents the Discord bot from matching unrelated IDE agent conversations that contain generic words (like "test") in their path or text.
- **Submodule Fix**: Updated `getLatestConversationWithArtifacts` workspace filtering logic to strictly return the most recent conversation in the filtered workspace. If the latest conversation in that workspace does not have any artifacts (which happens when a new execution run starts and has not yet generated its final artifacts), it returns `null` instead of falling back to older completed conversations in that workspace. This completely prevents displaying stale walkthrough/task buttons from past completed runs during active or paused execution states.
- **Submodule Fix**: Switched timestamp comparison from the mutable `.metadata.json`'s `updatedAt` field to the actual operating system filesystem modification time (`mtimeMs`) for all artifact fresh/stale checks, making the check completely immune to missing or static metadata fields.

---

## v2.4.7 - Non-Expiring File & Artifact Review Buttons

- **Submodule Feature**: Implemented non-expiring `customId` formats for file open buttons (e.g. `file_open:rel:<relativePath>` and `file_open:art:<conversationId>:<filename>`). This allows the bot to resolve files on-the-fly dynamically without relying on the ephemeral in-memory cache, ensuring buttons in Discord history never expire across bot restarts or cache eviction.
- **Submodule Feature**: Bypassed workspace checks when opening artifacts. Since artifacts reside outside the project workspace in the user's brain directory, they can now be opened and reviewed even if the channel has no active workspace binding.
- **Submodule Test**: Added unit tests to verify absolute resolution and bypassed workspace checks for relative paths and artifacts in `tests/events/interactionCreateHandler.question.test.ts`.

---

## v2.4.6 - Review task.md Button & Regression Tests

- **Submodule Feature**: Updated artifact check loop in `bot/index.ts` to automatically include `task.md` and `walkthrough.md` as cited files if they exist in the conversation artifacts, rendering green "Review task.md" and "Review walkthrough.md" buttons in the final Discord response even if they are not explicitly mentioned in the text.
- **Submodule Test**: Added a new unit test suite in `tests/events/interactionCreateHandler.question.test.ts` to verify that question select and skip actions resume monitoring correctly via `promptDispatcher.resume()`.

---

## v2.4.5 - Question Modal Resume Monitoring

- **Submodule Fix**: Extended `createQuestionSelectAction` in `src/handlers/questionSelectAction.ts` and `createQuestionSkipAction` in `src/handlers/questionSkipAction.ts` to return the execution success status boolean.
- **Submodule Fix**: Updated `events/interactionCreateHandler.ts` to capture the return value of question select/skip actions and invoke `promptDispatcher.resume()` on success. This ensures Discord immediately resumes session monitoring after multiple-choice questions or modal questions are submitted or skipped, preventing the bot from remaining stuck on `IDE is working on the response...` and allowing the final walkthroughs, task lists, and review buttons to render properly.

---

## v2.4.4 - webview Iframe context Resolution & Artifact Detection Fallback

- **Submodule Fix**: Updated `chatSessionService.ts` and `cdpBridgeManager.ts` in `vendor/LazyGravity` to fallback to `document.body` when evaluating DOM state inside same-origin webview iframes. This resolves the bug where `activeConversationId` was null because `.antigravity-agent-side-panel` was unreachable from the iframe context.
- **Submodule Fix**: Added fallback in `bot/index.ts` to `getLatestConversationWithArtifacts()` when `activeConversationId` is not resolved via title matching. This ensures the correct active conversation folder in the brain directory is located, and its associated artifacts (like `walkthrough.md` and `task.md`) are successfully resolved for review button creation.
- **Submodule Fix**: Updated `events/interactionCreateHandler.ts` to call `promptDispatcher.resume` when the "Allow" or "Allow Chat" buttons on the `Approval Required` notification are accepted. This ensures that Discord resumes monitoring the chat session after file approval, allowing it to capture and post the final output and review buttons for walkthroughs/tasks.

---

## v2.4.3 - Support IDE Accept All Custom Elements

- **Submodule Fix**: Updated `approvalDetector.ts` in `vendor/LazyGravity` to detect custom DOM elements (`span.cursor-pointer` and `div.cursor-pointer`) in `buildClickScript` and dropdown selectors, resolving the bug where Discord's "Allow" button failed to click the IDE's "Accept all" action.

---

## v2.4.2 - Add npm Test Support to Launcher

- **Launcher Feature**: Updated the `test` command in `run.sh` to execute the npm test suite in the `vendor/LazyGravity` submodule in addition to the Python test suite.
- **ADR Publication**: Added [ADR 0016](./0016-add-npm-test-support.md) to record the addition of the npm test support to the launcher.

---

## v2.4.1 - Add Test Command to Launcher

- **Launcher Feature**: Added a `test` command to `run.sh` to execute the Python test suite via `uv run pytest`.
- **ADR Publication**: Added [ADR 0015](./0015-add-test-command-to-launcher.md) to record the addition of the test command to the core launcher.

---

## v2.4.0 - Structured Discord Rendering & Attachments

- **Submodule Feature**: Added structured DOM extraction for Antigravity 2.0 to properly identify plan cards, file changes, and action buttons.
- **Submodule Feature**: Implemented a native Discord renderer to parse extracted Antigravity responses into rich Discord Embeds, avoiding flattened markdown clutter.
- **Submodule Feature**: Supported Discord message replies by dynamically prepending the replied-to message content into the prompt context for the LLM.
- **Submodule Feature**: Supported Discord text attachments (under 50KB), fetching and injecting their contents into the prompt.
- **ADR Publication**: Added [ADR 0007](./0007-structured-discord-rendering.md) to record the switch from regex extraction to structured DOM extraction and Discord Rendering.

---

## v2.3.9 - Strict Cross-Project Artifact Isolation & Stable Duplicate Detection

- **Bug Fix**: Fixed duplicate Discord events caused by rapidly toggling Proceed/Review button text. `planningDetector` now deduplicates events via a hash of the underlying plan contents instead of button text.
- **Security Fix**: Upgraded `ArtifactService` to read the modern `.system_generated/logs/transcript.jsonl` file to perform strict string-matching on the workspace directory path, strictly preventing artifacts from completely unrelated projects from bleeding into the current Discord context (see [ADR 0014](./0014-prevent-artifact-cross-project-pollution.md)).

---

## v2.3.8 - Duplicate Message Prevention (Debounced Polling)

- **Bug Fix**: Implemented debounce resolution logic in all CDP detectors in `vendor/LazyGravity` to completely prevent duplicate Discord messages caused by UI flicker or momentary re-renders (see [ADR 0013](./0013-debounced-cdp-detector-polling.md)).

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
