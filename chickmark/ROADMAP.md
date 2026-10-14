# ChickMark — Product Roadmap

## Active release checkpoint — 2026-10-14
**Current published release:** 1.4.0 (8), approved and published, owner-confirmed on 2026-10-14. The exact 1.4.0 (8) version is also installed on paired physical iPhone 13 and Apple Watch SE as read by CoreDevice on 2026-10-14. Independent country-by-country storefront propagation was not checked. The unsubmitted 1.3.1 candidate was superseded; older preparation checklists below are historical.

Evidence: [HealthKit 1.4 branch roadmap](https://github.com/arvectum2/arvectum-tools/blob/feature/chickmark-healthkit-1.4/chickmark/ROADMAP.md), commit b7e37f5; code remains on this branch pending review and integration into main.
- [x] 1.4 branch implements opt-in read-only HealthKit-derived rules, local privacy safeguards, Watch/widget improvements and localized HealthKit purpose strings.
- [x] App Store build 8 validated, uploaded, attached and review submitted on 2026-10-13.
- [x] Owner confirmed Apple's approval and public release of 1.4.0 (8) on 2026-10-14; device inventories show the same version on iPhone and Watch. Regional propagation not independently checked.
- [ ] Finish physical iPhone+Watch HealthKit consent/readings, offline Watch reconciliation, nonempty widget, ad and privacy acceptance. Device inventory and non-activated launch only are verified; see [physical QA evidence](docs/PHYSICAL_QA_2026-10-14.md).
- [ ] Merge reviewed 1.4 work and release evidence into main while protecting 1.3 data and rollback.
- [ ] After release prioritize Gentle restart; weekly summary, reduction habits and check-in notes remain evidence-gated.


**Updated:** 2026-10-14
**Historical 2026-10-11 snapshot:** v1.3.0 (build 5) was published, before the later 1.4.0 release. See active checkpoint above for current state. Installed on paired physical iPhone 13 and Apple Watch SE, verified via CoreDevice app inventory 2026-10-11. Independent public App Store availability/rollout not re-verified in this audit.
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

### Historical 1.4 proposal (HealthKit implemented and shipped in 1.4.0; other features remain backlog)
- [x] **P1 · Apple Health / HealthKit auto-check (implemented in released 1.4.0; manual QA open):** optional per-habit authorization and mapping for walk distance, workouts and other reliable HealthKit metrics; show a traceable completion source, handle revoked permission, duplicates, and Watch/iPhone reconciliation; preserve local-first privacy and allow manual correction.
- [ ] **P1 · Gentle restart after an interruption:** offer an optional, one-tap return plan after a user-configured gap; preserve all past check-ins and historical streaks, never guilt-trip or silently rewrite missed days.
- [ ] **P2 · Local weekly summary:** 7-day opt-in, low-noise snapshot with completion consistency, best day and trend; respect pauses/skips and flexible weekly goals; no account or remote analytics.
- [ ] **P2 · Negative/reduction habits:** distinguish "avoided today", "slipped" and quantity limits from positive habits; define streak, reminder and insight semantics before schema migration.
- [ ] **P3 · Notes on a check-in:** short optional comment attached to a specific habit/day, with backup/restore and migration coverage; no notes required for ordinary one-tap completion.

**Implementation gate:** do not start all five at once. Ship HealthKit and Gentle restart first behind independent opt-in flags, with migration/Watch/widget regression; only add subsequent features if they keep the core check-in friction low.

## Product-specific ad guardrails
Core features stay free. No interruptions during creation, check-off, widgets or reminders.
Delayed initial advertising and its thresholds are **ChickMark-specific**, not portfolio policy.

No app-specific tasks are duplicated in Core or Growth.
