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
- independent N/N daily check-ins (2–5), count goals (1–100), and time goals (five-minute steps)
- 7/30-day consistency insights for fixed schedules, respecting skipped and paused days
- user-controlled JSON backup export and validated merge/replace import
- optional local-only named groups (backed up in JSON)
- Spanish iOS + Watch + widget + Shortcuts localization (published in 1.3)
- per-habit rolling local reminders with Complete / Skip notification actions
- RU + EN localization and accessibility-oriented layouts
- Home Screen / Lock Screen interactive widgets
- Apple Watch app + complications
- low-latency iPhone ↔ Apple Watch sync with durable offline reconciliation
- private-CloudKit-ready persistence with local fallback; multi-device CloudKit is monitored post-release and does not block V1
- Siri / Shortcuts intents for complete and undo
- simulator regression, UI tests, release hygiene and archive smoke tooling

## Release validation baseline

The signed release candidate is validated on the approved physical iPhone + Apple Watch pair: reminder delivery, foreground/background Watch sync, disconnect/reconnect convergence, VoiceOver/Dynamic Type and App Group provisioning are green. Private multi-device CloudKit convergence is not a V1 release blocker and will be monitored post-release.

Canonical plan: [ROADMAP.md](ROADMAP.md).

Sync design: [SYNC_DESIGN.md](SYNC_DESIGN.md).


## 1.3 published release and post-release validation

The former branch `feature/chickmark-multicheck` has been integrated into canonical `main`; version 1.3.0 (build 5) is now **published, owner-confirmed 2026-10-11**. Legacy recurrence, CloudKit schema, Watch and widget identities remain unchanged. New count/duration modes store a stable step count using the published habit and check-in models. Post-release device/cloud persistence, offline reconciliation and ad/privacy checks remain tracked in [ROADMAP.md](ROADMAP.md). Details: [ROADMAP.md](ROADMAP.md).

## 1.3.1 candidate (not published)

After the Arvectum Tools Core refactor, the next patch release adds a compact ChickMark + Arvectum identity header, a dynamic version label, and links to the localized product website. The version is synchronized across iPhone, Watch and widgets; see [release checklist](app-store/metadata/release-checklist-1.3.1.md). Public release still requires App Store Connect metadata and owner approval.
