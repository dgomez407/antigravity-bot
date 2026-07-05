# 0007: Secure Workspace Interaction Routing

## Context and Problem Statement
Interactive UI components (such as "Accept all" and "Reject all" buttons, question dropdowns, and file modification modals) originating from the Discord IDE integration were relying on a global `lastActiveWorkspace` variable to route their actions. This global variable was updated upon every user message, causing severe cross-project contamination. Commands executed or file inspections would bleed across project folders from Discord channels that were supposedly tied to specific project sessions. This was a critical security and isolation concern, as the Discord control plane failed to maintain strict workspace boundaries.

## Decision
We completely eliminated the global `lastActiveWorkspace` fallback from all interactive Discord components. The Discord bot's `interactionCreateHandler` and individual action handlers (`approvalButtonAction`, `fileChangeButtonAction`, `errorPopupButtonAction`, `planningButtonAction`, `runCommandButtonAction`, `questionSelectAction`) now strictly resolve the target workspace by looking up the Discord `channel.id` via the injected `WorkspaceCommandHandler` dependency (`getWorkspaceForChannel`). If a project cannot be resolved for a given channel, interactive elements fail safely, preventing arbitrary actions on unrelated workspaces.

## Consequences
- **Absolute Session Isolation**: Discord interactions are strictly routed to the workspace currently bound to the channel, preventing UI leakage and unsafe cross-workspace command execution.
- **Improved Testing Resiliency**: Unit tests for interaction handlers have been updated to explicitly mock and assert `wsHandler.getWorkspaceForChannel` behavior, eliminating state-based testing flakiness related to the global `lastActiveWorkspace`.
