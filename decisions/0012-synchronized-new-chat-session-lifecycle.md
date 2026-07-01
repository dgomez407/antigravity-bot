# 0012. Synchronized New Chat Session Lifecycle

## Context
When users executed the `/new` slash command in Discord, LazyGravity successfully created a new Discord channel. However, it did not explicitly command the Antigravity IDE to start a new chat session. The user's active page in the IDE would remain pointing to the old chat session, causing confusion and a disjointed experience where Discord and the IDE were out of sync.

## Decision
1. **CDP UI Automation**: Added `startNewChat` to `ChatSessionService` which uses CDP `Input.dispatchMouseEvent` to locate and click the "New Chat" button (identified by `[data-tooltip-id="new-conversation-tooltip"]`) in the Antigravity UI.
2. **Command Handler Integration**: Updated `ChatCommandHandler.handleNew` to invoke `startNewChat` immediately when the `/new` command is run. This ensures the IDE flips to a fresh session context exactly when the Discord channel is born.

## Status
Accepted.

## Consequences
* **Positive**: The IDE's active page now stays perfectly synchronized with Discord channel creation.
* **Risk**: High reliance on exact DOM coordinates and class structures in Antigravity. If the "New Chat" button moves or changes its `data-tooltip-id`, the CDP click logic will break. 
