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

## Automated sprint execution — 2026-10-14

- Baseline SHA: 46456c22bb78936569be0eebc645ae3ff6c811b8. Executed in a **separate Git worktree** from current main, not on owner device. macOS and Xcode version are in the private QA build log folder.
- Local logs (Mac mini): /Volumes/ArvectumSSD/Arvectum/builds/chickmark/sprint-a-20261014/
- Architecture check: **PASS**. Release hygiene: **PASS**. Store assets: **12 PNGs / 0 errors**. watchOS generic Debug build: **PASS**.
- Baseline all-unit simulator: **173 tests, 0 failed**. Repeated after four A2/A3 regression additions: **177 tests, 0 failed**.
- New A2 tests:
  - Offline Watch check then undo: a delayed older iPhone completion cannot resurrect a check or drop the later pending undo, and a subsequent authoritative ACK clears the queue.
  - Previous-day offline command after midnight: remains attributed to the original day, never checks today's Watch UI.
- New A3 tests:
  - 2026-10-14 00:30 UTC: London date Oct 14, New York Oct 13; requested midnight is computed from **local calendar**, not fixed 86,400 sec, and persisted check-in day key is stable.
  - New York spring and autumn 2026 DST: midnight delay is 22.5 / 24.5 hours from 00:30 local, next calendar day correct.
- First UI run selected five tests: **accessibility audit PASS**, **unified HealthKit editor PASS**, but **three old XCTest scripts failed** while typing without keyboard focus. The app deliberately does not autofocus the name field anymore; a user must tap it. Repaired **four test paths** to tap explicitly before typing (one extra large-text multi-check path proactively fixed), with no app runtime changes.
- Repeated the three failing selected UI tests: **3/3 PASS** (Spanish Create, Create/History, Largest Dynamic Type). The proactively updated **Five Multi-Check Buttons at Largest Dynamic Type** also passed in a separate UI run (1/1). Together with the two initial passing cases, **six distinct UI scenarios** now have successful executions. VoiceOver-specific runtime and widget-gallery physical checks remain open.
- Device read-only: physical iPhone 13 ChickMark **1.4.1 (14) installed**. No uninstall/reinstall, simulator cleanup on physical device, changed real Health consent, CloudKit fetch, Watch toggling or data restore.
- A6 static SDK: Info.plist / XcodeGen use **R-M-20183085-1**; code gates at 3 days, 5 foreground cold launches and 3 successful checkoffs. Real YAN partner dashboard and filled ad not verified (public partner login redirect is not evidence).
- **Sprint A acceptance remains open A1–A7** because existing automated coverage is not a physical CloudKit/Watch outage/denied-HealthKit/Lock Screen/live YAN/localization sign-off.

### Next safe physical acceptance (priority order)

1. **A1:** owner visually compare pre/post update history counts and old dates on iPhone; iCloud on a second enrolled device, without restoring backups. If only one enrolled device exists, mark cross-device CloudKit UNVERIFIED.
2. **A2:** use an expendable newly created habit and temporary Watch offline mode, restore normal connectivity, inspect both directions and ACK resolution. Do not use established habit data.
3. **A5 / A7:** install nonempty widget formats and visually inspect on iPhone, test languages / large font only if user allows display-preference changes.
4. **A4:** permission denial in a disposable test setup, not on owner's active Health permissions.
5. **A6:** YAN dashboard access or screenshot of placement/fill stats; never claim revenue from a successful SDK network request alone.
