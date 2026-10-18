# ChickMark CM18-3 — Apple Health dietaryWater: phase 1 simulator QA (18.10.2026)

**Scope:** feature/chickmark-water-export-20261018, draft PR #94 stacked on Core PR #90. NOT merged into stable main or submitted to Apple.

## User experience implemented

- Existing quantity habit → More actions → Export water to Apple Health. Disabled by default; user chooses 10–1000 millilitres per check-in. No inference from name/icon. RU, EN, ES localizations.
- Only explicit Save after enabling export asks HealthKit for dietaryWater WRITE authorization (no water read permission). Denial leaves no opt-in rule. On opt-out, a successful own-sample removal clears the receipt.
- Saved SwiftData check-ins reconcile to one daily aggregate HKQuantitySample at local midday. Never backfill days before opt-in.
- Each sample uses an app-owned habit/day identifier with increasing HKMetadataKeySyncVersion. Removal predicates require matching identifier and current app HKSource, in addition to HealthKit's own source ownership restriction.
- Durable pending write version covers crash after Apple Health accepted a sample but before the local success receipt; replays use a higher sync version, not blind duplicate inserts. Undo, changes, reverted counts, deletion of habits and opt-out are reconciled.
- No schema changes to SwiftData/CloudKit; not carried into Watch/ads/analytics.
- Isolated in-memory DEBUG fixture does not configure HealthKit writer and never requests permission.

## Local verification: Mac mini / Xcode 27.1 / iPad simulator

| Gate | Result |
| --- | --- |
| Pure opt-in and conversion | **12/12 PASS** |
| Fake HealthKit driver: permissions, errors, crash, undo, retry | **8/8 PASS** |
| Full ChickMark tests | **265/265 PASS**, no failures |
| Opt-in UI, default OFF, explicit ON, Cancel | **1/1 PASS** |
| iOS simulator build | **PASS** |
| Architecture/dependency checks | **PASS** |

iPad SwiftUI Stepper content is accessibility-grouped; the UI test targets the actual switch control and deliberately CANCELS, never pressing Save or granting real permission.

## Unverified release gates

- No real HealthKit authorization, writes or deletes were performed in this session. API signatures verified with installed iOS 27.1 SDK, but controlled real opt-in test of permissions, saved sample, correction, undo, revoked access and interrupted operation remains OPEN.
- Verify migration from published build, real ordinary iPhone/Watch/VoiceOver behavior, and consent wording before release.
- Apple is reviewing ChickMark 1.5.0 build 18: new upload requires a fresh build number and separate App Review, not a replacement of submitted bits.
- Combined Core PR #90 has queued macOS checks; this PR remains draft and is not eligible for main merge until CI and product QA are resolved.

Growth and Where? untouched.
