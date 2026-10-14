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

## 2026-10-14 follow-up: 1.4.1 (9) on physical iPhone and Watch
- [x] Owner created a personal JSON backup before in-place upgrade.
- [x] Owner installed TestFlight 1.4.1 (9) on iPhone **and** Apple Watch without uninstalling.
- [x] Changed Apple Health step goal on iPhone; **new target immediately arrived on Watch**. This proves at least the configuration snapshot of WatchConnectivity worked.
- [ ] After walking and waiting **five minutes**, owner reported that **step readings did not update**. Apple Fitness **had not been opened**. Do not assume that HealthKit had already saved the new step samples, or that the failure was specific to one device; those facts are not verified.
- [ ] Controlled diagnostic, without opening iPhone Fitness: first note the displayed counts/goal on ChickMark iPhone and Watch; then inspect Apple **Health → Browse → Activity → Steps** and note current count and most recent sample time. Observe whether returning to ChickMark then causes update. Separately check Apple Watch native Activity steps. A possible side effect of opening Health should be recorded rather than assumed absent.
- [ ] Verify read permission to *Steps* in iPhone Settings → Privacy & Security → Health → ChickMark and, separately, watchOS health permissions. HealthKit does not directly reveal read-denial status to an app.
- [ ] If current steps already exist in Health but ChickMark remains stale, debug foreground view task lifecycle and query errors/HealthKit authorization; if Health itself is stale, consider a consent-based live Core Motion pedometer foreground source (separate device step counts, no naive sum across phone and Watch, no CloudKit/raw measurements) rather than assuming a 60-second HealthKit SLA.
- [ ] No app patch/release from this observation yet; reproduce the source-data split first. Retain published 1.4.0 history and 1.4.1 TestFlight backup.

## Follow-up: opening Watch Activity rings makes Health steps available
- [x] User observed **equal stale step readings in iPhone Apple Health and ChickMark** even after additional walking. This demonstrates the particular stale reading was not isolated to the ChickMark iPhone UI.
- [x] When the user opened **native Activity rings on Apple Watch**, the step readings refreshed in **Watch ChickMark, iPhone ChickMark and iPhone Apple Health**. This is a temporal association, not proof that the Activity app guarantees synchronization.
- [x] **Watch auto-completion then worked without a manual checkbox tap**, but only after the user opened the Watch ChickMark app; the widget/complication still did **not** update autonomously. Which exact widget (Watch face or iPhone widget) was observed remains to be separately confirmed.
- [x] Root code issue found for Watch complication: WatchTodayView local HealthKit-derived checkoffs were not projected into WatchComplicationBridge. Fix implemented in [PR #22](https://github.com/arvectum2/arvectum-tools/pull/22) on the ChickMark feature branch. It publishes Boolean-only local ephemeral progress to Watch complication, excludes caches from backups, respects manual undo and avoids repeated unnecessary iPhone widget reload requests. **167/167 iOS unit tests**, generic watchOS build, architecture check passed; no user-device upgrade or public release.
- [ ] Verify iPhone widget separately from Watch complication in next physical QA; WidgetKit is OS-budgeted and may defer timeline updates even after a correct reload request.
- [ ] Test updated Watch complication only after a separately versioned internal TestFlight build and user-approved install. Keep 1.4.1(9) unchanged meanwhile. Closing Watch ChickMark before step completion remains an independent background-delivery limitation.

## Precise affected widget: Watch face complication (owner clarification)
- [x] The stale checkmark was on the **ChickMark complication on the Apple Watch face**, not on an iPhone Home Screen widget.
- [x] Owner has **not installed any ChickMark iPhone widget**; it cannot be evaluated from this device test, and should not be marked as failing.
- [ ] Next internal TestFlight watchOS QA after PR #22: when Apple Health has received steps beyond the threshold, launch ChickMark on Watch, do **not** tap the habit or toggle its checkbox, return to the watch face; observe whether complication now reflects the auto-completed habit. Record any OS-scheduled repaint latency.
- [ ] Separately test background mode, with Watch ChickMark closed before goal completion. Do **not** claim the complication can proactively read steps or update itself while watchOS app is suspended; this remains an OS scheduling/product limitation.
- [ ] Verify undo/skip and day rollover so local-only derived completion cannot resurrect a manually undone habit or remain on next day's complication.
