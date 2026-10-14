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


## Follow-up A1/A4 regression evidence — 2026-10-14

- **Source:** based on origin/main `622f38c`, isolated worktree `test/chickmark-sprint-a-data-health-20261014`; no modification or install on the owner's physical iPhone/Watch, no CloudKit restore or permission change.
- **AUTO / A1:** added tests for idempotent JSON merge across habit/check-in/skip/pause/day-mutation/one-off reminder, preservation of receiving-device history and persisted date key; orphaned check-in rejected in both merge/replace modes **before modifying history**.
- **AUTO / A1+A4 privacy:** confirm raw measurements, ephemeral Health completion keys and progress do not appear in the JSON backup.
- **AUTO / A4:** missing readings yield an empty Health completion projection while preserving independent manual check-ins. This does **not** emulate a native HealthKit Deny/Revoke prompt; actual permission-state QA remains OPEN.
- **Verification:** focused ChickMarkBackupTests + HealthHabitIntegrationTests **22/22 PASS**, complete iOS unit suite **181/181 PASS**, architecture contract **PASS**, release hygiene **PASS**. On an unpaired iOS simulator WatchConnectivity logs a non-fatal `WCErrorCodeDeviceNotPaired`, not a test failure.
- **Local evidence:** `/Volumes/ArvectumSSD/Arvectum/builds/chickmark/sprint-a-data-health-20261014/` contains `focused.log`, `all-unit.log`, DerivedData / XCTest result bundles. No App Store archive or uploaded binary changed.
- **Outstanding:** A1 real-device historical counters, multi-device CloudKit and non-destructive upgrade; A4 native HealthKit Deny/Revoke on disposable simulator/device. A1 and A4 stay OPEN until their appropriate acceptance evidence exists.


## A3/A5/A7 follow-up: widget midnight tap + localization/accessibility — 2026-10-14

- **Baseline:** origin/main `566ac94`. Isolated worktree: `test/chickmark-sprint-a-widget-a11y-20261014`. No physical iPhone/Watch installation, HealthKit permissions, iCloud/CloudKit, App Store binary or private records changed.
- **A3/A5 fix:** old/future WidgetKit timeline buttons are rejected at `ToggleHabitWidgetIntent.perform()` execution against the current **local** day. Instead of appending a command, mutating an old day or applying stale optimistic counts, the widget requests a timeline reload. This protects the midnight / timezone-change interval while keeping today's normal intent flow.
- **A5 accessibility:** small Home widget progress ring exposes a localized accessibility label/value (RU/EN/ES); no new privacy-bearing shared state or persistence.
- **AUTO:** two deterministic cases verify no old/future-day queued commands, no processor call and no optimistic mutation, plus London/New York local-day divergence at the October 2026 DST boundary. Complete iOS unit suite: **183/183 PASS**; WidgetKit extension compiled/linked in the tested app. Architecture, release hygiene, RU/EN/ES localization, and 12 store screenshot assets all **PASS**.
- **SIM / iPhone 13 (iOS 27):** rerun accessibility audit of Today/Manage/Detail/Create and full seeded RU/ES screenshot navigation: **3/3 PASS**. Separate EN screenshot navigation with simulator appearance set to **dark**: **1/1 PASS**. Audit retains the existing *known* exception for SwiftUI's programmatic contrast check on the enabled mint "Done" pill, which was visually assessed previously; this does not represent unqualified zero-issues VoiceOver acceptance. Ten captured RU/ES screenshots exported from XCTest bundle, including full populated Today screens.
- **SIM / infrastructure limitation:** first combined UI run on iPhone 18 Pro stopped before test assertions with Xcode `XCTDaemonErrorDomain Code=18: Timed out waiting for AX loaded notification`. After moving to iPhone 13, accessibility audit and UI screenshot tests passed, but a separate native `XCUIVoiceOverService` execution stalled in simulator accessibility initialization; stopped without reporting it PASS. Real VoiceOver navigation remains **OPEN**.
- **Evidence:** `/Volumes/ArvectumSSD/Arvectum/builds/chickmark/sprint-a-widget-a11y-20261014/` (`units-a5.log`, `localization.log`, `release-hygiene.log`, `architecture.log`, `store-assets.log`, `ui-a7-light.log`, `ui-a7-retry-iphone13.log`, `ui-a7-dark-voiceover.log` and `qa-screenshots/`). Unit `xcresult` remains under the existing Sprint A local DerivedData.
- **Still OPEN:** A5 actual populated small/medium widget and three Lock Screen widget family **rendering and interaction**, including day rollover on a real device; A7 native VoiceOver narration, Dynamic Type and dark/light physical acceptance. Deterministic tests and static localization cannot substitute for those checks. No new public App Store build created.


## A3 completion-relative schedules / DST / partial goals — 2026-10-15

- **Baseline:** `origin/main` commit `5588db2`; isolated worktree `test/chickmark-sprint-a-dst-interval-20261014`. No changes to production code, target versions, CloudKit, user habits or physical system timezone.
- **AUTO (five new XCTest cases):** New York spring (23-hour day) and autumn (25-hour day) check-ins with sliding recurrence after two local *calendar* days rather than fixed 48 hours; overlapping early/late/future records and the actual latest in-range completion; original saved London day key after travel to Los Angeles; multi-check 4/5 remains incomplete through DST/timezone travel, then 5/5 completes only the intended local day; widget horizon changes at New York local midnight after autumn DST and refuses stale-day actions.
- **Results:** 39/39 focused XCTest, **188/188 full iOS unit XCTest** with zero failures, architecture contract and en/ru/es localization resource audit PASS. Nonfatal `WCErrorCodeDeviceNotPaired` from unpaired simulator is not physical Watch evidence.
- **Evidence (Mac mini local):** `/Volumes/ArvectumSSD/Arvectum/builds/chickmark/sprint-a-dst-interval-20261014/focused-tests.log`, `all-unit.log`, `architecture.log`, `localization.log`; XCTest result bundles in the existing local DerivedData path.
- **Status:** A3 deterministic regression suite expanded; live Simulator WidgetKit refresh at a forced rollover and physical Watch/iPhone day-transition acceptance are still **OPEN**. Do not claim automatic background delivery or a real Lock Screen rendering pass from these unit tests. Submitted 1.4.1 (15) unchanged.


## A4 unavailable HealthKit projection regression — 2026-10-15

- **Baseline:** origin/main b1f1123. All CI jobs in previously merged PR #45 and #46 passed, including build-and-test.
- **Defect and correction:** HealthHabitCoordinator.reconcile() previously exited on unavailable HealthKit without clearing old automatic completions or transient progress. The unavailable path now uses the same invalidation as having zero rules; clears cached Health widget overlay, signals iPhone/Watch/WidgetKit, and refreshes reminders. No manual SwiftData history, privacy permissions, Health samples or public 1.4.1(15) binary were modified.
- **AUTO:** Two helper regressions verify fail-closed transient completion/progress state and idempotency while preserving manually saved check-ins. A third integration test exercises actual coordinator.synchronize() against in-memory SwiftData with test-only injected Health unavailability. Debug-only injection hooks are excluded from Store builds.
- **PASS:** HealthHabitIntegrationTests 19/19, complete iOS unit suite 191/191, architecture, release hygiene.
- **Evidence:** /Volumes/ArvectumSSD/Arvectum/builds/chickmark/sprint-a-health-unavailable-20261015/ (focused-integration.log, full-verified.log, architecture.log, release.log).
- **Still open A4:** simctl privacy offers motion but no HealthKit permission service. The OS-native denial/revocation sheet and independent Watch/Lock Screen refresh are not yet physically/simulator verified. Do not change the owner's Health permissions.


## A2 offline durable-transfer queue dedup — 2026-10-15

- **Baseline:** origin/main commit 4da5620. Isolated worktree fix/chickmark-watch-durable-dedup-20261015. No physical devices or user records modified; App Review build 1.4.1 (15) remains unchanged.
- **Observed risk:** WatchHabitSyncStore.resendPendingDurably previously canceled ALL outstanding userInfo transfers for the same habit/day (including identical command ID) on every offline refresh, and immediately re-enqueued the same packet. Repeated refresh under bad connectivity could delay guaranteed delivery and ACK.
- **Correction:** shared pure HabitDurableDeliveryPlan distinguishes identical already-queued transfer IDs from superseded IDs. Repeated identical transfer is retained; superseded commands for the same habit/day are canceled, while independent habit/day transfers remain in place. updateApplicationContext and transferUserInfo are performed for new transfers only. Existing phone-side mutation ledger, ACK semantics, queue size and snapshot protocol stay unchanged.
- **AUTO:** three new regression tests for idempotent repeated refresh, check-to-undo replacement scoped by habit/day, and repeated partial-goal (1/5 to 3/5) delivery. **PASS** focused HabitSyncProtocolTests 22/22; complete iOS unit suite 194/194; standalone generic watchOS Simulator build; architecture contract and release hygiene.
- **Evidence:** /Volumes/ArvectumSSD/Arvectum/builds/chickmark/sprint-a-watch-durable-dedup-20261015/ (focused.log, full-unit.log, watch-build.log, architecture.log, release-hygiene.log).
- **Still OPEN:** on-device offline-to-online delivery/ACK and transient WatchConnectivity scheduling, including airplane mode and a Watch app restart, require simulator pair or physical-device smoke; these cannot be asserted from a pure plan unit test. A2 not marked fully accepted.
