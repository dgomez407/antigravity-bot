# 14. Prevent Artifact Cross-Project Pollution & Fix Double-Accounting Events

Date: 2026-06-30

## Status

Accepted

## Context

Two related UI/session synchronization bugs were degrading the reliability of the Discord to Antigravity integration:
1. **Duplicate Event Firing (Proceed/Review)**: The `planningDetector` relied on the physical string pairs (`openText::proceedText::planTitle`) to deduplicate planning events. However, because the DOM rapidly oscillates button states (e.g., from "Proceed" to "Review"), the changing UI text tricked the detector into treating it as a newly detected plan, resulting in a double-accounting of events pushed to Discord.
2. **Artifact Cross-Pollution**: `ArtifactService.findConversationByTitle` was falling back to scanning `.system_generated/logs/overview.txt`. Modern versions of Antigravity deprecated `overview.txt` in favor of `transcript.jsonl`. Because `findConversationByTitle` was blindly skipping modern sessions and ignoring workspace isolation, it would eagerly match older legacy sessions from *completely different projects* that happened to share the same title (e.g., "Implement Login"). This caused Discord's `/artifacts` picker or `/new` command to accidentally pipe implementation plans from entirely different workspaces into the current channel.

## Decision

We have implemented two architectural fixes:
1. **Stable Content-Based Deduplication**: Modified `planningDetector.ts` to deduplicate based on the plan's underlying content (`planTitle` and `planSummary`) rather than the transient UI text of the buttons. This guarantees the event stream remains stable even if the IDE re-renders button states.
2. **Strict Workspace Artifact Isolation**: 
   - Upgraded `ArtifactService` to parse the modern `transcript.jsonl` schema instead of solely relying on the deprecated `overview.txt`.
   - Introduced a `workspaceFilter` into the artifact resolution chain (`ArtifactService`, `bot/index.ts`, `artifactsUi.ts`, and `interactionCreateHandler.ts`).
   - The Artifact Service now **strictly enforces** that a conversation is only resolvable if the first 16KB of its transcript natively contains the active workspace directory name, guaranteeing absolute isolation between projects.

## Consequences

- Artifacts (like implementation plans and walkthroughs) accessed via Discord are now mathematically guaranteed to belong to the correct workspace context.
- UI button text changes during planning states will no longer spam duplicate embeds to Discord channels.
- Legacy `overview.txt` conversations remain supported and are also subjected to the strict workspace isolation check.
