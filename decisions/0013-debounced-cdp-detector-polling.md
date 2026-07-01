# 13. Debounced CDP Detector Polling

Date: 2026-07-01

## Status
Accepted

## Context
When LazyGravity was interacting with the Antigravity UI, users were reporting duplicate messages in Discord channels. For instance, when the "Review" or "Proceed" button was clicked on a Planning mode dialog, Discord would send a second identical planning message (or multiple approval messages) after a short delay (e.g., 5 seconds).

Investigation revealed that the CDP polling detectors (`PlanningDetector`, `ApprovalDetector`, `ErrorPopupDetector`, etc.) were resetting their duplicate prevention state (`lastDetectedKey`) immediately whenever the target element disappeared from the DOM for even a single poll cycle (e.g., a momentary React re-render, transition, or flicker). 

When the element reappeared on the very next poll, it was considered a completely new event by the detector. The existing `COOLDOWN_MS` logic meant that the notification was queued until the 5-second cooldown elapsed, guaranteeing a delayed duplicate message rather than preventing it.

## Decision
We implemented a **debounce resolution** system in all CDP polling detectors. 

A detector must now observe the target element absent for a minimum number of consecutive polls (defined by `REQUIRED_EMPTY_POLLS = 3`) before considering the state "resolved" and clearing its deduplication cache (`lastDetectedKey`). 
Additionally, for `PlanningDetector`, the deduplication key was expanded to include `planTitle` so distinct plans are correctly identified even if they share the same button text.

## Consequences
- Duplicate messages caused by UI flickers and state transitions are completely eliminated.
- If an alert genuinely closes and another identical one appears within the debounce window (~6 seconds), it might not trigger a new notification. However, this scenario is exceedingly rare given the human-in-the-loop workflow speed.
- The change was isolated to the `vendor/LazyGravity` submodule and keeps the fix modular for a potential upstream pull request if desired.
