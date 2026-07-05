# Wiring LazyGravity Scheduler to Discord Slash Commands

Plan to integrate the existing backend scheduler service (`ScheduleService` and `ScheduleRepository`) with Discord slash commands (`/schedule add`, `/schedule list`, `/schedule remove`).

## User Review Required

> [!IMPORTANT]
> **Submodule Fork Workflow**:
> According to project guidelines in `AGENTS.md`, modifications inside `vendor/LazyGravity` must be done on the isolated `integration/*` branch of the submodule mirror. We will create and switch to that branch before making submodule modifications.

> [!WARNING]
> **Workspace Concurrency Gating**:
> If a scheduled cron job fires on a workspace while a user is actively running a prompt on that same workspace, the prompts will collide and corrupt the active IDE tab state.
> We propose moving the local per-workspace task queues from `messageCreateHandler.ts` to `bot/index.ts` so that both user prompts and scheduled tasks serialize cleanly on the same project workspace queue.

## Open Questions

> [!NOTE]
> **Preferred Account Selection**:
> When a scheduled task executes, it runs without user presence. We plan to resolve the account to use for CDP debugging in the following order:
> 1. The preferred account for the workspace: `bridge.pool.getPreferredAccountForWorkspace(workspacePath)`.
> 2. The account bound to the channel: `chatSessionRepo.findByChannelId(channelId).activeAccountName`.
> 3. The fallback default account: `default`.
> Is this priority list aligned with your expectations?

## Proposed Changes

### LazyGravity Submodule Core
---

#### [MODIFY] [package.json](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/package.json)
- Add `cron-parser` (version `^4.9.0` or similar) to `dependencies` and `@types/cron-parser` to `devDependencies` to calculate next run times for the `/schedule list` command.

#### [MODIFY] [registerSlashCommands.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/commands/registerSlashCommands.ts)
- Define `scheduleCommand` using `SlashCommandBuilder` with three subcommands:
  - `list`: Show all scheduled tasks with next-run times.
  - `add`: Register a recurring task. Takes options `cron` (required string) and `prompt` (required string).
  - `remove`: Delete a scheduled task. Takes option `id` (required integer).
- Add `scheduleCommand` to the `slashCommands` registration array.

#### [MODIFY] [index.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/bot/index.ts)
- Import `cronParser` from `cron-parser`.
- Import `ScheduleRepository` and `ScheduleService` classes.
- Centralize `workspaceQueues` and `enqueueForWorkspace` from `messageCreateHandler.ts` to `bot/index.ts` so they can be shared between the text message handler and the scheduler handler.
- Instantiate `ScheduleRepository` and `ScheduleService` inside `startBot`.
- Pass `scheduleService` as part of the dependencies object when calling `createInteractionCreateHandler`.
- Implement `executeScheduledTask(schedule)` job callback in `startBot`:
  - Locate the Discord channel bound to the workspace path via `workspaceBindingRepo`.
  - Construct a mock `Message` object using the channel reference.
  - Resolve the CDP session account (with workspace-preferred account priority).
  - Gated by `enqueueForWorkspace` to serialize execution and prevent collisions.
  - Send startup notification embed, then execute prompt via `sendPromptToAntigravity`.
- Inside `client.once(Events.ClientReady)`, trigger `scheduleService.restoreAll(executeScheduledTask)` to restore schedules once the Discord client is fully ready.
- Add `case 'schedule'` to the slash commands switch in `handleSlashInteraction`:
  - `list`: Retrieve all schedules, format and display them (calculating next run time via `cronParser.parseExpression`).
  - `add`: Retrieve current channel's workspace path; if bound, call `scheduleService.addSchedule` passing `executeScheduledTask` callback and show success embed.
  - `remove`: Extract ID option, invoke `scheduleService.removeSchedule`, and report status.

#### [MODIFY] [interactionCreateHandler.ts](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/events/interactionCreateHandler.ts)
- Ensure the types and arguments map correctly to include `scheduleService` in `InteractionCreateHandlerDeps` and pass it to `handleSlashInteraction`.

### Local Repository Control Plane
---

#### [NEW] [0019-wire-lazy-scheduler-discord.md](file:///c:/Users/dgomez/code/i/antigravity-bot/decisions/0019-wire-lazy-scheduler-discord.md)
- Create Architecture Decision Record documenting the wiring design of the scheduler to Discord slash commands and concurrency serialization.

#### [MODIFY] [release.md](file:///c:/Users/dgomez/code/i/antigravity-bot/decisions/release.md)
- Update release log to reference the new scheduler integration and ADR.

## Verification Plan

### Automated Tests
- Run unit tests to verify repository, service, and slash command parsing:
  ```bash
  npm run test
  ```
- Run integration tests to verify lifecycle behavior of process/session management:
  ```bash
  ./run.sh test
  ```

### Manual Verification
1. Boot the LazyGravity control plane:
   ```bash
   ./run.sh start
   ```
2. Open a Discord channel bound to a workspace.
3. Test command execution:
   - Run `/schedule add cron:"*/5 * * * *" prompt:"fix any syntax errors"`
   - Run `/schedule list` to verify it appears with correct next run times.
   - Wait for cron triggers to verify output posts correctly in the bound channel.
   - Run `/schedule remove id:<ID>` and check `/schedule list` to confirm removal.
