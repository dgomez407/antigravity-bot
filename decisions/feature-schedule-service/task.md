# Task Checklist: Wiring the Scheduler Feature

- [x] Merge baseline scheduler commit (`5c8ff76`) on `feature/schedule-service` branch in `vendor/LazyGravity` submodule
- [x] Install `cron-parser` package and add to dependencies
- [x] Centralize `WorkspaceQueue` instantiation at startBot level in `index.ts`
- [x] Refactor `messageCreateHandler.ts` to use the shared `WorkspaceQueue`
- [x] Wrap scheduled job callback executions in `workspaceQueue.enqueue` to serialize them and prevent collisions
- [x] Implement localized next run time calculation for `/schedule list` and `/schedule add` outputs
- [x] Ensure all 114 test suites (1,493 tests) build and pass cleanly
- [x] Write Architecture Decision Record [ADR 0019](file:///c:/Users/dgomez/code/i/antigravity-bot/decisions/0019-wire-lazy-scheduler-discord.md)
- [x] Update release log [release.md](file:///c:/Users/dgomez/code/i/antigravity-bot/decisions/release.md)
- [x] Create [walkthrough.md](file:///C:/Users/dgomez/.gemini/antigravity/brain/047cba12-a472-4f58-bccc-ffb9397453ea/walkthrough.md) artifact
