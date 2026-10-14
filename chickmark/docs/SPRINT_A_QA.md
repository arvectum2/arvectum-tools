# ChickMark — Sprint A: stability & real-device QA

Owner: Arvectum Tools. Started: 2026-10-14.
Product build under review: 1.4.1 (15). Physically accepted build: internal 1.4.1 (14).
Source of truth: ../ROADMAP.md. Historical notes are archived, not converted to new blockers.

## Evidence legend

- **AUTO**: deterministic XCTest, architecture check, signed archive or CI result. Never implies production UX tested.
- **SIM**: interactive simulator UI/screenshot test; may be done without changing physical device.
- **DEVICE**: physical iPhone / paired Apple Watch actual result.
- **EXTERNAL**: live YAN or App Store Connect account, network provider data.
- **OPEN**: cannot pass without next evidence. No destructive user-data mutation is authorized.

**Safety:** DO NOT uninstall app; reset habits, Health permission, iCloud/CloudKit or the paired Watch; or restore a JSON backup in replace mode on the owner's device. Use temporary simulator data for destructive scenarios and read-only physical inspection. Raw HealthKit samples must never be copied to analytics, advertising or CloudKit for QA. Apple 1.4.1 submission remains unchanged; any new code requires a separate future version.

## Verification matrix

| ID | Existing coverage and evidence type | Real-world acceptance | Status |
|---|---|---|---|
| A1 Backup, CloudKit, upgrades | AUTO: ChickMarkBackupTests, ChickMarkGroupCloudSyncTests, PersistenceTests, SchemaVersioningTests, CrossSurfaceDurabilityTests | DEVICE: previously saved habits, counts and dates remain after an update; PRIVATE CloudKit multi-device sync without duplicated records; read-only comparison, no restore-REPLACE | OPEN physical |
| A2 WatchConnectivity | AUTO: HabitSyncProtocolTests, HabitCompletionMutationTests and CrossSurfaceDurabilityTests | DEVICE: with Watch temporarily offline, toggle an expendable test habit; rejoin and ensure final action, no duplicate, correct iPhone result, including after app reopen | OPEN physical |
| A3 Day boundaries / TZ | AUTO: HabitDayBoundaryTests, HabitFrequencyTests, HabitWidgetBridgeTests, WatchComplicationBridgeTests, HealthHabitIntegrationTests | SIM: midnight, DST forward/back, timezone travel, sliding recurrence and derived cache expiration without changing owner clocks | OPEN expanded simulator tests |
| A4 HealthKit permission denial | AUTO: HealthHabitIntegrationTests, WatchComplicationBridgeTests, rule validation. Does not simulate actual native permission sheet. | SIM/DEVICE: no crash on denial, other habits still work, current-day threshold not completed on missing data; no raw readings persisted | OPEN runtime test |
| A5 iPhone widgets | AUTO: HabitWidgetBridgeTests, WidgetIntent and WatchComplicationBridgeTests | SIM/DEVICE: populated small + medium Home widgets, all three Lock Screen families, live check/undo, midnight refresh, VoiceOver labels | OPEN screen/layout QA |
| A6 Yandex Ads | AUTO: HabitAdEligibilityTests and release-level real placement configuration | EXTERNAL: registered placement R-M-20183085-1, ad correctly appears only after 3 days + 5 launches + 3 check-offs; empty-fill is non-blocking; partner dashboard shows valid actual impressions | OPEN live fill |
| A7 Language/accessibility | AUTO: LocalizationTests, localization script and UI smoke | SIM/DEVICE: switch System/RU/EN/ES, verify labels / large text / screen-reader hints / dark mode; no clipped controls on supported iPhone or Watch | OPEN expanded physical |

## Reproducible automatic / simulator run

Run in a clean worktree of main; capture exact commit SHA, macOS/Xcode and destination IDs before reporting:

1. python3 core/tools/check_architecture.py
2. python3 chickmark/ios/scripts/release_hygiene.py
3. python3 chickmark/ios/scripts/audit_store_assets.py
4. From chickmark/ios, regenerate project as needed via scripts/generate_project.sh; then run all HabitsByArvectumTests with iPhone 13 simulator and no code signing.
5. From chickmark/ios, run essential UI scenarios via chickmark/ios/scripts/ci_essential_ui_smoke.sh or direct XCTest selection, and generic watchOS build.
6. Maintain new focused regressions in follow-up patch branches, separate from already-submitted 1.4.1 (15).
7. Save results as a dated section **below**, with tests/command outcomes and observed limitations.

## Non-destructive device protocol

### A1 — history and CloudKit
Before any action, record **counts only**: total habits, completed entries and history range on iPhone, Apple Watch and any second enrolled Apple device. Do not request screenshots containing names or private health history unless needed. After normal App Store update, compare totals and two old dates; do not sign out of iCloud. For CloudKit, verify a harmless new habit created on one device syncs to another; do not use restore-REPLACE. Mark pass only with both states observed.

### A2 — Watch offline / reconnect
Use one new test habit, not established habits. With Watch paired and ChickMark already launched once, temporarily turn off the Watch connection in a controlled way, mark the test habit; restore the connection. Confirm the final action appears on iPhone without duplicates, then reverse direction. Document actual connection method and time. Never reset Watch pairing. A weak connection is not a conclusive simulated outage.

### A3 — time boundary
Perform simulator-only runs at last minute before and first minute after a local day boundary, including DST Europe/London and America/New_York. Check date key, skipped/mutation states, sliding recurrence due date, widgets and local-only HealthKit projection. Do not change the timezone on user's real iPhone. Native background refresh cadence is system-controlled.

### A4 — permissions
Run on a fresh disposable simulator installation; create a step-linked rule, choose Deny when offered, verify manual checkbox still works and no false auto-complete. In a separate simulator trial, allow and later revoke permission; verify no crash. On physical device, permission state may be read but must not be modified without an explicit user action.

### A5 — widgets
Add each supported Home and Lock Screen type with a **nonempty** list of habits, and check visual clipping, tap target, label counts and midnight. Watch face independence on 1.4.1 (14) has already been physically confirmed and is not reopened as a failure.

### A6 — ads
Use YAN account / dashboard to confirm placement R-M-20183085-1, activation and valid first impressions. If SDK returns no-fill, do not claim revenue. Test the 3d/5 launches/3 completed checkoff gate with isolated simulator preferences; do not artificially alter engagement counts on production device.

### A7 — language/accessibility
Check System/RU/EN/ES and back in a disposable simulator, large Dynamic Type and both light/dark appearances; manually compare important elements. Watch widget localization follows Watch system settings and does not necessarily change with in-app iPhone selection.

## Initial evidence (2026-10-14)

- REAL DEVICE [PASS from owner] linked step target threshold on Watch, local checkmark, and eventually automatic Watch-face completion without opening ChickMark on Watch/iPhone. In one trial stale after 25 min, updated shortly afterward. WatchOS timing is not guaranteed.
- REAL DEVICE [PASS from owner] compact downward keyboard chevron.
- CI [PASS] feature build (14): 38593557338. Public release candidate build (15): 38615994169. main Habits iOS CI rerun: 38619713713 completed success.
- Signed four-bundle public 1.4.1 (15) Apple archive, Production CloudKit/HealthKit; App Privacy SDK declarations and policy revised.
- No A1-A7 scenario has all of its required evidence yet; existing unit coverage is not a substitute for physical device / external provider observation.

## QA findings and triage

If a defect is reproduced, record: build SHA, iOS/watchOS version, source data, exact action, actual vs expected, whether iPhone or Watch was opened, relevant permission status and whether the symptom persisted after re-foreground. Prefer anonymized event counts and timing. File a focused GitHub issue and regression test before a potential 1.4.2. Never overwrite already submitted 1.4.1.
