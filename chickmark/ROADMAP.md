# ChickMark — Product Roadmap

**Updated:** 2026-10-12
**Status:** v1.3.0 (build 5) **published — owner-confirmed 2026-10-11**. Installed on paired physical iPhone 13 and Apple Watch SE, verified via CoreDevice app inventory 2026-10-11. Independent public App Store availability/rollout not re-verified in this audit.
**Authoritative feature evidence:** historical [ChickMark branch snapshot](docs/history/ROADMAP-chickmark-branch-2026-10-11.md) formerly from `feature/chickmark-multicheck`, now integrated into `main`; [earlier planning archive](docs/history/ROADMAP-legacy-2026-10-11.md).
**Shared rules:** [Core](../core/CORE_PRINCIPLES.md). **Promotion and ASO metrics:** [Growth](../growth/ROADMAP.md).

## Published baseline: 1.2
- [x] Local-first SwiftData habit tracking, daily check-off, scheduling and progress.
- [x] Apple Watch and widget integration; app-specific release checks.
- [x] One-off reminders with isolated local persistence.
- [x] First unobtrusive Today ad; keep published schema and 1.2 rollback compatibility.

## 1.3: published (owner-confirmed); physical acceptance remains ongoing
- [x] Multiple check-offs, incremental goals and extended statistics (implementation recorded in branch).
- [x] RU/EN/ES localized UI and localized store assets prepared.
- [x] Signed 1.3.0 (5) candidate and device installation recorded.
- [x] App Review submission recorded 2026-10-11.
- [x] Owner confirmed public release of 1.3.0 (5) on 2026-10-11; physical iPhone and Watch installed versions also match.
- [ ] Independently confirm store rollout in each intended region when relevant.
- [ ] Complete physical-device CloudKit/data-preservation, Watch offline reconciliation and ad/privacy QA evidence. No destructive migration or overwrite of published app.
- [ ] Verify branch documentation and final release notes against the exact uploaded binary.

## 1.3.1 — branding, web links and post-refactor update (App Store preparation)
- [x] Adopt current post-refactor Core modules, without changing published storage schema or Watch/widget IDs.
- [x] Add compact branded Today header (ChickMark, official Arvectum logo, runtime app version).
- [x] Link the header to locale-specific product pages (RU/EN/ES) and test mappings.
- [x] Synchronize iOS, Watch and widget target versions at 1.3.1 (6).
- [x] Regenerated Xcode project; 17 unit tests, 1 UI test and non-uploading release archive audit passed on 2026-10-12.
- [x] Replace unsubmitted App Store Connect 1.4 placeholder with 1.3.1 and configure AFTER_APPROVAL automatic publication (2026-10-12).
- [x] Set and verify locale-specific Marketing URL, Support URL and What’s New for RU, EN-US, ES-ES and ES-MX (2026-10-12).
- [ ] Attach signed 1.3.1 (6) build, pass App Store readiness checks, and submit for Apple review.
- [ ] Final iPhone/Watch non-destructive upgrade and offline-sync smoke, plus App Review.

## Product backlog
- [x] Sliding recurrence: next due date N days after **actual completion** (shipped in 1.3; covered by HabitFrequencyTests.testCompletionIntervalMovesFromActualCompletionDay).
- [ ] Finish edge-case policy/regression coverage for timezone travel, partial goal completion and overlapping interval completions (basic late-completion and future-check-in cases already tested).
- [ ] Evaluate extra monetization placements only after retention evidence; do not add a second native Progress ad by default.

### Proposed 1.4 — less manual tracking (not included in 1.3.1)
- [x] **P1 · Apple Health / HealthKit auto-check (development implemented, physical QA pending):** optional per-habit authorization and mapping for walk distance, workouts and other reliable HealthKit metrics; show a traceable completion source, handle revoked permission, duplicates, and Watch/iPhone reconciliation; preserve local-first privacy and allow manual correction.
- [ ] **P1 · Gentle restart after an interruption:** offer an optional, one-tap return plan after a user-configured gap; preserve all past check-ins and historical streaks, never guilt-trip or silently rewrite missed days.
- [ ] **P2 · Local weekly summary:** 7-day opt-in, low-noise snapshot with completion consistency, best day and trend; respect pauses/skips and flexible weekly goals; no account or remote analytics.
- [ ] **P2 · Negative/reduction habits:** distinguish "avoided today", "slipped" and quantity limits from positive habits; define streak, reminder and insight semantics before schema migration.
- [ ] **P3 · Notes on a check-in:** short optional comment attached to a specific habit/day, with backup/restore and migration coverage; no notes required for ordinary one-tap completion.

**Implementation gate:** do not start all five at once. Ship HealthKit and Gentle restart first behind independent opt-in flags, with migration/Watch/widget regression; only add subsequent features if they keep the core check-in friction low.

## Product-specific ad guardrails
Core features stay free. No interruptions during creation, check-off, widgets or reminders.
Delayed initial advertising and its thresholds are **ChickMark-specific**, not portfolio policy.

No app-specific tasks are duplicated in Core or Growth.

## 1.4 HealthKit implementation checkpoint (2026-10-12)
- [x] Read-only per-habit opt-in: steps, walk/run distance and workout duration.
- [x] Local rules, HealthKit observers, foreground 7-day catch-up; raw samples never leave HealthKit.
- [x] Automatic check-in through canonical mutation ledger; manual and Watch corrections take priority.
- [ ] Verify permissions, background delivery, CloudKit/Watch updates on a physical iPhone.
- [ ] Check App Store privacy disclosures and HealthKit capability before uploading 1.4.

### Native Apple integrations (future iterations)
- [x] Siri and Shortcuts — existing App Intents for completing and undoing habits.
- [x] Apple Watch and WidgetKit — existing check-in and offline Watch sync.
- [x] Apple Health — optional read-only thresholds (1.4 development, release gated by physical QA and privacy review).
- [ ] P2 · Apple Reminders — opt-in one-way creation of a reminder from a ChickMark habit; prevent duplicates and clarify it is not two-way status sync.
- [ ] P2 · Apple Calendar — opt-in event creation with write-only EventKit access; avoid overlapping ChickMark native notifications.
