# ChickMark — Roadmap

**Status:** ACTIVE / implementation started
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
- [ ] Add V1→V2 migration fixtures together with the first post-V1 schema change.
- [x] Smoke-test additive SwiftData schema migrations on a physical device (reminders and timezone-stable day keys).
- [ ] Add export/import only after MVP validation.

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
- [ ] Today: at most one small adaptive banner in a dedicated bottom area.
- [ ] Progress / Statistics: at most one native ad after useful content.
- [x] Eligibility guard prevents ads immediately after install.
- [x] Store first-launch date, cold-launch count and successful check-off count locally.
- [x] Initial eligibility gate implemented: 3 full days + 5 cold launches + 3 successful check-offs.
- [ ] Validate thresholds only after the core loop is stable.
- [ ] Test retention impact before increasing ad exposure.

## Post-MVP backlog

- [ ] Quantitative / duration habits.
- [ ] Habit groups.
- [ ] Advanced statistics.
- [x] Siri / Shortcuts: Complete Habit and Undo Habit App Intents use the same idempotent desired-state bridge as the widget, with no extra in-app UI.
- [ ] Additional localizations.
- [ ] Achievements only if they improve retention without adding noise.

## Current checkpoint

M1/M2 are implemented end-to-end, and the required M3 Watch/live-sync path is operational: local storage → minimal create/edit → reminders with Complete/Skip quick actions → Today → history/skip/pause/archive → widgets → Watch. The simulator control suite has 100 unit tests plus 11 XCUITest methods: 10 run on iOS 26.5 and the iOS-27-only VoiceOver navigation test is skipped there by design. The suite includes the permanent accessibility audit across Today → Manage → Detail → Create alongside timezone/DST, mutation conflicts, flexible weekly goals, notification actions, widgets, localization, persistence and explicit schema versioning.

Physical validation on 2026-10-02 is green for the main single-device/Watch paths: canonical signed ChickMark builds install on iPhone 13 (iOS 27.0.1) and Apple Watch SE (watchOS 26.6); all core UI scenarios pass on the physical iPhone, including largest Dynamic Type, the accessibility audit for contrast/clipping/hit regions/descriptions/traits, and the iOS 27 VoiceOver navigation test using real spoken output and focus order across Today → Manage → Detail; rolling local reminders were scheduled and delivered with the app terminated; persistent SwiftData state survived a full app restart; Watch→iPhone and iPhone→Watch completion sync both converged; a Watch action queued while the iPhone app was suspended was delivered after resume and duplicate delivery remained idempotent; signed App Group storage contains the live widget snapshot and 14-day horizon; and the CloudKit-enabled signed build opens its primary SwiftData container without falling back to local-only storage.

**Post-submission development line:** until the first public release, visual/UX fixes stay on version 1.0.0 and only increment the build number. The current local follow-up is 1.0.0 (build 2); nothing from this line is submitted automatically.

**Current release state:** ChickMark 1.0 (build 1) was submitted to App Review on 2026-10-03 and is now `WAITING_FOR_REVIEW`. The App Store build is VALID / APP_STORE_ELIGIBLE; RU/EN metadata and iPhone/Watch screenshots are uploaded; App Privacy is published as Data Not Collected; category, 4+ age rating, content rights, review details and the not-a-regulated-medical-device declaration are complete. Automatic release after approval is selected. Keep V1 binary and feature scope frozen while review is in progress. No CloudKit second-endpoint test blocks V1; multi-device CloudKit remains a post-release observation item. Small/large screen coverage remains simulator-only under the physical-device safety rule.
