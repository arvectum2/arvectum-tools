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
- [x] **2026-10-14 physical auto-check, owner-confirmed on published iPhone 1.4.0(8):** after increasing real steps above the newly configured «Прогулка» target, the ChickMark foreground progress initially stayed stale. The owner then opened Apple Fitness and accepted updated conditions; afterwards ChickMark step data refreshed and the completion checkmark was set **automatically** without manual input. This confirms iPhone auto-completion after HealthKit data availability, but does NOT establish whether terms acceptance or sample-delivery latency caused the original delay.
- [ ] **Physical HealthKit freshness/timing remains open:** time the current reading in Apple Health/Fitness versus ChickMark over 0, 30, 60 and 120 seconds with the app foregrounded and after returning from background. The currently public 1.4.0 samples every 120 seconds while foreground-active; system background observer delivery was requested hourly (not an SLA). Do not infer background immediacy.
- [ ] **Physical Apple Watch failure, 2026-10-14:** after iPhone auto-completed «Прогулка», the Watch still showed no checkmark and no step progress. The published Watch 1.4.0(8) has no step progress UI at all. Independent local HealthKit availability/authorization and paired WatchConnectivity delivery still need to be tested.
- [x] **Source fixes for future 1.4.1** in [PR #15](https://github.com/arvectum2/arvectum-tools/pull/15): 60-second foreground-only HealthKit reads on iPhone/Watch; transmit Boolean ephemeral auto-completion state over paired-Watch snapshot when it changes (not step count or HealthKit samples); preserve SwiftData/CloudKit and manual history unchanged. Local tests 32/32, watchOS simulator build and architecture contract passed.
- [ ] **Real-device re-test after patch installation:** correct steps/goal on Watch, automatic checkbox after iPhone HealthKit reaches goal, online/offline sync, manual overrides and delay to reach paired Watch. Do not mark PR #15 accepted on physical devices.
- [ ] Complete remaining HealthKit read authorization/denial, target auto-check edge cases, manual undo and correction tests on both devices.
- [ ] Test denied/revoked permission: no crash, no surprise check-ins or raw HealthKit samples uploaded to CloudKit.
- [ ] Test nonempty iPhone widgets and Watch complications, offline/online reconciliation, date rollover and pending mutations.
- [ ] Compare preservation of existing habits/history after published 1.4 upgrade; do not delete or reset actual data.
- [ ] Check real RСЯ creative/consent behavior separately from debug diagnostics.

Release publication is confirmed by owner, but this is NOT a full physical-device acceptance sign-off.

## 1.4.1 (9) artifact ready, not yet physically accepted
- [x] Combined non-published release candidate created in [PR #17](https://github.com/arvectum2/arvectum-tools/pull/17), including updated iOS/Watch Health refreshing, paired-Watch auto-completion Boolean, unified editor, and numeric Watch progress. Full local iOS tests 163/163, essential UI tests 2/2 and archive smoke passed.
- [x] Internal-only TestFlight IPA locally exported and verified: 1.4.1(9) four signed bundles, CloudKit Production, aps-environment production, get-task-allow false. [Export evidence](https://github.com/arvectum2/arvectum-tools/pull/18). Stored on Mac mini under /Volumes/ArvectumSSD/Arvectum/builds/chickmark/1.4.1-9/export-internal/HabitsByArvectum.ipa. No upload or physical installation performed.
- [ ] GitHub Actions CI success still required (local pass is not equivalent to CI).
- [ ] Explicit user approval before internal TestFlight upload, and full in-app habit backup before replacing public 1.4.0 app. Never install development-signed 1.4.1 over the published production CloudKit configuration.
- [ ] Run actual iPhone and paired Watch HealthKit permission, step reading/target, automatic checkmark, WatchConnectivity reconciliation, manual undo, midnight and data-preserving upgrade tests.
