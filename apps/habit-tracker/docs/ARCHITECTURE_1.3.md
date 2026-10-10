# ChickMark 1.3 — module boundaries and data contracts

**Status:** development-only. The published 1.2 release is unchanged. Never merge/publish this branch without release approval and device QA.

## Domain
- `HabitGoalMode`: single typed public domain abstraction. Its stored integer adapter preserves V1 storage (scheduled 0; weekly 1–7; after completion −1...−365; multi 1002–1005; count 3001–3100; duration 5001–5024).
- `HabitMetrics`, `HabitFrequency`, `HabitInsights`: pure date / calendar / progress calculations; no UI, network, ads or writes.
- `HabitMultiCheck`: deterministic UUID slot ledger. For binary habits target=1; for multi, target completion is N/N, never the first partial mark.

## Persistence and migrations
- `Models`, `SchemaVersioning`: the production-compatible SwiftData models. This branch adds **no new persistent SwiftData field**. Do not casually rename stored fields or change the CloudKit-visible model.
- `HabitCompletionMutation`, `HabitSkipMutation`, `HabitDayMutationLedger`: desired-state writes, day-level Last-Writer-Wins (updatedAt + mutation UUID) and skip/completion reconciliation.
- `ChickMarkBackup` + `ChickMarkBackupService`: independent serializable schema and persistence coordinator; explicit plaintext JSON, versioned, validated, merge or replace (replace is destructive and may sync via iCloud). Owned by the user; no Arvectum backend.
- `ChickMarkGroups` + `ChickMarkGroupsCloudSync`: optional local-first group projection in UserDefaults, plus an independent iCloud Key-Value Store LWW ledger with deletion tombstones and per-habit assignment records. This is separate from SwiftData/CloudKit models. Offline conflicts use timestamps and deterministic tie-breakers; clock skew, KVS quota, signed-device delivery and multi-device convergence remain release gates.

## Transport and adapters
- `Shared/HabitSyncProtocol`, `Shared/HabitWidgetBridge`: optional desiredCount is additive to the previous binary command wire format. Missing desiredCount means old whole-goal behavior. No breaking protocol-version change.
- `PhoneWatchSyncCoordinator`, `HabitWidgetCoordinator`: authoritative iPhone model runtime. No SwiftData writes from Watch/widget; durable ACK/retry queues remain bounded.
- `WatchHabitSyncStore`: optimistic offline cached state; partially increments count by issuing desired-state commands, not blind toggles. Reconciler discards stale commands and converges after ACK.
- `HabitReminderScheduler`: local notification windows / due logic only. Ads and cloud transport must never gate reminders.

## Presentation, localization and privacy
- `HabitsByArvectumApp` production bootstrap is separated from `HabitDebugFixtures` (DEBUG-only seed/diagnostic hooks); production release has no demo seeding code.
- `TodayView` orchestration, `TodayComponents` presentation rows, `HabitDetailView` read-only history and statistics, `HabitProgressEditor` historical N/N operations.
- `Localization` plus en/ru/es strings for iPhone, Apple Watch, widgets and Shortcuts. App Store text is **draft only**, not an uploaded release.
- Ad eligibility stays limited to 3 days, 5 cold launches and 3 completed habits. No interstitial/App Open/extra Progress ad without production retention evidence. Keep PrivacyInfo.xcprivacy audited against the final release artifact.

## Engineering rules
1. Small domain-focused modules; model writes isolated behind explicit mutation APIs.
2. Every new persistence or wire-format field requires backwards-decoding and repeated/offline command tests.
3. No model migration solely to support presentation/group folders.
4. Test calendar day identities and DST, not 24-hour arithmetic.
5. Changes land in short-lived branches, pass full simulator unit + UI accessibility tests and local archive smoke.
6. **Last acceptance step only**: an authorized physical iPhone plus iOS simulator for iCloud CloudKit/KVS convergence. A simulator's iCloud account availability may limit what can be proven. Do not replace the App Store app or delete its user data without a recoverable backup.
7. Do not automatically upload TestFlight/App Store bundles; explicit separate owner approval required.

## Audit and release readiness
- `scripts/audit_archive.py` checks four embedded executable bundles, version/build, and first-party PrivacyInfo manifests. This is a **static audit of the unsigned local archive**, not an Apple App Store Privacy certification or a full ad-SDK disclosure audit.
- `scripts/localization_audit.py` verifies RU/EN/ES key/printf parity and `scripts/archive_smoke.sh` invokes static archive auditing in CI.
- Active ad placement: Yandex sticky Today banner `R-M-20183085-1` behind the three-day/five-launch/three-completion gate. No Progress native ad unless real retention data warrants it.

## Modular refactor completed before physical acceptance
- Production bootstrap `HabitsByArvectumApp` separated from `HabitDebugFixtures` (DEBUG-only seeding and diagnostics).
- `ChickMarkBackup` defines the versioned JSON DTO and document wrapper, while `ChickMarkBackupService` owns SwiftData capture/restore with explicit merge/replace transaction logic.
- `HabitGoalMode`, `HabitInsights`, `HabitFrequency`, `HabitMetrics`, `HabitMultiCheck` provide distinct domain calculations independent of presentation.
- `TodayComponents` holds UI rows; the historical progress editor is a separate presentation module.
- `ChickMarkGroupsCloudSync` merges local-first KVS ledgers without changing the published SwiftData schema.
- `HabitAdSDK.initializeIfEligible` defers third-party SDK startup until the eligibility-gated banner mounts.
- CI checks RU/EN/ES string parity, App Store screenshot sizes, unit/UI regression and the four-target archive/privacy manifest audit.
- Deliberately retained orchestration files (`TodayView`, `HabitDetailView`, `AddHabitView`): split them further only when characterization tests justify it. A blanket file-count refactor would risk SwiftUI state regressions and undo previous QA.

## CI watchOS SDK selection
GitHub CI uses `xcodebuild -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test` without forcing `-sdk iphonesimulator`. Forcing the iPhone SDK onto the multi-platform app/Watch scheme makes Xcode 26.6 compile watchOS-only asset catalogs as an iPhone platform, producing a misleading `AppIcon did not have any applicable content` error. Auto-resolved SDK selection preserves the native watchOS icon assets; no icon/image files need replacement.
