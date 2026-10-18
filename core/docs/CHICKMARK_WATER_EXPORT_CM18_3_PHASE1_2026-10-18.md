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
| Pure opt-in and conversion, including deleted-habit ledgers | **13/13 PASS** |
| Fake HealthKit driver: permissions, errors, crash, undo, retry | **8/8 PASS** |
| Full ChickMark tests | **276/276 PASS**, no failures |
| Opt-in UI, default OFF, explicit ON, Cancel on iPad | **1/1 PASS** |
| Safe opt-in and denied-permission UI on iPad | **2/2 PASS** |
| Safe opt-in and denied-permission UI on ordinary iPhone 17 Pro | **2/2 PASS** |
| iOS simulator build | **PASS** |
| Architecture/dependency checks | **PASS** |

The compiled app's localized InfoPlist.strings resources for en, ru and es were directly verified: all system HealthKit write-permission descriptions disclose adding water. scripts/localization_audit.py now prevents a false promise that the phone app never writes health data. Watch stays read-only.

When a habit is deleted, obsolete local export settings are cleared only after all owned HealthKit samples and pending write intents have been successfully cleaned; failures retain receipts for retry.

Additional defensive QA: the DEBUG-only --ui-testing route rejects WRITE authorization before it can touch HKHealthStore, even if an automated test clicks Save. A second UI test on both iPad and ordinary iPhone confirms a denied permission produces a visible error and **does not persist** a per-habit opt-in rule. No Apple Health permission prompt or sample operation occurred in either simulator test. Normal Release builds do not include the test-only authorization guard.

iPad SwiftUI Stepper content is accessibility-grouped; the UI test targets the actual switch control and deliberately CANCELS, never pressing Save or granting real permission.

## Fail-closed SwiftData read hardening

Important fix: the previous best-effort SwiftData fallback could interpret a storage error as a genuine empty habit/check-in list, potentially deleting valid Apple Health water samples. WaterExportSnapshot.load now returns no snapshot on either query failure. The coordinator stops reconciliation without changing samples or receipts. Legitimately empty query results are distinct from errors.

- Four additional tests inject failed habit reads, failed check-in reads, and valid empty/nonempty reads.
- Isolated iPad QA: **270/270 ChickMark unit PASS** (previous 266 + 4) and **2/2 export/denial UI PASS**. No real Apple Health data touched.
- An unrelated pre-existing CrossSurfaceDurabilityTests intentionally forces a read-only SwiftData store error; the suite completes successfully.

## Corrupted local ledger hardening

WaterExportLocalStore now exposes a fail-closed canSafelyReconcile guard. Persisted JSON for all three maps (per-habit consent rules, successful own-sample receipts, interrupted-write versions) must decode successfully **before any HealthKit upsert, delete or local receipt cleanup**. A corrupted map is not assumed to mean an empty map. Missing keys from a fresh, never-opted-in installation remain valid and do not block startup.

- Tests cover damaged consent JSON with a valid own-sample receipt; corrupt receipts and pending-intent maps; and a fake HealthKit writer that must observe **zero** upserts and deletions if consent cannot be read.
- Following this change: **276/276 ChickMark unit PASS** and **2/2 iPad opt-in/denial UI PASS**; no actual HealthKit data accessed.

## Manual settings cannot overwrite unreadable ledgers

The per-habit settings editor now refuses Save before a HealthKit authorization prompt if any consent/receipt/pending-write JSON is damaged, and the local rule setter itself returns failure without modifying the original bytes. The editor shows a localized recovery message in RU/EN/ES instead of dismissing and claiming an export was enabled. The protection also applies to opt-out: a corrupt receipt must remain available for later recovery.

- One added unit test verifies corrupt consent is preserved after attempted enable and disable, and a corrupt receipt prevents overwriting a healthy opt-in.
- **276/276 ChickMark unit PASS**, **2/2 iPad export/denied-permission UI PASS**. CI localization and release hygiene audits PASS.

## Same-day undo and re-entry preserves HealthKit sync versions

A daily quantity sample keeps the same deterministic app-owned sync identifier even if the user first removes all check-ins and then adds water again that day. To avoid reusing old HealthKit metadata versions, WaterExportLocalStore now retains a local monotonically increasing highest-version watermark per habit/day **after the sample receipt was deleted**. The next upsert chooses a strictly newer version than the previous successful or interrupted attempt. This fourth small local ledger also participates in the fail-closed corruption guard.

- Tests cover write (version 1) → delete → new same-day water quantity (version 2), version watermark not decreasing when a receipt is cleared, and corrupted watermark JSON prohibiting reconciliation.
- Isolated iPad simulator full suite: **276/276 unit PASS**. **2/2 opt-in/denied UI PASS** if confirmed in the final xcresult.
- HealthKit replacement semantics are only validated against fake drivers and the installed iOS SDK; real Apple Health behavior remains a release acceptance blocker.

## Unverified release gates

- No real HealthKit authorization, writes or deletes were performed in this session. API signatures verified with installed iOS 27.1 SDK, but controlled real opt-in test of permissions, saved sample, correction, undo, revoked access and interrupted operation remains OPEN.
- Verify migration from published build, real ordinary iPhone/Watch/VoiceOver behavior, and consent wording before release.
- Apple is reviewing ChickMark 1.5.0 build 18: new upload requires a fresh build number and separate App Review, not a replacement of submitted bits.
- Combined Core PR #90 has queued macOS checks; this PR remains draft and is not eligible for main merge until CI and product QA are resolved.

Growth and Where? untouched.
