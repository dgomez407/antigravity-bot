# 0010. Custom Channel Naming for /new Command

## Context
When users create a new chat session using the `/new` slash command, the Discord channel is automatically named sequentially (e.g., `session-1`, `session-2`). The IDE's conversation title starts as "Untitled" until the first message is sent, after which Antigravity's backend automatically renames it (and then LazyGravity synchronizes this to the Discord channel).
Users requested the ability to specify a custom name during creation using an optional argument in the `/new` command, and that this custom name should be reflected in the chat conversation within the IDE as well.

## Decision
1. **Slash Command Update**: Added an optional `name` string argument to the `/new` slash command definition.
2. **Channel Creation**: If a custom name is provided, the Discord channel is immediately created as `session-<number>-<sanitized-name>`.
3. **Database State**: The custom name is set as the `displayName` for the channel in `ChatSessionRepository` and `is_renamed` is set to `true`. This prevents the `autoRenameChannel` background process from later overriding the Discord channel name when the first prompt is sent.
4. **IDE DOM Injection**: Since Antigravity does not expose a native API for renaming conversations programmatically before a prompt is sent, `ChatSessionService.renameCurrentChatInUI` was introduced to safely inject a script into the Antigravity frontend (via CDP `Runtime.evaluate`) that updates the conversation title directly in the DOM. This gives the user an immediate visual cue that the IDE conversation matches the Discord channel.

## Status
Accepted.

## Consequences
* **Positive**: Users have more control over project organization. 
* **Positive**: Aligning the IDE's visual state with the Discord channel reduces cognitive dissonance.
* **Negative/Risk**: The IDE DOM update is cosmetic. Antigravity's internal state machine might still run its auto-rename logic after the first prompt, potentially overwriting the DOM title locally. However, since Discord is the primary interface for our users and its title is frozen via `is_renamed`, this inconsistency is isolated to the local IDE window, which is deemed acceptable for this feature.
