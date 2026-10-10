# ChickMark — Roadmap

**Status:** PUBLISHED / 1.2 live; 1.3 development planning
**Branch:** `arvectum-habits`
**Product name:** `ChickMark`

## Product principle

A simple, free and convenient habit tracker: keep the genuinely useful mechanics of products such as HabitKit Pro while deliberately removing unnecessary setup, feature clutter and interaction cost.

Working formula: **«всё удобное — без лишнего»**.

Brand microcopy: the daily check-in is a **Chick-in**. Use it sparingly; clarity wins over the pun.

## M0 — product scaffold

- [x] Create dedicated branch `arvectum-habits`.
- [x] Keep Habits inside the existing Arvectum Tools repository.
- [x] Create independent iOS app target under `apps/habit-tracker/ios`.
- [x] Set product name to `ChickMark`.
- [x] Set bundle identifier to `ru.arvectum.tools.habits`.
- [x] Use iOS 17+ / SwiftUI / SwiftData.
- [x] Add dedicated unit-test target.
- [x] Add CI release-hygiene check for privacy manifests, entitlements, RU/EN localization parity, shared target versions and Watch/widget project integration.
- [x] Add unsigned Release archive smoke check that validates embedded iPhone/Watch/widgets, privacy manifests and matching bundle/build versions.
- [x] Add path-scoped GitHub Actions CI.
- [x] Mandatory simulator regression includes an optimized Release build and verifies embedded App Intents metadata, Watch app and Widget extension.
- [x] Production app-icon asset catalogs and iPhone/Watch plumbing; verified at SpringBoard size and with warning-free watchOS asset compilation.
- [x] Final approved ChickMark chicken-check artwork is installed consistently on iPhone and Watch; the in-app Chick-in celebration uses a transparent mascot cut from the same approved artwork rather than animating the square app-icon tile.

## M1 — core habit loop

### Data and persistence

- [x] Local-first persistence with SwiftData.
- [x] Habit model: name, icon, color, creation date, archive state.
- [x] Weekday schedule model.
- [x] Separate per-day completion records.
- [x] Persist data without registration or server.
- [x] Non-destructive storage recovery: if both cloud-backed and local SwiftData stores fail to open, show a safe recovery screen instead of resetting data or crashing.
- [x] Regression test: habit and check-in survive persistent-store recreation.
- [x] Freeze the current model as `HabitsSchemaV1` and wire an explicit `HabitsMigrationPlan` into production and persistence tests.
- [x] Simulator upgrade smoke test: data created by pre-versioning commit `e67bc45` survives an in-place update to the V1 migration-plan build.
- [ ] Add real V1→new-schema migration fixtures when a new persisted CloudKit field/model is introduced; 1.3 incremental modes intentionally preserve the V1 habit store layout.
- [x] Smoke-test additive SwiftData schema migrations on a physical device (reminders and timezone-stable day keys).
- [x] Add versioned JSON export/import after MVP validation; merge and explicit replace modes, validated data and simulator round-trip tests (not encrypted; user-managed local backup).

### Today

- [x] Today screen.
- [x] Show only habits scheduled for the current day.
- [x] One-tap completion / undo.
- [x] Daily progress summary.
- [x] Empty state for first launch.
- [x] Empty state when nothing is scheduled today.
- [x] Show current streak on the habit row.
- [x] Haptic feedback for successful check-in.

### Create habit

- [x] Add habit from the Today screen.
- [x] Name.
- [x] Sensible quick-name suggestions.
- [x] Color selection.
- [x] SF Symbol selection.
- [x] Daily schedule by default.
- [x] Select individual weekdays.
- [x] Quick presets: every day / weekdays.
- [x] Prevent saving a blank habit or empty schedule.
- [x] Keep the default creation path minimal: name (or one-tap template) + Done; custom days, appearance and reminder use progressive disclosure.

### Habit detail

- [x] Current streak.
- [x] Completion percentage.
- [x] Total check-in count.
- [x] Five-week visual history.
- [x] Correct a previous check-in by tapping a day.
- [x] Archive habit.
- [x] Archived-habits screen appears only when needed, with a path to restore habits.
- [x] Delete habit and its completion history.
- [x] Edit name, icon, color and schedule.
- [x] Clear six-week heatmap aligned to calendar weeks with weekday headers.

### Habit logic

- [x] Scheduled-day calculation.
- [x] Streak calculation.
- [x] Streak ignores unscheduled days.
- [x] Incomplete current day does not destroy yesterday's visible streak.
- [x] Completion rate uses scheduled days only.
- [x] Unit tests for core schedule / streak / completion-rate cases.
- [x] Test DST and timezone-change scenarios explicitly.
- [x] Timezone rule: historical check-ins stay attached to the local calendar date on which they were made; schedules/reminders follow the device's current local timezone.
- [x] Today automatically rolls over to the new local calendar day while the app remains open; midnight scheduling is DST-safe.

## M2 — reminders and polish

- [x] Per-habit local reminder for fixed schedules; flexible N/week goals intentionally stay reminder-free in V1 to avoid notifications after the weekly target is already complete.
- [x] Ask notification permission only when the user enables a reminder; if access is denied, offer a direct Settings recovery action.
- [x] Update scheduled notifications when a habit changes.
- [x] Replace repeating weekday reminders with a bounded rolling one-shot horizon; completion/skip suppresses the current day's pending reminder and the plan rebuilds after iPhone/Watch/widget mutations.
- [x] Cap managed local reminders at the earliest 60 requests to stay below the iOS pending-notification limit; planning horizon is up to 60 days so sparse/simple setups use the available capacity instead of stopping at two weeks.
- [x] Physical iPhone verification of the rolling reminder plan/delivery: signed iPhone 13 build authorized notifications, scheduled the bounded 60-request plan, and delivered a local reminder while ChickMark was terminated.
- [x] Notification quick actions: `Done` and `Skip today` mutate the same conflict-safe day ledger without opening the app.
- [x] Simulator runtime diagnostic verifies notification action completion → newer skip convergence.
- [x] Explicit four-second Undo toast after a successful Today check-off; tapping the checkmark again still works.
- [x] Base accessibility pass: 44 pt touch targets for habit actions/pickers, VoiceOver labels and selected-state hints.
- [x] Accessibility-size responsive layouts for Today summary, habit identity/stats, primary action buttons, create-schedule presets and Manage schedule labels; verified in real `ru_RU` runtime at the largest Dynamic Type on iPhone 17e simulator.
- [x] Add a largest-Dynamic-Type XCUITest for the core create flow; verify it compiles via `build-for-testing` on Xcode 27.
- [x] Physical accessibility audit on iPhone 13: largest Dynamic Type plus automated real-device checks for contrast, text clipping, hit regions, element descriptions and accessibility traits pass.
- [x] Physical VoiceOver navigation on iPhone 13 verified with Xcode 27 `XCUIVoiceOverService`: real spoken output/focus order passes across Today → Manage → Detail, and decorative stat symbols are excluded from speech while each stat is exposed as one meaningful value.
- [x] Final in-app Arvectum visual polish: remove redundant zero-streak copy, preserve deliberately sparse Today layout, verify Light/Dark on small and large simulators, and install the final ChickMark chicken-check icon on iPhone and Watch.
- [x] Move rare Pause/Archive/Delete maintenance actions out of the active detail body into an overflow menu; when paused, Resume remains prominent in the body.
- [x] Subtle completion feedback: haptic + lightweight symbol bounce on iPhone and Watch; iPhone also gets a restrained one-shot Chick-in mascot peck/grain celebration attached to the exact habit row that was completed, with Reduce Motion support; no XP/reward economy.
- [x] Light/Dark empty-state smoke test on iOS 27 simulator.
- [x] RU + EN localization.
- [x] Localization completeness test for both bundled languages.
- [x] UI regression for create → check → detail → history plus Skip→complete, Pause→Resume and Archive→Restore using an isolated in-memory app store.
- [x] Physical iPhone 13 signed-build install/launch smoke test.
- [x] Test-device safety rule: simulators are allowed; physical testing is limited to the user's Mac mini, MacBook, `iPhone Nikita` (iPhone 13) and `Apple Watch — Никита` (Apple Watch SE). Do not use any other physical device without a new explicit approval.
- [x] Simulator visual smoke test on iPhone 17e and iPhone 18 Pro Max in Light/Dark; no clipping or contrast regressions.
- [x] Small/large screen-size coverage stays simulator-only under the physical-device safety rule.
- [x] Smoke-test clean simulator install and additive-schema upgrade path on the physical iPhone 13.

## M3 — live sync + Apple Watch (REQUIRED before public release)

### Sync protocol

- [x] Shared Codable sync DTOs for Today snapshot and completion commands.
- [x] Commands are idempotent: Watch sends desired state, never a blind toggle.
- [x] Stable command IDs and day keys for duplicate-safe delivery.
- [x] Immediate transport when counterpart is reachable.
- [x] Durable queued transport when counterpart is temporarily offline.
- [x] Rapid same-habit/day Watch mutations compact to one local pending command; offline durable transport is debounced so 51 rapid toggles produce at most one current system transfer instead of a false/true delivery flood.
- [x] Latest snapshot persisted locally on Watch for offline launch.
- [x] Watch app cache, widget and complication reject stale previous-day snapshots after calendar rollover.
- [x] Publish a 14-day read-only day horizon so Watch/complication can roll over at midnight without opening the iPhone app; paired live-sync regression still converges to `pending=0` after a Watch check-off.
- [x] Bound WatchConnectivity snapshots to a conservative 48 KiB envelope: typical users keep the full horizon, while only distant projected days are trimmed for very large habit sets; current-day habits are never dropped.
- [x] Optimistic Watch UI: a tap updates immediately without waiting for iPhone.
- [x] Reconcile optimistic state when the authoritative iPhone snapshot arrives.
- [x] Resend/snapshot on activation so devices converge after interruption.
- [x] Document conflict rules and timezone semantics in `SYNC_DESIGN.md`.

### Apple Watch app

- [x] Add native watchOS target to the existing Habits project and embed it in the iPhone app.
- [x] Today-first Watch UI; no secondary dashboard before the habit list.
- [x] Show overall today's progress at a glance.
- [x] Show only habits due today.
- [x] One obvious tap to complete / undo.
- [x] Keep completion usable when iPhone is temporarily unreachable.
- [x] Visual state matches iPhone colors/icons without requiring configuration on Watch.
- [x] RU + EN localization.
- [x] Base Dynamic Type / VoiceOver semantics on Watch.
- [x] Pair iPhone + Apple Watch simulators and test both apps together; regression now requires the post-action Watch snapshot itself to reach `completed=1/2 pending=0`, preventing false-positive convergence.
- [x] Visual/runtime smoke test on 42 mm and 46 mm Apple Watch simulators with a populated Today snapshot; retry confirmed the earlier 46 mm watch-face capture was a simulator foreground artifact.
- [x] Integration test: Watch check-off appears on iPhone.
- [x] Integration test: iPhone check-off appears on Watch.
- [x] Integration test: offline Watch check-off converges after reconnect.
- [x] Physical Apple Watch SE smoke test: signed watchOS build installs/launches, Watch→iPhone and iPhone→Watch completion sync both converge, and a Watch action queued while the iPhone app is suspended is delivered idempotently after resume.

### Cross-device sync direction

- [x] Keep local-first operation as the invariant.
- [x] CloudKit-compatible SwiftData schema and private-iCloud capability wiring without requiring an Arvectum account.
- [x] Wire CloudKit background delivery requirements in source: `remote-notification` background mode + `aps-environment` (`development` Debug / `production` Release).
- [x] Local-first fallback: if cloud-backed container creation fails, Habits opens the local store instead of failing to launch.
- [x] Release decision: do not block V1 on a second-endpoint private-CloudKit convergence test. Signed provisioning is configured; the physical iPhone build carries CloudKit (`iCloud.ru.arvectum.tools.habits`), Push and App Group entitlements and opens the CloudKit-backed SwiftData container without fallback. Multi-device CloudKit behavior is monitored post-release and investigated if real users report an issue.
- [x] Treat WatchConnectivity as the low-latency iPhone↔Watch path and cloud sync as durable multi-device convergence.
- [x] Conflict-safe last-write-wins day mutation ledger for iPhone / Watch / widget commands, with deterministic mutation-ID tie-breaks.
- [x] Runtime stress test: a newer Skip rejects an older delayed Watch completion; paired simulator converges after durable delivery.
- [x] Reconnect hardening: a newer authoritative snapshot can semantically acknowledge an already-satisfied pending Watch command even if WatchConnectivity redelivers older durable packets; verified offline action → reconnect ends with `pending=0`.
- [x] Durable-save invariant: Watch acknowledgements are recorded only after SwiftData save succeeds; failed saves keep the command retryable and return authoritative persisted state.
- [x] Test simultaneous edits and duplicate delivery before enabling cloud sync in production.

## M4 — high-value expansion from competitor/user research

- [x] Skip day: neutral exceptional-day state that does not break a streak or distort completion rate.
- [x] Best streak in habit details.
- [x] Pause / resume with explicit paused periods so history, streaks and completion rate stay correct.
- [x] Interactive Home Screen widget target with small progress + medium habit list UI; medium check/undo control uses an enlarged hit target.
- [x] Widget navigation removes an extra step: small/Lock Screen surfaces open Today, while tapping a habit row in the medium widget deep-links directly to that habit detail; parser + runtime route are covered by tests.
- [x] Widget AppIntent bridge uses desired-state commands, optimistic updates and a bounded queue; on iOS 17–25 it can route through the app process via `ForegroundContinuableIntent`, and on iOS 26+ through dynamic foreground-capable runtime modes, so authoritative SwiftData/reminder reconciliation can happen in the background without opening UI. The App Group queue remains the durable fallback.
- [x] Widget bridge regression suite: 12 passing tests covering persistence, midnight projection, dedupe, queue bounds, optimistic state, actionable-first presentation and app-runtime intent processing.
- [x] Enable and verify `group.ru.arvectum.tools.habits` in signed Apple provisioning for iPhone app, iOS widget, Watch app and Watch widget; physical iPhone App Group storage contains the live widget snapshot (`2/2`) plus the 14-day horizon.
- [x] Lock Screen widget families: circular, rectangular and inline.
- [x] Watch complication (circular, rectangular, inline) backed by the Watch-local snapshot.
- [x] Overall Today progress available outside the full app through the Home Screen widget.
- [x] Home/Lock Screen widgets receive a 14-day read-only projection so the next calendar day is immediately useful after midnight even if the full app has not been opened.
- [x] Flexible frequency behind progressive disclosure: N times per week, with creation/pause/skip-aware effective weekly targets; fully skipped weeks are neutral for streaks and completion rate.
- [x] Manual habit order in Manage only; Today, Widget snapshots and Watch consume one shared `HabitTodayProjection`. Today/Watch preserve exact user order; the three-row medium widget stably prioritizes unresolved habits while preserving relative order within unresolved/resolved groups.
- [x] Distinguish a truly missed scheduled day from skipped / paused / unscheduled days in history; never mark individual days missed for N/week goals.
- [x] Apple Health decision for V1: defer integration until after launch; later use auto-completion only for authoritative Health data where it removes manual logging.
- [x] Keep haptics/micro-feedback (haptic + restrained symbol bounce + explicit Undo); do not add an XP/reward economy.

## Product research before feature expansion

- [x] Decompose current HabitKit by user jobs and interaction mechanics.
- [x] Separate genuinely useful mechanics from optional complexity.
- [x] Review HabitKit plus Streaks, Habitify, Everyday, Way of Life, Loop, Strides, Productive, Finch, Atoms and HabitMinder.
- [x] Separate repeated user praise (simplicity, glanceable progress, skip/grace, reliable sync, Watch/widgets) from feature-count noise.
- [x] Build an explicit `do-not-build` list in `PRODUCT_RESEARCH.md`.
- [x] V1 template decision: keep four one-tap quick suggestions in creation; do not build a template gallery before activation data proves a need.
- [x] V1 quantitative-habit decision: defer count/duration/measure types until post-launch evidence justifies the added model and UI complexity.

## Monetization — Habit-specific policy

Core habit tracking stays free. Advertising is the planned monetization model, but it must not interfere with the habit loop.

- [x] Product rule: no App Open Ads.
- [x] Product rule: no interstitials in onboarding, create/edit, check-off or settings.
- [x] Today: one adaptive sticky banner in a dedicated fixed bottom safe-area slot; the habit list scrolls independently above it and the banner never appears between habits.
- [ ] Progress / Statistics: at most one native ad after useful content.
- [x] Eligibility guard prevents ads immediately after install.
- [x] Store first-launch date, cold-launch count and successful check-off count locally.
- [x] Initial eligibility gate implemented: 3 full days + 5 cold launches + 3 successful check-offs.
- [x] Yandex Mobile Ads sticky banner integrated with production block `R-M-20183085-1`; required SKAdNetwork entries are bundled, test creative loads on iOS 27, and banner height follows the SDK content size.
- [x] `app-ads.txt` for the shared Arvectum domain already matches the current Yandex/RСЯ seller list, so ChickMark does not need a second file.
- [x] First ad-enabled build privacy audit completed against the exact signed/exported artifact, embedded SDK manifests, Yandex documentation and runtime settings; App Store Privacy remains Data Not Collected, Tracking = No.
- [ ] Validate thresholds only after the core loop is stable.
- [ ] Test retention impact before increasing ad exposure.

## Post-MVP backlog

- [x] Completion-relative interval: a habit can recur “N days after I actually did it”; the next due date moves from the real completion day, remains due when overdue, supports local reminders, and does not alter the published Habit/CloudKit storage schema.
- [x] One-off reminders: lightweight single-event reminders alongside habits (for example, “buy a marathon slot”; registration opens at 08:00), with date/time, local notification, notification Done action, edit/delete and no conversion into a recurring habit.
- [x] Multi-check daily target (2–5 independent circles; one day is complete only at N/N). Core persistence/Watch/widget completion compatibility and independent taps tested on simulator; past-day per-slot editing and physical Watch validation remain separate.
- [x] Basic quantitative/time goals beyond multi-check: count targets 1–100 (increments of 1) and duration 5–120 minutes (increments of 5); current step total shown on Today/Watch/widget and persisted with existing V1 records. Arbitrary measurement units, fractional values and finer time entries remain backlog.
- [x] Optional named habit groups with assign/remove and local-only storage; included in JSON backup. [ ] Multi-device CloudKit group sync deferred to a versioned schema migration.
- [x] Fixed-schedule 7/30-day consistency insights with neutral skipped/paused days and in-progress-day handling; core tests green. [ ] Weekly-goal and completion-relative insights pending.
- [x] Siri / Shortcuts: Complete Habit and Undo Habit App Intents use the same idempotent desired-state bridge as the widget, with no extra in-app UI.
- [ ] Additional localizations.
- [ ] Achievements only if they improve retention without adding noise.

## Current checkpoint

M1/M2 are implemented end-to-end, and the required M3 Watch/live-sync path is operational: local storage → minimal create/edit → reminders with Complete/Skip quick actions → Today → history/skip/pause/archive → widgets → Watch. The simulator control suite has 109 unit/integration tests plus 12 XCUITest methods: 11 run on iOS 26.5 and the iOS-27-only VoiceOver navigation test is skipped there by design. The suite includes the permanent accessibility audit across Today → Manage → Detail → Create alongside timezone/DST, mutation conflicts, flexible weekly goals, notification actions, widgets, localization, persistence and explicit schema versioning.

Physical validation on 2026-10-02 is green for the main single-device/Watch paths: canonical signed ChickMark builds install on iPhone 13 (iOS 27.0.1) and Apple Watch SE (watchOS 26.6); all core UI scenarios pass on the physical iPhone, including largest Dynamic Type, the accessibility audit for contrast/clipping/hit regions/descriptions/traits, and the iOS 27 VoiceOver navigation test using real spoken output and focus order across Today → Manage → Detail; rolling local reminders were scheduled and delivered with the app terminated; persistent SwiftData state survived a full app restart; Watch→iPhone and iPhone→Watch completion sync both converged; a Watch action queued while the iPhone app was suspended was delivered after resume and duplicate delivery remained idempotent; signed App Group storage contains the live widget snapshot and 14-day horizon; and the CloudKit-enabled signed build opens its primary SwiftData container without falling back to local-only storage.

**Published baseline:** ChickMark 1.0 (build 1) passed App Review and is published in the App Store. It remains the compatibility baseline for storage, CloudKit, Watch and widget behavior.

**Published releases:** 1.1.0 (build 3), released 2026-10-06; **1.2.0 (build 4) confirmed published by product owner on 2026-10-10**. It ships one-off reminders plus the first non-disruptive Today banner monetization. One-off reminders use their own local-only SwiftData configuration, so the published V1 habit/CloudKit store and production CloudKit schema remain unchanged. Multi-check habits, quantitative goals, advanced statistics and additional ad placements are tracked in the 1.3+ development plan below. Small/large screen coverage remains simulator-only under the physical-device safety rule.


## V1.1 release scope

- [x] Version line: 1.1.0 / build 3.
- [x] Primary feature: one-off reminders, independent from habit streaks/statistics and stored in a separate local-only SwiftData configuration.
- [x] Monetization: sticky Today banner only; do not add Progress/native ads in the first monetized release.
- [x] One shared local-notification budget: one-off reminders reserve slots first so explicit future commitments cannot be crowded out; recurring habit reminders fill the remaining capacity under the existing 60-request cap.
- [x] Audit the exact App Store archive/IPA privacy manifests and reconcile App Store Privacy; final 1.1 decision is Data Not Collected, Tracking = No under the current Yandex runtime configuration.
- [x] Refresh App Store screenshots only where the visible Today UI materially changed.
- [x] Prepare RU/EN What's New copy and new review notes.


## 1.2 publication closeout (2026-10-10)

- [x] Owner confirms App Store 1.2 is published.
- [x] Public App Store ChickMark listing (ID 6818711298) exposes Arvectum Developer Website and Privacy Policy; official Arvectum marketing page, /privacy, /contact.html and /app-ads.txt returned HTTP 200 on 2026-10-10.
- [ ] Record production Yandex ad fill and check eligibility gate on real installs, respecting user privacy.
- [ ] Monitor crash reports, retention and ad impact before changing ad frequency.
- [ ] Validate cross-iPhone CloudKit convergence on two authorized devices (requires explicit authorization for any new physical test device).

## 1.3+ execution roadmap — finish the agreed backlog

### Sprint A — multi-check daily targets (priority P0)
- [x] V1-compatible multi-check storage with typed domain modes and deterministic slot identities; existing CloudKit model and binary habits retained.
- [x] Independent 2–5 N/N checks on Today, individual historical-day editor, detailed day accessibility values, and Watch/widget summary.
- [x] Only N/N means completed; partial progress is not a streak or a due-date completion; skip clears day progress and paused/neutral rules preserved.
- [x] Desired-count is an optional, backwards-decodable Watch/widget wire parameter; iPhone mutation ledger, ACK and reconcilers enforce idempotent offline desired state. Watch has +/− partial controls; widget/Shortcuts/notification UI retain whole-goal quick actions.
- [x] Unit/integration tests for duplicate/out-of-order counts, partial completion, schema compatibility, DST/timezone, local data upgrade and widget/watch replay; simulator upgrade from 1.2 retained two habits, a completion and a reminder.
- [ ] FINAL ONLY: physical iPhone + paired Watch smoke and the owner-requested real iPhone + simulator CloudKit/KVS convergence tests after all feature/refactor/localization tasks.

### Sprint B — quantitative and duration goals (priority P1)
- [x] Count 1–100 in integer steps and duration 5–120 minutes in five-minute steps; custom units/fractions remain evidence-gated rather than adding a complex input surface.
- [x] Incremental count/duration goals, current and historical day progress editing, complete-at-target semantics and V1 model compatibility; free-form physical units/fractions deferred until a proven user need.
- [x] Core projection/streak/notification/desired-count regression suite; binary default remains one tap.

### Sprint C — usability / analytics (priority P1)
- [x] Optional local-only groups in Manage and Add/Edit, with original ungrouped Today and backup participation; [ ] CloudKit-backed groups after schema migration.
- [x] Fixed-schedule 7/30-day insights, 4/12 completed-week insights, and actual occurrence/average interval for completion-relative schedules; unfinished weeks and neutral pauses excluded.
- [x] Versioned plaintext JSON export/import with validation, merge or explicitly destructive replace and round-trip tests; file destination chosen by user.
- [x] Current release line retains the same SwiftData/CloudKit model; real 1.2→1.3 simulator upgrade exercised; new schema fixture not applicable until a schema is deliberately changed.

### Sprint D — monetization / release (priority P1)
- [x] Product decision: do NOT add a second native ad to Progress in 1.3 without retention evidence; track as postrelease/evidence-gated instead.
- [x] Simulated threshold/boundary tests green; the already-shipped gate remains 3 days/5 cold launches/3 check-ins. [ ] Real-world ad fill/eligibility can only be observed on approved physical install; no extra ad slot.
- [x] Local distribution-signed IPA, all 28 embedded third-party/first-party privacy manifests and vendor behavior documented in privacy-notes-1.3.md. [ ] Physical/runtime disclosure confirmation is the final device acceptance step.
- [ ] Refresh RU/EN metadata and screenshots, archive smoke, CI and App Review checklist for next release.

### Later / evidence-gated (P2)
- [x] Spanish added across app/Watch/widgets/Shortcuts plus es-ES/es-MX metadata; [ ] further localizations only after store-demand evidence and a localization editorial pass.
- [ ] Apple Health auto-completion only with reliable authoritative events and explicit user consent.
- [ ] Achievements only if retention data shows benefit; no XP clutter.

### Engineering and release rules
- Preserve 1.2 production behavior as rollback baseline.
- Use short-lived implementation branches from the reconciled current app source; do not blindly merge diverged `main`/`arvectum-habits` histories.
- Each sprint requires isolated feature implementation, focused test suite, simulator build, documented acceptance and a separate commit/PR.
- No release or production ad exposure increase without validation and explicit owner release decision.


## 1.3 feature and QA checkpoint — 2026-10-10

- [x] Functional phases A–C built: N/N, quantity and duration progress, history correction, group folders, multi-period insights, and JSON backup/import.
- [x] Local-first iCloud KVS group transport implemented with per-group tombstones and per-habit assignments; **real two-endpoint convergence is explicitly unverified** and deferred to the very end.
- [x] Watch stepwise desired-count actions, offline durable command queue and backwards-compatible 1.2 binary command decoding.
- [x] Automated release hygiene, RU/EN/ES resource parity audit, 138 passing unit/integration tests and 4 passing key simulator UI cases; maximum Dynamic Type and contrast audited.
- [x] Local unsigned 1.3.0 (build 5) Release archive smoke passed, including embedded iPhone widget/Watch/Watch widget and privacy manifests.
- [x] Prior 1.2 simulator SwiftData data preserved across a non-destructive update; this is **not** the user's requested iPhone-to-simulator cloud convergence test.
- [x] Typed goal mode, separated UI components, group KVS transport/merge ledger, isolated SwiftData backup service and DEBUG-only fixture file, lazy-on-eligibility ad initialization, architecture boundary document.
- [x] Full simulator regression: 140 unit/integration tests, 19 XCUITest cases (18 executed, 1 iOS27-only skip) — all passed; iOS signed development archive and Apple Distribution exported IPA built locally.
- [x] Twelve App Store-sized regional PNGs generated and checked: iPhone 1320×2868, Watch 416×496, EN/RU/ES. No Apple upload.
- [x] Exhaustive signed IPA static privacy audit: all four first-party components and 28 total first-/third-party manifests examined; tracking-capable AppMetrica manifest caveat documented. [ ] Last: actual SDK network/eligibility on approved physical iPhone.
- [x] Draft next-version Store copy RU/EN/es-ES/es-MX; App Store Connect and TestFlight remain untouched.
- [x] Nine raw iPhone 17 Pro simulator screenshots captured from real 1.3 UI: Today, history, Manage × EN/RU/ES, with no user data.
- [x] Raw Apple Watch SE 3 screenshots for EN/RU/ES, from synthetic 3/5 preview.
- [x] App Store-oriented screenshots exported for EN/RU/ES (iPhone 1320×2868, Watch 416×496), with automated dimensional audit.
- [ ] Final physical-device editorial review and App Store Connect screenshot acceptance at release; additional languages remain evidence-gated, not a V1.3 scope blocker.
- [ ] Real production ad-fill/retention check before deciding on any new ad slot; no increase to ad exposure in this branch.
- [ ] Release-IPA privacy/ad-SDK audit on the final signed binary, separate from unsigned local archive smoke.
- [ ] **Last after everything else:** actual physical iPhone + simulator iCloud convergence, and paired Watch/physical-device regression (single iPhone; no need to acquire a second one if same-account simulator iCloud functionality is available).
- [ ] Separate explicit release approval; **do not upload**.

## 1.3 implementation checkpoint — 2026-10-10 (working branch, NOT a release)

- [x] Multi-check: independent 2–5 slots, stable UUIDs per slot/day, complete only at N/N, reminders/streaks/historical day-count all use target-aware completion; undo of the last slot reverts only that slot.
- [x] Quantitative count 1–100 (+1/−1) and duration 5–120 minutes (+5/−5) with saved progress, basic Today controls and whole-goal Watch/widget commands.
- [x] Watch and widget snapshots carry optional count/target fields; older binary habits and old packet data remain compatible.
- [x] JSON backup/export and validated import (merge/replace) with data-preservation tests; caution: plaintext file and replace can sync deletions through iCloud.
- [x] Fixed-calendar 7/30-day insights, excluding neutral skip/pause and unfinished today.
- [x] Current unit/integration suite: 127 passing simulator tests after typed goal-mode adapter, local group tests, and component extraction; N/N, VoiceOver/accessibility audit, and Skip→Complete targeted UI scenarios passed.
- [x] Deliver local-only habit groups and move the group identity out of Habit V1 schema; [ ] add CloudKit sync after versioned migration and multi-device validation.
- [ ] Add unlimited/custom measurement units, fractional values and non-5-minute duration entries if the product requires them.
- [x] Independent history day editor for 2–5 slots; adaptive 44pt+ accessibility row, tested for five check-ins at maximum Dynamic Type.
- [ ] Paired Watch physical smoke for partial progress, late/duplicate commands and widget behavior.
- [x] Flexible weekly consistency (last 4/12 completed weeks) and rolling 30/90-day interval occurrence/mean-gap insights, with dedicated calendar/DST tests.
- [ ] Validate full import/export and 1.2→1.3 upgrade against real-device persistent data with an explicit non-destructive smoke procedure.
- [x] Deferred additional ad placement until postrelease evidence; no added Progress/native ad in this 1.3 branch. [ ] Physical runtime check of existing banner only at final QA.
- [x] Initial post-feature localization: all app + Watch/widget + Shortcuts strings translated into Spanish (172 iOS keys), and es-ES/es-MX ASO drafts prepared. [ ] Localization to further priority markets and human review/screenshot capture.
- [x] Initial modular refactor: typed HabitGoalMode adapter centralizes published integer storage compatibility; Today UI subviews extracted into TodayComponents.swift. [ ] Complete dependency-oriented module split and characterization testing before release.
- [ ] LAST STEP ONLY: signed-device QA, CloudKit + group iCloud KVS convergence on one authorized physical iPhone plus a simulator, final privacy/ads review and explicit owner release approval. No upload.

**Compatibility design:** Incremental goal mode is encoded in the already-published `Habit.weeklyTarget` recurrence-mode integer, retaining the V1 SwiftData/CloudKit model schema. This is an explicit technical tradeoff for an unreleased branch: during the planned refactor, replace magic integer ranges with a named domain representation and add migration fixtures before shipping any persistent schema update. Never silently reset user data to recover from a migration issue.

## 1.3 delivery policy — product owner decision (2026-10-10)

**HOLD RELEASE:** do not submit, upload, deploy, or release 1.3 until explicitly instructed. Version 1.2 remains the published stable baseline.

Execution order (each stage must pass build/tests and be reviewed before advancing):

1. **Feature completion:** Sprint A N/N multi-check with iPhone, Watch, widget and reminder parity; Sprint B quantitative / duration; Sprint C groups, useful statistics and export/import. Recheck persistence, CloudKit, backward compatibility and offline replay after each change.
2. **Localization pass:** after features stabilize, use the same regional localization workflow as Photo Size: define target locales and market names, localize every user-facing string, notifications, widgets, Watch, App Store metadata and screenshots as applicable; run completeness, truncation, accessibility and RTL checks where relevant. Existing RU/EN must remain complete meanwhile.
3. **Dedicated refactor:** only after feature and localization baselines are green; define module boundaries (domain calculations, persistence/migrations, sync, reminders, presentation/strings, ads); remove duplication without changing public behavior, schema or bundle IDs. Review file responsibilities, inject dependencies, add characterization/regression tests, and record architecture decisions.
4. **Pre-release stabilization:** clean builds (Debug+Release), full unit/UI suite, Watch pairing/reconnect tests, CloudKit data-preservation upgrade tests, privacy/ads audit, device smoke tests and App Store metadata review. **Do not ship** without separate approval.

Progress note (2026-10-10): implementation is direct ChatGPT + RDC + Xcode (no external coding agent). New features and the simulator regression/unsigned archive smoke are green; the final signed binary, localized screenshots, production ads evidence and cross-device convergence are **not** signed off. The 1.2 App Store release remains untouched.

## 1.3 final non-device acceptance — 2026-10-10

- [x] 140 unit/integration tests + 19 UI cases, 18 executed, 1 platform-specific skip, **0 failures**.
- [x] Code refactor merged into the isolated ChickMark branch; no published data-schema change.
- [x] 12 store-sized RU/EN/ES screenshots validated with local automated audit.
- [x] One and only one existing Today ad: `R-M-20183085-1`; ad SDK starts only after the gate in 1.3. Extra placements deferred, not blockers.
- [x] **Distribution-signed 1.3.0 (5) IPA exported locally**, validated `codesign`, all four bundles and 28 embedded privacy manifests. SHA-256: `73523aeb9060631ab8c6ffaa711bfc2f5145c8d3905f56f6a6495da3560f7049`.
- [ ] **Only remaining technical validation:** paired physical iPhone/Watch plus an authorized iOS simulator (same iCloud account), non-destructive data/sync/notification/ads/privacy smoke. Separate explicit owner release approval also required. No upload.


## 1.3 dependency hardening + second refactor — 2026-10-10
- [x] Direct vs transitive dependency inventory in `docs/DEPENDENCIES.md` (1 direct Yandex, 4 transitives); iOS 17 / watchOS 10 deployment targets kept separate from Xcode 27 toolchain.
- [x] Replace exact-version requirement in XcodeGen with compatible semver floor; retain exact reviewed versions as a **tracked SwiftPM lockfile** for CI/release reproducibility.
- [x] Add update-only workflow and lock consistency/source revision audit; default builds cannot automatically select newer ad SDK binaries.
- [x] Extract insight-card presentation from `HabitDetailView` into `HabitDetailInsights.swift`.
- [x] 140 unit/integration tests, iOS 27 accessibility and historical N/N UI retest, and Release unsigned archive smoke passed after refactor.
- [ ] Green CI for the final dependency/refactor commit.
- [ ] FINAL DEVICE QA ONLY after green CI: real physical iPhone + simulator, Watch, cloud data/restore, real notification/ads/privacy.
- [ ] Later phase by explicit owner decision: ASO, SEO and publication.

- [x] Test deliberate Yandex 8.6.0 upgrade in an isolated worktree: simulator build succeeds, and new Tapjoy 14.8.0 transitive graph is **correctly rejected** by dependency policy pending privacy/security review. The shipping candidate remains on 8.5.0.

## 1.3 physical-device QA preparation — 2026-10-10
- [x] Verified 1.2.0 installed on physical iPhone 13, iOS 27.0.1, paired physical Apple Watch SE.
- [x] Exported ad hoc 1.3.0 (5) candidate for the physical device with production CloudKit and production APS; four signed provisioned bundles validated. SHA-256 and local QA artifact location recorded in docs/DEVICE_QA_1.3.md.
- [x] Paired iOS 27 iPhone 18 Pro simulator with watchOS 27 Watch SE 3 simulator.
- [x] Re-ran full iOS 27 UI suite: identified two test-only viewport/VoiceOver expectation issues, then passed both corrected scenarios separately; new full-suite pass to follow.
- [ ] Fresh iCloud/Finder backup and 1.2 baseline confirmation **before** physical in-place installation.
- [ ] Production CloudKit and Watch inter-device convergence, ad/notification/network and privacy acceptance on physical iPhone; no second physical iPhone required.
- [ ] ASO/SEO and release authorization ONLY AFTER QA.

- [x] Final iOS 27 UI Xcode Test Result: **19/19 passed, 0 failures, 0 skips** on iPhone 18 Pro (commit 1cf9833 app/test code). Paired Watch SE 3/watchOS27 simulator app launches and displays seeded 3/5 partial controls.
- [ ] Hosted Xcode 27 CI completion and backup-driven physical acceptance still pending; no App Store / TestFlight upload.
