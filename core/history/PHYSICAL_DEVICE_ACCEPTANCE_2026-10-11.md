# Physical device acceptance checkpoint — 2026-10-11

## Devices, non-destructive verification

- CoreDevice connected physical **iPhone 13** and available paired **Apple Watch SE** (Watch6,11).
- Physical iPhone app inventory: **ChickMark 1.3.0 (5)**, **What? 0.1.0 (2)**, PUSHKIN 1.0.0 (2).
- Paired physical Watch app inventory: **ChickMark watchOS 1.3.0 (5)**, **What? watchOS 0.1.0 (2)**.
- ChickMark 1.3 publication **confirmed by product owner**. App Store availability in every territory was not independently verified during this checkpoint.
- No application installation, data removal, Bluetooth disconnection, account changes or device reboot performed. Existing personal data was left in place.

## Available engineering evidence

- Canonical Core CI `38139496364` completed successfully: Core tests; four iOS builds; both Watch builds; What? and ChickMark behavioral simulator tests; Android tests, lint and APK.
- Physical installations and matching Watch/iPhone build versions confirmed by `xcrun devicectl device info apps`.
- **PASS:** CoreDevice successfully launched all four installed physical apps by bundle ID: ChickMark on iPhone and Watch, What? on iPhone and Watch. This is a process-launch smoke test only; app UI, data, sync and advertising were not visually verified.

## Remaining manual physical acceptance — NOT YET VERIFIED

- [ ] On iPhone and Watch, open ChickMark 1.3 and verify representative existing habits, individual N/N check-offs, widgets, reminder actions and unmodified historic records.
- [ ] Back up existing ChickMark data before any migration/import experiment; verify actual private-CloudKit data convergence on a second authorized device (do not sign out of iCloud).
- [ ] Watch offline behavior: disconnect, queue 2–3 actions/recordings, reconnect, verify delivery exactly once and retained data across a deliberate Watch reboot only after backup.
- [ ] What? record multiple notes on physical Watch offline, verify audio persists locally, reconnect and verify iPhone receipt/ACK; test failed transfer and retry without duplicate notes.
- [ ] Check ChickMark delayed advertisement on physical iPhone only after eligibility; verify correct consent/ATT and no overlay of core interactions. Avoid deliberately resetting install/consent state.

**Safety:** Physical phone and Watch contain user data. Never uninstall/reinstall signed production app, clear persistent containers, force migrations or reset pairing as part of testing. These acceptance gates require visual/manual interaction or instrumented evidence and may not be inferred from app inventory or CI build success.
