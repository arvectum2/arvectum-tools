# ChickMark 1.4.1 (13) — focused real-device QA

Date: 2026-10-14
Source: PR #32 fix, PR #33 four-target build bump.
Internal distribution: ChickMark Internal QA, confirmed VALID and group-linked via official App Store Connect API. No public App Store submission.
IPA: all four signed components 1.4.1 (13), Production CloudKit, production push and watchOS HealthKit Background Delivery entitlement. Signed archive privacy audit errors: none.
Code validation: 170/170 local unit tests, generic Watch build, iPhone simulator numeric keyboard arrow UI test success. GitHub CI for branch commit 05d9c5b: https://github.com/arvectum2/arvectum-tools/actions/runs/38579186000 (running when recorded).

## Phone keyboard acceptance
- Install/update via TestFlight on iPhone without uninstalling.
- Open a step habit goal edit, focus numeric field.
- Expect the **small downward-chevron control**, aligned right on a native narrow keyboard toolbar. It must not be a broad label button and must not block the step input.
- Tap chevron: number pad closes, goal unchanged until explicitly saved; no dragging/jitter from old UIWindow pan gesture.

## Watch local auto-completion acceptance
- Ensure paired Watch app is also 1.4.1 (13) via the iPhone Watch application.
- Keep ChickMark on iPhone closed and do not touch it during this test. Do not force-quit Watch ChickMark, which can suppress background relaunch.
- With an existing today step habit (especially one whose goal/check state was modified earlier), use native Watch Activity rings until steps reach the configured goal, e.g. 4500 / 4400.
- Open ChickMark **on the Watch only**. Once it displays live step totals at or above the goal, the automatic checkmark must appear **on the Watch itself**. No manual completion tap.
- Return to the Watch face. Observe complication count. WidgetKit may defer the repaint, but a correct local derived snapshot should eventually be reflected.
- If still unchecked, preserve diagnostics about the watch step count, target, skipped status and whether iPhone was subsequently opened; do not presume Apple Health latency when the Watch already shows 4500 / 4400.

## Invariants
- Today's fresh HealthKit threshold may re-complete after historic manual undo, consistent with current iPhone HealthHabitAutoPolicy. A skipped day is not auto-completed. Future day and stale goals are never inherited.
- Only local derived Boolean completion is cached in Watch app group; raw Health measurements are not synced to iPhone or CloudKit.
- Public release requires separate authorization after real Watch acceptance.
