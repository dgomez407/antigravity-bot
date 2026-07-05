# 19. Wire Lazy Scheduler to Discord Slash Commands

Date: 2026-07-05

## Status

Accepted

## Context

The backend scheduler persistence (`ScheduleRepository` in SQLite) and cron execution service (`ScheduleService` via `node-cron`) were already implemented in the submodule. However, they were completely disconnected from the operator interface:
1. There were no Discord slash commands to add, list, or remove scheduled tasks.
2. The `ScheduleService` was not instantiated or restored on bot startup.
3. If a scheduled task fired, there was no wiring to resolve which Discord channel to notify, nor any mechanism to serialize execution to prevent browser tab control collisions in the IDE.

## Decision

We have wired and integrated the scheduler with the following design:
1. **Slash Commands**: Registered the `/schedule` slash command in [registerSlashCommands.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/commands/registerSlashCommands.ts) with subcommands `list`, `add <cron> <prompt>`, `remove <id>`, `clear`, `backup`, and `restore <file>`.
2. **Next-Run Time Calculation**: Integrated `cron-parser` to parse cron expressions and compute localized next run times dynamically. These next run times are shown in the `/schedule list` response and after successfully adding a new task.
3. **Delayed Restoration**: Gated the instantiation and task restoration of `ScheduleService` inside the Discord `ClientReady` event listener in [bot/index.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/bot/index.ts). This ensures the client is ready and connected to Discord before any scheduled jobs execute and send messages.
4. **Task Execution Serialization**:
   - Centralized the `WorkspaceQueue` instance at the `startBot` level.
   - Passed the shared `WorkspaceQueue` to both the user text message handler ([messageCreateHandler.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/events/messageCreateHandler.ts)) and the scheduler job execution callback.
   - Wrapped the scheduled task CDP connection and prompt dispatch inside `workspaceQueue.enqueue` to ensure that scheduled prompts and user prompts run serially on the same workspace, preventing tab control collisions.
5. **Session Routing & Account Resolution**: Resolves the Discord channel bound to the task's workspace via `workspaceBindingRepo` (converting relative binding paths to absolute paths and comparing them case-insensitively), constructs a mock `Message` wrapper, and resolves the preferred/scoped account to select the correct Antigravity CDP port.
6. **Backup and Restore**: Added `/schedule backup` to export all schedules as a portable JSON file attachment, and `/schedule restore` to upload a backup JSON file attachment, downloading and validating it, and updating the database within a transaction while stopping and restarting cron tasks in memory.

## Consequences

- Operators can schedule, inspect, and delete recurring natural language tasks directly from Discord.
- Task execution is safe and collision-free because scheduled runs share the same serialization lock/queue as user messages.
- Next execution times are clearly visible.
