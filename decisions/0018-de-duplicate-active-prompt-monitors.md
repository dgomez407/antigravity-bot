# 18. De-duplicate Active Prompt Monitors

Date: 2026-07-04

## Status

Accepted

## Context

When LazyGravity runs a task, it monitors execution progress by launching a `ResponseMonitor` (which polls the active Playwright page). If the agent in the IDE pauses—for example, to request a planning review, ask a multiple-choice question, or obtain code approval—the bot displays a Discord interaction card containing buttons (like "Proceed", "Reject", "Accept all", or multiple-choice buttons).

When the user interacts with one of these buttons, the bot's interaction handler updates the state in the IDE and triggers `deps.promptDispatcher.resume(...)`. Because the resume command was dispatched asynchronously without checking if a loop was already active, each button click spawned a brand new `ResponseMonitor` polling loop. In complex multi-step tasks, this resulted in multiple duplicate `ResponseMonitor` loops running concurrently on the same CDP session. When the task eventually completed, all active loops detected the final output simultaneously, resulting in multiple duplicate "Final Output" message cards being posted to Discord (e.g., three duplicate outputs).

## Decision

We have implemented a session tracking and de-duplication mechanism:
1. **Active Monitor Registry in `PromptDispatcher`**: Added an `activeMonitors: Map<string, { stop: () => Promise<void> }>` registry inside the [PromptDispatcher](file:///c:/Users/dgomez/code/i/antigravity-bot/vendor/LazyGravity/src/services/promptDispatcher.ts) class, keyed by the Discord `channelId`.
2. **Monitor Registration Callback**: Updated `PromptDispatchOptions` to support an optional `onMonitorCreated` callback hook.
3. **Loop Cancellation**: In `PromptDispatcher._dispatch`, before launching a new prompt or resume session, we check if there is an active monitor registered for the channel. If so, we log the event and call `await existing.stop()` to cleanly abort the previous monitor and terminate its Playwright polling loop.
4. **Safe Termination Callback**: Inside `bot/index.ts`, when `ResponseMonitor` is initialized, we hook into `onMonitorCreated` and pass a wrapper stop function that marks `isFinalized = true` and stops the monitor. Setting `isFinalized = true` ensures that other intervals (like the 1-second elapsed timer) and pending callbacks are cleaned up immediately, preventing resource leaks.

## Consequences

- Only a single active `ResponseMonitor` polling loop can run per channel at any given time.
- Clicking Discord interaction buttons (e.g. "Proceed", "Option 0", "Accept all") during paused states will no longer leak parallel loops or result in multiple duplicate final output notifications.
- Memory and timer leak concerns are resolved because aborted monitors immediately mark their state as finalized, cleaning up internal timer loops.
