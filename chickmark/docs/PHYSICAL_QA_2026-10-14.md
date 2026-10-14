# ChickMark 1.4.0 (8) — physical QA evidence, 2026-10-14

Scope: installed physical iPhone 13 and paired Apple Watch SE. No app reinstallation, reset, manual data mutation or authorization change performed.

## Verified by CoreDevice
- [x] iPhone app bundle ru.arvectum.tools.habits: version 1.4.0 (8), the owner-confirmed published version.
- [x] Watch app bundle ru.arvectum.tools.habits.watch: version 1.4.0 (8).
- [x] App launch command succeeded on iPhone without foreground activation.
- [x] App launch command succeeded on Watch without foreground activation.

These results do NOT prove that either UI stayed open, that a live HealthKit query succeeded or that widget/Watch data synchronized.

## Critical manual acceptance still open
- [x] Owner opened ChickMark 1.4.0 (8) on physical Apple Watch SE and observed «Прогулка» on the list (2026-10-14): no immediate startup crash. On Watch a row tap marks completion; no detail navigation exists.
- [ ] Confirm longer foreground stability, actual Watch HealthKit permission grant and no fatal privacy termination during a read; the simple successful opening does not establish all of these.
- [ ] **Confirmed product defect in published 1.4.0 (8):** «Прогулка» is linked to HealthKit but its Watch row shows only a checkbox, not steps or target. Release 1.4.0 does not render HealthKit quantity progress.
- [x] Code correction for a *future patch*, [PR #7](https://github.com/arvectum2/arvectum-tools/pull/7) into the unmerged 1.4 development branch: Watch-local current/target + gauge + unavailable-data message; 17/17 focused tests, watchOS build and architecture checks passed. Not present in the published 1.4.0 binary.
- [ ] Perform physical QA of this correction with real step data, watch authorization and Watch/iPhone health consistency before any App Store update.
- [x] **Follow-up patch implemented on development branch** ([PR #11](https://github.com/arvectum2/arvectum-tools/pull/11)): edit the HealthKit-linked target directly in Edit Habit; preserve its metric, enabledAt and check-in history; add localized keyboard dismissal to creation, editing and Health settings. Tests: 28/28 focused unit, keyboard simulator UI smoke PASS, iOS simulator build PASS. This is not installed on the physical iPhone.
- [ ] On the final 1.4.1 candidate, physically change «Прогулка» steps to a small integer, save/reopen and confirm the changed target on iPhone and Watch. Then walk beyond the target without manual check-in, verify automatic completion and non-destructive history preservation.
- [x] **Unified editing UX in dev branch** ([PR #13](https://github.com/arvectum2/arvectum-tools/pull/13)): Apple Health toggle, metric and goal now live in Create/Edit Habit alongside name, schedule and reminders. The old «Smart automations» navigation and screen were removed. The rule is committed only by Save; no raw HealthKit data in synchronization. 29/29 focused unit + 2/2 UI flows, generic iOS simulator build passed.
- [ ] Physically validate first-time Apple Health authorization and failed authorization in the unified editor, including that Cancel never alters an existing rule. Release 1.4.0 does NOT yet include this change.

- [x] **Physical iPhone UI, owner-confirmed 2026-10-14:** the Apple Health-linked «Прогулка» row on the iPhone displays the real step progress and target. This confirms the iPhone-facing HealthKit progress display; it is not proof of correct Watch Health reads or automatic check-in at the threshold.
- [ ] Complete true HealthKit read authorization/denial, target auto-check, manual undo and correction tests with disposable habit data on iPhone and Watch (the progress display alone does not close them).
- [ ] Test denied/revoked permission: no crash, no surprise check-ins or raw HealthKit samples uploaded to CloudKit.
- [ ] Test nonempty iPhone widgets and Watch complications, offline/online reconciliation, date rollover and pending mutations.
- [ ] Compare preservation of existing habits/history after published 1.4 upgrade; do not delete or reset actual data.
- [ ] Check real RСЯ creative/consent behavior separately from debug diagnostics.

Release publication is confirmed by owner, but this is NOT a full physical-device acceptance sign-off.
