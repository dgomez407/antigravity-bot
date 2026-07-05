# 17. Fix Brain Path Mismatch, Inactivity Prompts, and Workspace Isolation Loop

Date: 2026-07-04

## Status

Accepted

## Context

Three issues affected the reliability of LazyGravity's session matching and lifecycle monitoring:
1. **Brain Path Mismatch**: The Discord bot was configured to search `.gemini/antigravity/brain`, but the Antigravity IDE writes active conversation folders to `.gemini/antigravity-ide/brain`. This mismatch prevented the bot from locating correct session folders, causing a fallback check to mistakenly pull artifacts from our coding assistant workspace instead.
2. **Premature Activity Completion**: When terminal command executions or CDP approvals are waiting, the IDE panel displays "Working." but stops printing message tokens. The response monitor would previously trigger an early completion.
3. **Workspace Isolation Loop**: The regex workspace filter matched any path in `transcript.jsonl` matching `/workspaceName/`. Because our coding assistant session ran diagnostics on other workspaces (e.g., `test`), the coding assistant transcript accumulated those paths, causing a feedback loop where our workspace folder matched the filter for the target workspace.

## Decision

We have implemented three fixes:
1. **Dynamic Brain Directory Resolution**: Upgraded the `ArtifactService` constructor to dynamically detect and use `.gemini/antigravity-ide/brain` if it exists on disk, defaulting back to `.gemini/antigravity/brain`.
2. **Exclude Meta-Paths from Workspace Matcher**: Updated the regex filter in `findConversationByTitle` and `getLatestConversationWithArtifacts` to ignore any paths containing `.gemini`, `brain`, or `antigravity`, preventing workspace isolation feedback loops.
3. **Active Status Preservation**: Added regex tests for `Working.` in the DOM panels inside `cdpService.ts`, `responseMonitor.ts`, and `questionDetector.ts` to block premature completions.

## Consequences

- Discord commands and notifications will correctly resolve and bind to the correct conversation directories inside `.gemini/antigravity-ide/brain`.
- Stale buttons from unrelated helper workspaces will no longer pollute Discord channels.
- Active sessions executing long-running or modal-awaiting processes will remain active until they fully complete.
