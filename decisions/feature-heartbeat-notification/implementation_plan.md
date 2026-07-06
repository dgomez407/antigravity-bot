# Implementation Plan - Optional Heartbeat / Keep-Alive Notification

This plan outlines the design and implementation details for adding an optional periodic heartbeat notification feature to the LazyGravity submodule. This will allow operators to verify the bot is still running when away from their PC by receiving periodic updates in a designated Discord channel.

---

## User Review Required

> [!NOTE]
> The heartbeat service needs to store the last heartbeat message ID to allow in-place updates. This implementation proposes saving it directly to `~/.lazy-gravity/config.json` via the existing `ConfigLoader.save` system. This keeps the configuration and state persistent without requiring database migrations.

---

## Open Questions

> [!IMPORTANT]
> **Default Heartbeat Interval:** If `/heartbeat on` is executed without specifying an interval option (e.g. `/heartbeat on`), what should the default interval be? We propose **1 hour** (`3600000` ms) as a sane default.

---

## Proposed Changes

We will modify and add files within the `vendor/LazyGravity` submodule.

### LazyGravity Submodule Configuration & Services

#### [MODIFY] [config.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/utils/config.ts)
- Add new properties to `AppConfig`:
  - `heartbeatEnabled: boolean;`
  - `heartbeatIntervalMs: number;`
  - `heartbeatChannelId?: string;`
  - `heartbeatLastMessageId?: string;`

#### [MODIFY] [configLoader.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/utils/configLoader.ts)
- Add new properties to `PersistedConfig`.
- Resolve these fields in `mergeConfig` from:
  1. Environment variables (`HEARTBEAT_ENABLED`, `HEARTBEAT_INTERVAL_MS`, `HEARTBEAT_CHANNEL_ID`, `HEARTBEAT_LAST_MESSAGE_ID`)
  2. Persisted config file (`~/.lazy-gravity/config.json`)
  3. Sane defaults (`heartbeatEnabled = false`, `heartbeatIntervalMs = 3600000`)

#### [NEW] [heartbeatService.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/services/heartbeatService.ts)
Create a new service `HeartbeatService` that:
- Maintains bot startup time (`botStartTime`).
- Tracks last activity timestamp (`lastActivityTimestamp`), updated whenever `recordActivity()` is called.
- Manages the periodic interval timer.
- Constructs the heartbeat embed containing:
  - Uptime (e.g., `2h 15m 30s`)
  - Active sessions count (`bridge.pool.getActiveWorkspaceNames().length`)
  - Last activity relative time (e.g., `5m ago`)
- Implements message updating: edits the previous message in-place using `heartbeatLastMessageId` if it exists and is valid; otherwise sends a new message and updates the persisted message ID.
- Exposes utility functions `parseInterval` (e.g. `1h` -> `3600000`, `30m` -> `1800000`), `formatDuration`, and `formatRelativeTime`.

---

### Command Registration & Hooking

#### [MODIFY] [registerSlashCommands.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/commands/registerSlashCommands.ts)
- Register the `/heartbeat` slash command with the following subcommands:
  - `/heartbeat on [interval] [channel]`: Enable heartbeats with an optional interval (default: `1h`) and optional channel (default: current channel).
  - `/heartbeat off`: Disable heartbeats.
  - `/heartbeat status`: Show current heartbeat status, interval, channel, and metrics.

#### [MODIFY] [messageCreateHandler.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/events/messageCreateHandler.ts)
- Add `heartbeatService?: HeartbeatService` to `MessageCreateHandlerDeps`.
- Add `'heartbeat'` to `slashOnlyCommands` array to ensure users are redirected to the slash command.
- Call `deps.heartbeatService?.recordActivity()` at the start of message handling if the message is from an allowed user.

#### [MODIFY] [interactionCreateHandler.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/events/interactionCreateHandler.ts)
- Add `heartbeatService?: HeartbeatService` to `InteractionCreateHandlerDeps`.
- Call `deps.heartbeatService?.recordActivity()` when any interaction is received from an allowed user.
- Pass `heartbeatService` to `handleSlashInteraction`.

#### [MODIFY] [index.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/bot/index.ts)
- Instantiate `HeartbeatService` in `startBot`.
- Initialize `heartbeatService` on the `Events.ClientReady` event (once `readyClient` and `bridge` are active) and start the loop.
- Pass `heartbeatService` to slash and message handlers.
- Add `'heartbeat'` case to `handleSlashInteraction` to process `/heartbeat on`, `/heartbeat off`, and `/heartbeat status`.

---

## Verification Plan

### Automated Tests
We will add a new test file under `vendor/LazyGravity/tests` to verify:
- Parsing intervals correctly (`1h` -> 3.6M, `30m` -> 1.8M, `6` -> 21.6M, etc.).
- Formatting uptime and relative durations.
- Heartbeat service starts and stops intervals correctly on config updates.

Commands:
- `cd vendor/LazyGravity && npm run test` to verify unit tests.
- `./run.sh test` to execute Python integration tests.

### Manual Verification
- Start the bot via `./run.sh start`.
- Run `/heartbeat status` to verify current configuration.
- Run `/heartbeat on interval:10s` to verify heartbeats are posted to the channel and edit in-place every 10 seconds.
- Verify that sending normal messages or running commands updates the "Last Activity" field of the heartbeat.
- Run `/heartbeat off` to verify the heartbeat loop terminates and is disabled.
