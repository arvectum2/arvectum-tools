# ChickMark CM18-3 — physical iPhone 13 QA (18 October 2026)

## Device and isolation

- Mac mini, Xcode 27.1, physical iPhone 13 with iOS 27.0.1, developer mode enabled and paired. No unique device ID recorded in this file.
- Existing ChickMark Review QA, UhWhat, Pushkin and user data preserved.
- Installed isolated ChickMark Water QA 1.5.0(201), bundle ru.arvectum.tools.chickmark.waterqa. Own private container, no App Groups, CloudKit, push notifications or Watch/widget targets.
- Confirmed Apple Development signature and only HealthKit-specific entitlement com.apple.developer.healthkit=true. No App Store Connect changes.
- QA project: chickmark/ios/project.water-physical-qa.yml, generated with XcodeGen. Probe is compiled only with DEBUG && WATER_PHYSICAL_QA, gated by --ui-testing --water-readiness and exact QA bundle identifier.

## Physical results

| Verification | Result |
| --- | --- |
| CoreDevice connection, signing and physical app install | PASS |
| Arm64 physical iPhone build | BUILD SUCCEEDED |
| Water export isolated XCTest (planning, opt-in, fake HealthKit, undo, crash/retry, corrupted ledgers) | 31/31 unit PASS, zero failures |
| Actual device HKHealthStore.isHealthDataAvailable | TRUE |
| Physical dietaryWater write authorization for QA app | notDetermined, raw value 0 |
| Probe requested HealthKit permission or read/wrote/deleted a sample | NO, all flags false |
| Automated physical iPhone UI test (initial attempt) | BLOCKED: XCTest timeout enabling UI Automation before assertions |
| Automated physical iPhone UI retry after owner enabled UI Automation | **2/2 PASS, zero failures**; export OFF by default and denied-write leaves opt-in OFF |
| Previously completed simulated iPad and standard iPhone UI | 2/2 per simulator, not equivalent to physical device acceptance |

Local artifacts, stored privately under ArvectumSSD/Arvectum/tmp on Mac mini:
- water-physical-build-20261018.log
- water-physical-units-20261018.log and xcresult
- water-physical-ui-retry-20261018.log and xcresult
- water-readiness-iphone13-20261018.json

The failed first-run UI runner was removed from iPhone. After owner enabled UI Automation and explicitly requested another run, the physical retest passed **2/2** with TEST SUCCEEDED. The standalone QA app remains installed. No existing personal app or medical data was removed or modified.

Latest physical UI log and xcresult: water-physical-ui-after-toggle-20261018.log and water-physical-ui-after-toggle-20261018.xcresult on Mac mini ArvectumSSD. Both testDeniedPermissionDoesNotPersistOptInOrOpenHealth and testQuantityHabitHasWaterExportScreenButNoAutomaticPermission passed. The DEBUG --ui-testing guard intercepted permission requests; no real HealthKit authorization or sample operations occurred.

## Live HealthKit acceptance (20:20 MSK, 18 Oct 2026)

The device owner approved native write-only HealthKit permission for independently signed **ChickMark Water QA** on physical iPhone 13. The isolated DEBUG-only probe was armed ONLY with explicit --ui-testing --disable-cloud-sync --water-live-qa arguments and exact ru.arvectum.tools.chickmark.waterqa identity.

A one-time journal was persisted BEFORE the actual operation (identifier private to this QA bundle). The probe exercised the **production WaterHealthKitWriter**:
- requestWriteAccess(): system native consent, without requesting READ permissions.
- upsert(): a single synthetic 250 mL dietaryWater quantity with unique metadata sync identifier/version 1.
- removeOwn(): deletes matching identifier scoped to the application's HKSource.default(), never another app's samples.
- Independent second own-ID source-scoped deleteObjects verification returned exactly **0 residual items**.
- Journal: stage=completedClean, saveCompleted=true, ownDeletionCompleted=true, residualOwnSamples=0. No retry or additional writes occurred.
- No user's pre-existing medical records were read. The QA file remained in its private app Documents directory. Existing production ChickMark and Watch data were not altered.

Evidence retained privately under ArvectumSSD/Arvectum/tmp/chickmark-water-live-build-20261018.log and chickmark-water-live-report-snapshot5-20261018.json. The probe includes a persistent one-shot journal and fail-closed cleanup-recovery state for interruption between save and delete.

**Live write + own sample deletion ACCEPTED.** Testing denial/revocation from iOS Settings, same-day edits across several checkins, and app life-cycle interruption after save remain independent gates. This does not claim that all production water-export UI journeys are accepted.

## Open acceptance gates

1. **CLOSED:** Owner enabled Settings > Developer > Enable UI Automation; physical consent UI tests **2/2 PASS**. No personal Apple Health settings changed.
2. **CLOSED:** Real write-only HealthKit permission, one disposable 250 mL dietaryWater sample and exact own-source deletion were verified, with zero residual. Still OPEN: multiple checkins/edit/undo via the actual habit UI, permission revoke/regrant, and interruption recovery.

3. Draft PR #94 is not ready for merge/release until live HealthKit acceptance and product CI finish; existing Store binary and CloudKit remain unchanged.

Growth and Where? untouched.
