# ChickMark 1.4.1 (12): paired-device acceptance

Date: 2026-10-14
Distribution: internal-only TestFlight, existing ChickMark Internal QA group, no public App Store release.
Source: feature/chickmark-healthkit-1.4 (commit c7f7d58), PR #28 (fixes), PR #29 (build number), PR #30 (distribution confirmation).
CI: https://github.com/arvectum2/arvectum-tools/actions/runs/38572244812 — complete / success.
Release verification: four signed IPA bundles 1.4.1 (12), Production CloudKit, Watch HealthKit Background Delivery entitlement present in signed exported Watch binary and provisioning profile. No database migrations.

## Known actual device status
- iPhone 13 ChickMark 1.4.1 (12): independently verified through devicectl read-only app listing on 2026-10-14.
- Apple Watch: appears as paired to Mac mini, but CoreDevice over-network tunnel returned 4000 / RemotePairingError 1001. Installed Watch app version could not be verified from Mac mini.
- iPhone numeric keyboard: simulator test for unified Health editor proved downward swipe closes it. Real-device check remains outstanding.
- Health completion inside Watch app: physically confirmed working in 1.4.1 (11).
- Complication on Watch face without opening app: not yet physically verified in 1.4.1 (12). Apple schedules HealthKit background delivery and WidgetKit repaints; no hard latency SLA.

## Acceptance case A — numeric step keyboard
1. On iPhone 1.4.1 (12), edit an existing step-linked habit. Tap the numeric target field.
2. Swipe down on the form, above the numeric keypad, not on individual number keys. There must be no broad Hide keyboard button.
3. PASS: keyboard disappears, numeric target and Save remain visible, number entered unchanged. FAIL: gesture ignored or form becomes unusable.

## Acceptance case B — complication refresh while ChickMark is not foreground
1. In Watch app on iPhone, confirm ChickMark on Watch is also 1.4.1 (12). Do not uninstall either app and do not delete/restyle existing habits.
2. Launch ChickMark on Watch once for foreground permission/observer setup, return to the face. Do not force-quit it from the watchOS app switcher, which can suppress background relaunch.
3. Ensure today's step goal is currently not checked, and the goal is larger than the current step count in Activity.
4. Walk past the goal. Open Apple's Activity rings if necessary to make the native Watch Health data catch up, but do not tap the ChickMark complication.
5. Watch the face. Record whether the resolved fraction changes without opening the ChickMark app, approximately how long it took and whether Activity's step count passed the goal.
6. Only after recording the face state, open ChickMark on Watch and record whether the checkmark is correct. This separates HealthKit background event delivery, Watch foreground projection and WidgetKit rendering.

## Failure classification
- Native Activity still below goal: not a ChickMark auto-check failure.
- Native Activity above goal; foreground ChickMark displays below goal: Watch HealthKit sample availability / query mismatch.
- Foreground ChickMark correctly checks; face does not update until opening app: HealthKit background wake / WidgetKit budget path remains unverified. Record elapsed time, not a guaranteed instant failure.
- Face stays stale even after opening ChickMark: WidgetKit update or app-group projection fault.
- iPhone/Watch show different goals: WCSession synchronization/reconciliation fault.

## Safety gates
- No public App Store release without explicit approval.
- No uninstall/reinstall or reset of production SwiftData/CloudKit stores.
- No collection/upload of raw HealthKit step records; local transient widget cache stores completion Boolean only.
- Defer any claim of autonomous complication refresh until physically observed on Watch.
