# ChickMark P2 — opt-in local weekly summary, 2026-10-16

Source-only implementation for [issue #80](https://github.com/arvectum2/arvectum-tools/issues/80). No new App Store binaries or HealthKit permissions requested.

## Policy and metrics

- Off by default; in Manage Habits → Weekly summary, the user can turn on the fully local view. No notification scheduling, accounts, analytics, ad attribution, CloudKit sync, backup entries or stored projections.
- Last **fully completed calendar week** and the one before, excluding the current incomplete week. Respect Gregorian/locale start-of-week and daylight-saving calendar days, never hard-code 7×86400 seconds.
- **Scheduled habits:** number of fully completed days out of eligible scheduled days. Skipped/paused days and days before habit creation are neutral, not scored as misses.
- **Flexible weekly habits:** evaluate each completed week against its effective target **once**, not against seven made-up daily obligations. A whole neutral week has no eligible weekly target.
- **Completion-relative habits:** count actual completed occurrences; do not fabricate overdue-day percentages.
- **Multi/quantity/duration:** count a day completed only once the configured target is met; duplicate records on the same day must not count as extra habit-days.
- Activity counts complete habit-days across supported modes, best day shows highest number completed (earliest day breaks ties), comparison is absolute change vs the preceding completed week, **not a completion percentage**.
- Archived and future-created habits are excluded. **Health-linked habits are excluded by design for now**: historic automatic HealthKit checkoffs cannot be reconstructed correctly from manual SwiftData history. The view explains this limitation instead of misreporting missed days.
- Read-only projection over existing Habit / CheckIn / Skip / Pause models. No schema migration, no new persistent check-ins, no HealthKit read or write, no Watch/widget code change. Local opt-in preference only in UserDefaults.

## Verification

- [x] **Xcode 27 iOS simulator build PASS** and generic watchOS Simulator build PASS. Signed Apple distribution/App Store release NOT attempted.
- [x] **8/8 targeted XCTest PASS:** no history; skipped/paused neutral; flexible weekly goals; completion-relative occurrences; partial multi-check; archived/future-created habits; DST fall-back; previous-week comparison and best-day tie.
- [x] **230/230 complete iOS XCTest PASS** and **1/1 focused weekly opt-in UI PASS** on isolated fresh iOS 27 Simulator; the disposable simulator was shut down and deleted, real user data untouched.
- [x] RU/EN/ES localization, architecture, shared Swift dependency catalog, release hygiene, all 12 App Store PNG assets and git diff check PASS.
- [x] GitHub [PR #81](https://github.com/arvectum2/arvectum-tools/pull/81) **MERGED** at `9159e1b012ca314c53034da24abd6cee375b6c1b`, with two independent GitHub Habits iOS CI checks [push 38861433076](https://github.com/arvectum2/arvectum-tools/actions/runs/38861433076) SUCCESS (13m55s) and [PR 38861470827](https://github.com/arvectum2/arvectum-tools/actions/runs/38861470827) SUCCESS (15m5s); full iOS unit, system UI-smoke, archive, architecture and catalog PASS. GitVerse mirror workflow SUCCESS; GitHub/GitVerse `main` both exact `9159e1b...`.
- [ ] **OPEN [physical acceptance #82](https://github.com/arvectum2/arvectum-tools/issues/82):** non-destructive opt-in and accessibility check with disposable demo habits before later release. Do not delete or reset user history or modify genuine Apple Health permissions.

**Release distinction:** Apple-approved public ChickMark **1.4.1(15) READY_FOR_SALE** stays unchanged; the older signed A5 **1.4.2(16) RC remains not submitted**. This source-only P2 feature requires a separately versioned binary after acceptance. The opt-in HealthKit dietaryWater writer remains a separate [issue #79](https://github.com/arvectum2/arvectum-tools/issues/79).
