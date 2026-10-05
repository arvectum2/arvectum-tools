# ChickMark

A simple, local-first habit tracker in the Arvectum Tools family.

## Product rule

Keep the useful habit-tracking mechanics and remove setup friction and feature clutter. A user should be able to create a habit quickly, make a daily **Chick-in** in one tap, and understand progress at a glance.

Working formula: **«всё удобное — без лишнего»**.

## Current implementation

- iOS 17+ / SwiftUI / SwiftData
- local-first operation with explicit schema migration and safe storage recovery
- daily, selected-weekday, flexible N-times-per-week and completion-relative interval habits
- one-tap completion, undo, neutral skip, pause/resume and manual ordering
- streaks, best streak, scheduled-day completion metrics and calendar-aligned history
- per-habit rolling local reminders with Complete / Skip notification actions
- RU + EN localization and accessibility-oriented layouts
- Home Screen / Lock Screen interactive widgets
- Apple Watch app + complications
- low-latency iPhone ↔ Apple Watch sync with durable offline reconciliation
- private-CloudKit-ready persistence with local fallback; multi-device CloudKit is monitored post-release and does not block V1
- Siri / Shortcuts intents for complete and undo
- simulator regression, UI tests, release hygiene and archive smoke tooling

## Current gate

The signed release candidate is validated on the approved physical iPhone + Apple Watch pair: reminder delivery, foreground/background Watch sync, disconnect/reconnect convergence, VoiceOver/Dynamic Type and App Group provisioning are green. Private multi-device CloudKit convergence is not a V1 release blocker and will be monitored post-release.

Canonical plan: [ROADMAP.md](ROADMAP.md).

Sync design: [SYNC_DESIGN.md](SYNC_DESIGN.md).
