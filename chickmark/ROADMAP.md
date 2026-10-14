# ChickMark — Product Roadmap

## Active release checkpoint — 2026-10-14
- [x] **Follow-up TestFlight QA:** native Watch Activity rings opening preceded fresh Apple Health steps across Watch and iPhone, after which ChickMark auto-checked only when Watch app was opened. Widget/complication remained stale. [Code correction PR #22](https://github.com/arvectum2/arvectum-tools/pull/22) merged to feature branch; 167 unit tests and Watch build pass, full CI ongoing. No distribution of correction yet. See [physical QA](docs/PHYSICAL_QA_2026-10-14.md).
- [ ] Verify Watch complication and iPhone widget separately after next internal build; no guaranteed instant WidgetKit refresh or background Watch Health execution.

**Current published release:** 1.4.0 (8), approved and published, owner-confirmed on 2026-10-14. The exact 1.4.0 (8) version is also installed on paired physical iPhone 13 and Apple Watch SE as read by CoreDevice on 2026-10-14. Independent country-by-country storefront propagation was not checked. The unsubmitted 1.3.1 candidate was superseded; older preparation checklists below are historical.

Evidence: [HealthKit 1.4 branch roadmap](https://github.com/arvectum2/arvectum-tools/blob/feature/chickmark-healthkit-1.4/chickmark/ROADMAP.md), commit b7e37f5; code remains on this branch pending review and integration into main.
- [x] 1.4 branch implements opt-in read-only HealthKit-derived rules, local privacy safeguards, Watch/widget improvements and localized HealthKit purpose strings.
- [x] App Store build 8 validated, uploaded, attached and review submitted on 2026-10-13.
- [x] Owner confirmed Apple's approval and public release of 1.4.0 (8) on 2026-10-14; device inventories show the same version on iPhone and Watch. Regional propagation not independently checked.
- [ ] Finish physical iPhone+Watch HealthKit consent/readings, offline Watch reconciliation, nonempty widget, ad and privacy acceptance. Watch foreground opened without immediate crash on 2026-10-14, but Health permission/real readings remain unverified; see [physical QA evidence](docs/PHYSICAL_QA_2026-10-14.md).
- [x] **2026-10-14 iPhone physical progress:** owner confirmed «Прогулка» shows current steps and target on iPhone Today; this does not prove the watchOS HealthKit data path.
- [x] **2026-10-14 iPhone automatic check:** owner exceeded «Прогулка» threshold; after opening Apple Fitness, accepting updated terms and receiving updated HealthKit data, ChickMark automatically checked the habit. Update latency in the foreground still needs timed verification.
- [ ] **2026-10-14 Watch remains failed:** no checkbox or step count appeared after iPhone automatic check. Future [PR #15](https://github.com/arvectum2/arvectum-tools/pull/15) updates HealthKit foreground poll interval from 120 to 60 seconds and includes ephemeral completion Boolean in private Watch snapshots; 32 unit tests and Watch simulator build passed. Published 1.4.0 unchanged; physical Watch acceptance still pending.
- [x] **1.4.1 (9) internal QA candidate prepared** in [PR #17](https://github.com/arvectum2/arvectum-tools/pull/17), with signed internal-only TestFlight export evidence in [PR #18](https://github.com/arvectum2/arvectum-tools/pull/18). On Mac mini: 163/163 unit tests, 2/2 essential iOS UI tests, signed archive + IPA and four valid signatures. Exported IPA is Production CloudKit; no upload or device installation. [Release checklist](https://github.com/arvectum2/arvectum-tools/blob/feature/chickmark-healthkit-1.4/chickmark/docs/RELEASE_CANDIDATE_1.4.1.md).
- [ ] **Release blocked:** GitHub Actions iOS CI still running and physical Health/Watch acceptance pending. Require user approval before internal TestFlight upload; do not overwrite published iPhone/Watch app with the development-signed candidate.

- [x] **2026-10-14 · iPhone UX patch (code only):** editable HealthKit step goal surfaced directly in the habit edit sheet, plus RU/EN/ES **Hide keyboard** action during creation/editing; numeric grouping and opt-in activation preservation fixed in [PR #11](https://github.com/arvectum2/arvectum-tools/pull/11). 28 focused XCTest cases and one keyboard UI smoke passed on simulator; public 1.4.0 remains unchanged.
- [x] **2026-10-14 · unified Create/Edit Habit UX:** after physical feedback that "Smart automations" was unintuitive, moved ALL Apple Health controls (on/off, metric, target) into the same habit creation/editing sheet and removed the separate subpage in [PR #13](https://github.com/arvectum2/arvectum-tools/pull/13). Tests: 29 focused unit + 2 iOS 27 UI flows, iOS simulator build, architecture contract; published 1.4.0 on real devices not updated.
- [ ] **Next 1.4.1 physical gate:** create a new Apple Health-linked habit, edit target on existing «Прогулка», cancel/disconnect, and verify auto-check and Watch progress on actual devices before App Store submission.
- [ ] Include these fixes in 1.4.1, verify physical iPhone goal edit/save/reopen and auto-check after walking, and review Watch numeric-progress fix before signed release.
- [ ] **Patch after published 1.4.0:** missing step/current-target display for HealthKit-linked «Прогулка» on Watch. Code fix built and tested in [PR #7](https://github.com/arvectum2/arvectum-tools/pull/7), but NOT delivered to end users; physical sensor acceptance and release number/signing/review are still open.
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
- [ ] **P1 · Ухват → ChickMark note follow-ups (post-Ухват 1.0):** accept an opt-in reminder created for a newly recorded Ухват note after +1/+2/+3 hours; keep it in a separate one-off follow-up/reminders lane, never as a habit check-in or a streak. Show the full on-device transcription in the follow-up detail plus a deep link to original Ухват audio; use generic lock-screen alert text by default.
- [ ] **P1 · Follow-up lifecycle and handoff reliability:** stable source recording UUID, deduplicate deliveries, edit/reschedule/complete/dismiss, explicit note deletion handling and no automatic completion of other habits. Prototype supported iOS app-to-app mechanism and permission behavior; keep a no-ChickMark fallback reminder inside Ухват. Preserve local-first storage and existing published ChickMark schema.
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
