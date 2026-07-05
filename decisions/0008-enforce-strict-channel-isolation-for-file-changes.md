# 8. Enforce Strict Channel Isolation for File Changes

Date: 2026-07-01

## Status

Accepted

## Context

During a security review, it was discovered that file change inspections and commands could cross project boundaries. While interaction handlers for features like `ApprovalDetector` and `RunCommandDetector` securely validated that the originating Discord `channelId` matched the active project's bindings, the `fileChangeButtonAction` relied on legacy matching (`ide_file_accept_all` / `ide_file_reject_all`) that lacked `channelId` verification. This allowed file change approval actions from one project's Discord channel to unintentionally apply to the file change dialog of a different active Antigravity project.

## Decision

We will standardize and enforce strict channel isolation across all interaction handlers:
1.  Update `fileChangeButtonAction.ts` to parse composite custom IDs using `parseFileChangeCustomId` (e.g., `file_change_accept:projectName:channelId`).
2.  Enforce strict `channelId` bounds matching in the button execution block, identically to other securely routed interactions.
3.  Add dedicated security tests in `fileChangeButtonAction.test.ts` to verify cross-channel requests are blocked.

## Consequences

-   **Security**: Prevents unauthorized cross-project file inspection and execution, securing multi-workspace operations from command bleeding.
-   **Consistency**: All CDP actions (Run, Planning, Error Popups, and File Changes) now uniformly respect the channel isolation guarantees.
-   **Testing**: Test robustness is increased to detect regressions of cross-channel bleeding.
