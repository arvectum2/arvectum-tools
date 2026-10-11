# ChickMark — reproducible SwiftPM dependencies

Inventory checked 2026-10-10:

| Dependency | Role | Locked version |
| --- | --- | --- |
| Yandex Mobile Ads | direct | 8.5.0 |
| AppMetrica | transitive | 6.7.0 |
| KSCrash | transitive | 2.5.1 |
| Google User Messaging Platform | transitive | 3.1.0 |
| SwiftProtobuf | transitive | 1.38.1 |

Yandex Ads 8.6.0 is available, but a third-party SDK upgrade and changed privacy requirements must be separately reviewed, not silently shipped.

The project.yml direct dependency now uses a compatible-major semver minimum rather than exactVersion, branch or revision. The **tracked** ios/Package.resolved locks all five package versions and source commit revisions. Generated Xcode projects remain ignored.

Always invoke scripts/generate_project.sh, which copies the committed lockfile into the Xcode workspace and audits it. CI and archive use -onlyUsePackageVersionsFromResolvedFile: normal builds cannot silently update the graph. To review updates in an isolated branch: run scripts/update_dependencies.sh --review 8.6.0, inspect the Package.resolved diff, vendor privacy/ATT/IDFA declarations and API changes, then run simulator test suites and archive. Never merge a lockfile update just because a newer release resolves.

Canonical toolchain Xcode 27; iOS 17.0 and watchOS 10.0 are **deployment minimums**, not Xcode or third-party SDK versions. Marketing version 1.3.0 / build 5 is separately pinned release metadata. SwiftUI, SwiftData, WidgetKit and WatchConnectivity belong to Apple SDKs.

The advertising SDK is confined to HabitAdvertising.swift, not imported into domain, persistence, widgets or Watch. Schema, stable check-in UUIDs, offline sync packets and backup compatibility remain release invariants. App Store submission requires explicit approval.

## Upgrade rehearsal result

A Yandex 8.6.0 candidate was resolved separately on 2026-10-10. It introduces Tapjoy/swift-packages 14.8.0 as a sixth dependency. The default dependency_audit.py correctly **blocks** this unreviewed new graph, leaving the production 8.5.0 lock untouched. Even if it compiles, do not automatically approve this new advertising dependency without a vendor privacy/security and distribution-size review.

**Candidate test evidence:** 8.6.0 / Tapjoy 14.8.0 resolved and built successfully for iOS Simulator under Xcode 27, but the approval gate intentionally failed because of the unapproved new package. This is a compile-level compatibility check, not a complete runtime, privacy, performance or ad-fill acceptance test. Stable 8.5.0 lock is unchanged.
