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
| Automated physical iPhone UI test | BLOCKED: XCTest timeout while enabling UI Automation, before assertions |
| Previously completed simulated iPad and standard iPhone UI | 2/2 per simulator, not equivalent to physical device acceptance |

Local artifacts, stored privately under ArvectumSSD/Arvectum/tmp on Mac mini:
- water-physical-build-20261018.log
- water-physical-units-20261018.log and xcresult
- water-physical-ui-retry-20261018.log and xcresult
- water-readiness-iphone13-20261018.json

The failed UI runner was removed from iPhone. The standalone QA app remains installed. No existing user app or medical data was removed or modified.

## Open acceptance gates

1. On the physical iPhone, check Settings > Developer > Enable UI Automation and leave the phone unlocked. Retry UI consent tests; do not change personal HealthKit permissions for this.
2. Real HealthKit dietaryWater authorization, sample write, same-day change/undo and own-sample deletion have NOT been performed. Before actual write/delete, obtain explicit consent in the isolated QA app's system permission prompt and use only disposable, distinctly identifiable test samples with guaranteed own-source cleanup. Do not read other Health entries.
3. Draft PR #94 is not ready for merge/release until live HealthKit acceptance and product CI finish; existing Store binary and CloudKit remain unchanged.

Growth and Where? untouched.
