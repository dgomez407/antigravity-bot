# 20. Optional Heartbeat / Keep-Alive Notification

Date: 2026-07-06

## Status

Accepted

## Context

LazyGravity operates as a Discord control plane for a local installation of the Antigravity IDE on Windows. Because operators control the IDE remotely (e.g. from smartphones via Discord), they need a way to verify the health of the connection and the host PC without having to send active commands.
1. Host PCs may unexpectedly go to sleep, lose internet connection, or experience process crashes.
2. Passive status verification was previously not possible.
3. Sending periodic new status messages would quickly clutter the Discord channel history.

## Decision

We have implemented an optional, periodic heartbeat notification system with the following design:
1. **AppConfig Schema**: Extended `AppConfig` and `PersistedConfig` in `vendor/LazyGravity` to include `heartbeatEnabled`, `heartbeatIntervalMs`, `heartbeatChannelId`, and `heartbeatLastMessageId` properties.
2. **HeartbeatService**: Created a new `HeartbeatService` to handle state and scheduling. Uptime is computed based on bot start time. Active sessions count is fetched from the connected CDP pool.
3. **In-Place Updates**: Instead of sending a new message on every tick, the heartbeat service edits the previous status message in-place using the persisted `heartbeatLastMessageId`. If the message is deleted or not found, it sends a new message and updates the stored ID.
4. **Slash Command**: Registered the `/heartbeat` command in [registerSlashCommands.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/commands/registerSlashCommands.ts) with subcommands:
   - `on [interval] [channel]`: Starts the interval. Parses inputs (e.g., `1h`, `30m`) and defaults to hours if the unit is omitted.
   - `off`: Disables the heartbeat loop.
   - `status`: Displays config values, uptime, and last activity time.
5. **Activity Hooking**: Added `heartbeatService.recordActivity()` hooks to both the text message listener ([messageCreateHandler.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/events/messageCreateHandler.ts)) and the interaction listener ([interactionCreateHandler.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/events/interactionCreateHandler.ts)). This tracks when the last authorized operator activity occurred.

## Consequences

- Operators can remotely verify that the bot, IDE, and host PC are online and healthy.
- Channel history remains clean due to in-place message editing.
- Last activity and uptime details are passively visible.
