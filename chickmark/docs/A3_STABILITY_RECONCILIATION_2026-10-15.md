# ChickMark — portfolio A3 closure evidence (2026-10-15)

**Owner:** Arvectum Tools. **Scope:** A1 read-only history and Cloud KVS resilience; A4 HealthKit; A6 Native YAN; A7 physical accessibility. Does not reopen previously closed Watch offline, midnight or widget checks.

## External release baseline

Authenticated read-only App Store Connect lookup on **2026-10-15**:
- Public: **1.4.0 (8)**, READY_FOR_SALE.
- **1.4.1 (15): IN_REVIEW** (previously WAITING_FOR_REVIEW); no production release confirmation.
- A3 source changes are **not contained in submitted build 15**. The approved NativeAd SDK integration is likewise newer than submitted build 15. Do not modify or resubmit the existing build.

## A1 / physical history baseline (read-only)

The owner's physical iPhone 13 was connected to authorized Mac mini via CoreDevice. The existing `ru.arvectum.tools.habits` container's `Habits.store`, WAL and SHM were copied **from** the device to an ephemeral, private Mac temporary directory. SQLite was opened in `mode=ro` and used for aggregate table counts **only**; no habit names, UUIDs, notes or health values were printed or uploaded, and temporary copies were deleted immediately afterward.

- `ZHABIT`: **4**; `ZHABITCHECKIN`: **19**; `ZHABITDAYMUTATION`: **20**; `ZHABITSKIP`: **0**; `ZHABITPAUSEPERIOD`: **0**.
- Consistent with the 2026-10-15 previous read-only physical offline-Watch QA snapshot: 4 habits, 19 check-ins and 20 day mutations. This proves only those counts at those instants; unchanged totals **do not prove record-for-record equality, history restoration, CloudKit replication, or post-upgrade preservation**.
- Physical second independent signed-in iPhone/iPad available to Mac mini: **none**. The paired Apple Watch is not an independent SwiftData CloudKit peer. **CloudKit two-device production convergence remains OPEN**. No CloudKit account reset, habit mutation, restore or app reinstall performed.

## A1 / new Cloud KVS corruption defense

`ChickMarkGroupCloudSnapshot.joined(with:)` initialized local group/membership dictionaries using `Dictionary(uniqueKeysWithValues:)`, which **traps** if decoded ledger records duplicate an ID. A previous upload/retry/corrupt or legacy JSON payload can contain repeated IDs and should not crash startup/reconciliation.

Changed the local-half reduction to fold every duplicate using the **existing** revisedAt/author/payload tie-breaking rule, then join with the remote snapshot. Tombstones and unassignments retain their deterministic precedence on exact ties.

- [x] Two additional unit tests exercise repeated IDs in decoded JSON, conflicting same-author/same-time edits, deletion/unassignment precedence and commutativity/idempotence. No iCloud credentials or records used.
- [x] Complete local iOS unit suite: **216/216 PASS**, no failures, isolated iPhone 17 simulator on iOS 27.
- [x] Generic iOS `build-for-testing`, architecture, SwiftPM lock catalog, RU/EN/ES localization, release hygiene and 12 Store screenshot checks PASS.
- [ ] Generic watchOS simulator build, GitHub CI/PR, GitVerse main SHA: attach final outcomes after execution.
- [ ] A1 real post-update before/after record identity check and actual second-device CloudKit propagation; no destructive device QA authorized.

## A4 / Apple Health permission

The prior owner-reported physical **first denial** and automatic fallback to manual mode were accepted on disposable test habit. Source includes fail-closed ephemeral projection and 22/22 HealthKit unit regressions PASS. On Apple platforms, **read-data consent status is deliberately not exposed as a reliable direct Boolean**. Do not treat an empty Health query as proof the user has revoked or permitted access.

- [ ] Physical previously-granted permission revoke/regrant remains OPEN and needs deliberate user action; do not change the owner's real HealthKit permissions remotely.
- [ ] No sample collection or export, no new HealthKit writes in this A3.

## A6 / Yandex Native ad

Existing verified unit R-M-20183085-1 is **Native**; the previously submitted ChickMark 1.4.1(15) predates the NativeAdState/NativeAdContainer fix. Developer demo creatives and simulated no-fill are not commercial fill/impressions. Eligibility gate and accessible pinned layout have prior simulated QA.

- [ ] Actual future release with Native implementation followed by genuine YAN unit-level fill/no-fill and partner-reported impressions/revenue remains OPEN.
- [ ] Do not generate fake ad traffic, change YAN placement, or click a real creative for acceptance.

## A7 / accessibility

Existing tests include actual simulator XCUIVoiceOverService and AXXXL RU/EN/ES, light/dark tests; these do not prove real device navigation. Do not toggle the owner's physical system VoiceOver or Dynamic Type without authorization.

- [ ] Physical VoiceOver, large text and supported-screen-size matrix remain OPEN.

## Release gate

Code and automated CI can close the **source regression portion** of portfolio A3. The **overall A3 physical/external acceptance is NOT closed** until A1 CloudKit second device, A4 revoke, A6 commercial ad placement and A7 physical accessibility are independently verified. Future patch requires a new build/version distinct from Apple's currently reviewed 1.4.1(15).
