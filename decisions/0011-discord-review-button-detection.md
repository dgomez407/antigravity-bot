# 0011. Discord Review Button Detection

## Context
When Antigravity generates an implementation plan (planning mode) and stops to wait for user approval, it displays a button labeled "Review" or "Proceed" depending on the IDE version and state. 
LazyGravity previously failed to detect the "Review" label, causing the interactive button to not appear in Discord. This left Discord users without a way to approve plans, stalling the automation workflow.

## Decision
1. **Detection Expansion**: Updated `PROCEED_PATTERNS` in `src/services/responseMonitor.ts` to include the `review` string.
2. **Dynamic Label Propagation**: Updated `cdpBridgeManager.ts` and `notificationSender.ts` to extract the actual button text from the DOM and dynamically propagate it to the Discord button label, instead of hardcoding "Proceed".

## Status
Accepted.

## Consequences
* **Positive**: Full support for planning mode workflows directly from Discord.
* **Positive**: Button labels now accurately reflect the IDE state.
