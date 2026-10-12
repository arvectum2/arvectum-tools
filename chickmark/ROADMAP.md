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

## 1.3.1 — branding, web links and post-refactor update (in development)
- [x] Adopt current post-refactor Core modules, without changing published storage schema or Watch/widget IDs.
- [x] Add compact branded Today header (ChickMark, official Arvectum logo, runtime app version).
- [x] Link the header to locale-specific product pages (RU/EN/ES) and test mappings.
- [x] Synchronize iOS, Watch and widget target versions at 1.3.1 (6).
- [x] Regenerated Xcode project; 17 unit tests, 1 UI test and non-uploading release archive audit passed on 2026-10-12.
- [ ] Enter locale-specific Marketing URL and Support URL in **App Store Connect 1.3.1 metadata**, verify the URLs and submit for review only after release approval.
- [ ] Final iPhone/Watch non-destructive upgrade and offline-sync smoke, plus App Review.

## Product backlog
- [x] Sliding recurrence: next due date N days after **actual completion** (shipped in 1.3; covered by HabitFrequencyTests.testCompletionIntervalMovesFromActualCompletionDay).
- [ ] Finish edge-case policy/regression coverage for timezone travel, partial goal completion and overlapping interval completions (basic late-completion and future-check-in cases already tested).
- [ ] Evaluate extra monetization placements only after retention evidence; do not add a second native Progress ad by default.

### Candidates for future product versions (not included in 1.3.1)
- [ ] **Gentle restart:** optional, guilt-free plan after a missed week; does not erase history or change streak records.
- [ ] **Local weekly summary:** opt-in, nonjudgmental report of consistency and useful patterns without a social/gamified score.
- [ ] **HealthKit opt-in automations:** mark compatible walking/workout habits from verified Apple Health events; never transmit Health data to Arvectum servers.
- [ ] **Negative habits:** explicitly track avoidance/reduction rather than repurposing positive check-offs.
- [ ] **Habit notes:** short optional notes on a particular check-in, requiring a reviewed schema migration and Watch/backup behavior.

## Product-specific ad guardrails
Core features stay free. No interruptions during creation, check-off, widgets or reminders.
Delayed initial advertising and its thresholds are **ChickMark-specific**, not portfolio policy.

No app-specific tasks are duplicated in Core or Growth.
