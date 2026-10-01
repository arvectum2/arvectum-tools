# Habits by Arvectum — Roadmap

**Status:** ACTIVE / implementation started
**Branch:** `arvectum-habits`
**Product name:** `Habits by Arvectum`

## Product principle

A simple, free and convenient habit tracker: keep the genuinely useful mechanics of products such as HabitKit Pro while deliberately removing unnecessary setup, feature clutter and interaction cost.

Working formula: **«всё удобное — без лишнего»**.

## M0 — product scaffold

- [x] Create dedicated branch `arvectum-habits`.
- [x] Keep Habits inside the existing Arvectum Tools repository.
- [x] Create independent iOS app target under `apps/habit-tracker/ios`.
- [x] Set product name to `Habits by Arvectum`.
- [x] Set bundle identifier to `ru.arvectum.tools.habits`.
- [x] Use iOS 17+ / SwiftUI / SwiftData.
- [x] Add dedicated unit-test target.
- [x] Add path-scoped GitHub Actions CI.
- [ ] Final app icon and production asset catalog.

## M1 — core habit loop

### Data and persistence

- [x] Local-first persistence with SwiftData.
- [x] Habit model: name, icon, color, creation date, archive state.
- [x] Weekday schedule model.
- [x] Separate per-day completion records.
- [x] Persist data without registration or server.
- [x] Regression test: habit and check-in survive persistent-store recreation.
- [ ] Define explicit migration fixtures before the first public post-beta schema change.
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
- [ ] Add a clearer month / heatmap view after UX validation.

### Habit logic

- [x] Scheduled-day calculation.
- [x] Streak calculation.
- [x] Streak ignores unscheduled days.
- [x] Incomplete current day does not destroy yesterday's visible streak.
- [x] Completion rate uses scheduled days only.
- [x] Unit tests for core schedule / streak / completion-rate cases.
- [x] Test DST and timezone-change scenarios explicitly.
- [x] Timezone rule: historical check-ins stay attached to the local calendar date on which they were made; schedules/reminders follow the device's current local timezone.

## M2 — reminders and polish

- [x] Per-habit local reminder.
- [x] Ask notification permission only when the user enables a reminder.
- [x] Update scheduled notifications when a habit changes.
- [x] Physical iPhone verification: notification authorization is granted and a daily habit creates seven correctly timed pending requests.
- [ ] Add undo affordance beyond tapping the checkmark again if testing shows a need.
- [x] Base accessibility pass: 44 pt touch targets for habit actions/pickers, VoiceOver labels and selected-state hints.
- [x] Accessibility-size responsive layouts for Today summary, habit identity/stats and primary action buttons.
- [x] Add a largest-Dynamic-Type XCUITest for the core create flow; verify it compiles via `build-for-testing` on Xcode 27.
- [ ] Physical accessibility audit: Dynamic Type, VoiceOver navigation and contrast.
- [ ] Final Arvectum visual polish.
- [x] Light/Dark empty-state smoke test on iOS 27 simulator.
- [x] RU + EN localization.
- [x] Localization completeness test for both bundled languages.
- [x] UI test for create → check → detail → history using an isolated in-memory app store.
- [x] Physical iPhone 13 signed-build install/launch smoke test.
- [ ] Test on small and large physical iPhones.
- [x] Smoke-test clean simulator install and additive-schema upgrade path on the physical iPhone 13.

## M3 — live sync + Apple Watch (REQUIRED before public release)

### Sync protocol

- [x] Shared Codable sync DTOs for Today snapshot and completion commands.
- [x] Commands are idempotent: Watch sends desired state, never a blind toggle.
- [x] Stable command IDs and day keys for duplicate-safe delivery.
- [x] Immediate transport when counterpart is reachable.
- [x] Durable queued transport when counterpart is temporarily offline.
- [x] Latest snapshot persisted locally on Watch for offline launch.
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
- [x] Pair iPhone + Apple Watch simulators and test both apps together.
- [x] Integration test: Watch check-off appears on iPhone.
- [x] Integration test: iPhone check-off appears on Watch.
- [x] Integration test: offline Watch check-off converges after reconnect.
- [ ] Physical Apple Watch smoke test when hardware is available.

### Cross-device sync direction

- [x] Keep local-first operation as the invariant.
- [x] CloudKit-compatible SwiftData schema and private-iCloud capability wiring without requiring an Arvectum account.
- [x] Local-first fallback: if cloud-backed container creation fails, Habits opens the local store instead of failing to launch.
- [ ] Verify real private-CloudKit convergence between two signed Apple devices / simulator iCloud accounts before enabling the milestone for release.
- [x] Treat WatchConnectivity as the low-latency iPhone↔Watch path and cloud sync as durable multi-device convergence.
- [ ] Test simultaneous edits and duplicate delivery before enabling cloud sync in production.

## M4 — high-value expansion from competitor/user research

- [x] Skip day: neutral exceptional-day state that does not break a streak or distort completion rate.
- [x] Best streak in habit details.
- [x] Pause / resume with explicit paused periods so history, streaks and completion rate stay correct.
- [x] Interactive Home Screen widget target with small progress + medium habit list UI.
- [x] Widget AppIntent bridge uses desired-state commands, optimistic updates and a bounded queue.
- [x] Widget bridge regression suite: 5 passing tests for persistence, dedupe, queue bounds and optimistic state.
- [ ] Enable and verify the `group.ru.arvectum.tools.habits` App Group in signed Apple provisioning.
- [x] Lock Screen widget families: circular, rectangular and inline.
- [ ] Watch complication.
- [x] Overall Today progress available outside the full app through the Home Screen widget.
- [ ] Flexible frequency behind progressive disclosure: N times per week.
- [ ] Evaluate Apple Health auto-completion only where Health has authoritative data.
- [ ] Keep haptics/micro-feedback; do not add an XP/reward economy.

## Product research before feature expansion

- [x] Decompose current HabitKit by user jobs and interaction mechanics.
- [x] Separate genuinely useful mechanics from optional complexity.
- [x] Review HabitKit plus Streaks, Habitify, Everyday, Way of Life, Loop, Strides, Productive and Finch.
- [x] Separate repeated user praise (simplicity, glanceable progress, skip/grace, reliable sync, Watch/widgets) from feature-count noise.
- [x] Build an explicit `do-not-build` list in `PRODUCT_RESEARCH.md`.
- [ ] Validate whether templates materially improve first-run activation.
- [ ] Validate whether quantitative habits are worth the extra complexity.

## Monetization — Habit-specific policy

Core habit tracking stays free. Advertising is the planned monetization model, but it must not interfere with the habit loop.

- [ ] No App Open Ads.
- [ ] No interstitials in onboarding, create/edit, check-off or settings.
- [ ] Today: at most one small adaptive banner in a dedicated bottom area.
- [ ] Progress / Statistics: at most one native ad after useful content.
- [ ] Do not show ads immediately after install.
- [ ] Store first-launch date, cold-launch count and successful check-off count locally.
- [ ] Initial eligibility hypothesis: 3 full days + 5 cold launches + 3 check-offs.
- [ ] Validate thresholds only after the core loop is stable.
- [ ] Test retention impact before increasing ad exposure.

## Post-MVP backlog

- [ ] Quantitative / duration habits.
- [ ] Habit groups.
- [ ] Advanced statistics.
- [ ] Siri / Shortcuts.
- [ ] Additional localizations.
- [ ] Achievements only if they improve retention without adding noise.

## Current checkpoint

The M1 vertical slice is implemented and M2 reminders/localization are wired end-to-end: local storage → minimal create/edit flow → optional local reminder → Today → mark/unmark → details/history → archive/delete. Optional creation settings now use progressive disclosure so the default path stays focused on name + schedule. Historical check-ins now use a stable local-day key, while current schedules/reminders follow the device timezone. RU and EN are bundled and visually smoke-tested. The suite currently has 13 passing tests, including timezone/DST regressions, localization completeness and an XCUITest covering create → check → detail → history. Clean install and additive-schema upgrades have been smoke-tested, including signed install/launch on the physical iPhone 13 with Xcode 27.0.

**Next implementation step:** Home Screen + Lock Screen widgets now compile with Watch/iPhone, and the widget command bridge has a 5-test green regression suite. Continue with Watch complication support, then flexible N/week frequency behind progressive disclosure. Signed-device widget verification remains blocked only by Apple App Group provisioning; real private-CloudKit convergence still requires two signed Apple device identities before release.
