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
- [ ] Define explicit migration fixtures before first schema change.
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
- [ ] Measure actual tap count and reduce it further if possible.

### Habit detail

- [x] Current streak.
- [x] Completion percentage.
- [x] Total check-in count.
- [x] Five-week visual history.
- [x] Correct a previous check-in by tapping a day.
- [x] Archive habit.
- [x] Delete habit and its completion history.
- [ ] Edit name, icon, color and schedule.
- [ ] Add a clearer month / heatmap view after UX validation.

### Habit logic

- [x] Scheduled-day calculation.
- [x] Streak calculation.
- [x] Streak ignores unscheduled days.
- [x] Incomplete current day does not destroy yesterday's visible streak.
- [x] Completion rate uses scheduled days only.
- [x] Unit tests for core schedule / streak / completion-rate cases.
- [ ] Test DST and timezone-change scenarios explicitly.
- [ ] Define product rule for timezone travel before public release.

## M2 — reminders and polish

- [ ] Per-habit local reminder.
- [ ] Ask notification permission only when the user enables a reminder.
- [ ] Update scheduled notifications when a habit changes.
- [ ] Add undo affordance beyond tapping the checkmark again if testing shows a need.
- [ ] Accessibility audit: Dynamic Type, VoiceOver, contrast and touch targets.
- [ ] Final Arvectum visual polish.
- [ ] RU + EN localization.
- [ ] UI tests for create → check → detail → history.
- [ ] Test on small and large physical iPhones.
- [ ] Test clean install and upgrade path.

## Product research before feature expansion

- [ ] Decompose HabitKit Pro by user jobs and interaction mechanics.
- [ ] Separate genuinely useful mechanics from optional complexity.
- [ ] Review current App Store habit trackers and recurring user complaints.
- [ ] Build an explicit `do-not-build` list.
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

- [ ] Widgets.
- [ ] Lock Screen / interactive widgets.
- [ ] Apple Watch.
- [ ] iCloud sync.
- [ ] Quantitative / duration habits.
- [ ] Habit groups.
- [ ] Advanced statistics.
- [ ] Siri / Shortcuts.
- [ ] Additional localizations.
- [ ] Achievements only if they improve retention without adding noise.

## Current checkpoint

The first vertical slice is implemented: local storage → create a scheduled habit → see it on Today → mark/unmark it → open details → inspect streak/progress/history → correct prior days → archive/delete.

**Next implementation step:** finish edit-habit flow, then run the MVP on the simulator and a physical iPhone before adding reminders.
