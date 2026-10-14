# ChickMark 1.4.0 (8) — physical QA evidence, 2026-10-14

Scope: installed physical iPhone 13 and paired Apple Watch SE. No app reinstallation, reset, manual data mutation or authorization change performed.

## Verified by CoreDevice
- [x] iPhone app bundle ru.arvectum.tools.habits: version 1.4.0 (8), the owner-confirmed published version.
- [x] Watch app bundle ru.arvectum.tools.habits.watch: version 1.4.0 (8).
- [x] App launch command succeeded on iPhone without foreground activation.
- [x] App launch command succeeded on Watch without foreground activation.

These results do NOT prove that either UI stayed open, that a live HealthKit query succeeded or that widget/Watch data synchronized.

## Critical manual acceptance still open
- [ ] On unlocked Watch, open app and verify stable foreground operation after navigating to a HealthKit-linked habit (previous watchOS privacy crash).
- [ ] Authorize read-only HealthKit metrics for a disposable test habit; verify actual readings, current-day auto-check and manual correction on iPhone and Watch.
- [ ] Test denied/revoked permission: no crash, no surprise check-ins or raw HealthKit samples uploaded to CloudKit.
- [ ] Test nonempty iPhone widgets and Watch complications, offline/online reconciliation, date rollover and pending mutations.
- [ ] Compare preservation of existing habits/history after published 1.4 upgrade; do not delete or reset actual data.
- [ ] Check real RСЯ creative/consent behavior separately from debug diagnostics.

Release publication is confirmed by owner, but this is NOT a full physical-device acceptance sign-off.
