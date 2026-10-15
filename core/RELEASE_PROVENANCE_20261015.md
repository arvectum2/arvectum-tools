# Release provenance and source integration — 2026-10-15

## Verified sources and release state

Evidence recorded from authenticated read-only App Store Connect API, local signed distribution IPA metadata/checksums, Git history, GitHub Actions and GitVerse remote refs. An IPA SHA matching a release receipt proves the archived bytes, **not** that a new build from tagged source is bit-identical or that a physical device QA has passed.

| App | App Store state (API, 2026-10-15) | Source tag / commit | Local IPA SHA-256 | Actual metadata |
| --- | --- | --- | --- | --- |
| Фото и PDF под размер | **1.0.1 READY_FOR_SALE**, build 13 VALID | `photo-size-ios-v1.0.1-build13` → `fa837b3` | `4672c7d1cc7bd75453638baf590fbdf3382a2cf8291e37721ad041562a0c74a2` | ru.arvectum.tools.tosize, 1.0.1 (13) |
| Ухват / UhWhat? | **1.0.0 READY_FOR_SALE** | `uhvat-ios-v1.0.0-build5` → `8b7df3e` | 1.0.0 IPA not re-hashed in this checkpoint | ASC 1.0.0 build 5 VALID |
| Ухват / UhWhat? | **1.0.1 WAITING_FOR_REVIEW**, build 6 VALID | `uhvat-ios-v1.0.1-build6` → `daf98c0` | `fc9ac8de8c9e1fa5d74a1b3df6ab5b8aa8d00a2e320c5440b498d7eb20378180` | ru.arvectum.tools.what and embedded Watch app, 1.0.1 (6) |
| ChickMark | **1.4.0 READY_FOR_SALE; 1.4.1 WAITING_FOR_REVIEW**, build 15 VALID | `chickmark-ios-v1.4.1-build15-submitted` → `498a072` | `c380fdbf2da5a6dd94416273dfc2e7743e717d0e90d41cc41dfe9cfa92f1c5c0` | ru.arvectum.tools.habits and embedded Watch app, 1.4.1 (15) |
| Pushkin | **1.0 WAITING_FOR_REVIEW**, build 1 VALID | not tagged as a public release | not independently re-hashed | ASC App ID 6817847111 |

ASC App IDs: Фото/PDF 6816346084, Ухват 6822476399, ChickMark 6818711298, Pushkin 6817847111. The submitted/public releases should not be silently updated or assumed physically accepted just because they are VALID/READY_FOR_SALE.

## GitHub ↔ GitVerse mirror

GitHub Actions [mirror-to-gitverse.yml](../.github/workflows/mirror-to-gitverse.yml) runs on each branch/tag push, on demand and daily, and verifies main SHA. During A0, remote GitVerse `refs/heads/main` equals GitHub `586934a4bd2775ee96cebf6a61a892fd74c6d1ad` **before** the integration commit; GitHub mirror workflow 38752808387 completed SUCCESS. Four release tags have now been independently confirmed in GitVerse with peeled SHA matching GitHub: `photo-size-ios-v1.0.1-build13`→`fa837b3`, `uhvat-ios-v1.0.0-build5`→`8b7df3e`, `uhvat-ios-v1.0.1-build6`→`daf98c0`, and `chickmark-ios-v1.4.1-build15-submitted`→`498a072`. The GitVerse **integration branch** matched `5228a44` after the signing follow-up; after [PR #67](https://github.com/arvectum2/arvectum-tools/pull/67) merge, GitHub and GitVerse `refs/heads/main` were both verified as `e129efc00614322f1faa6b139b4345efcddfa490` on 2026-10-15.

## Selective production source integration to main

- **Фото/PDF:** imported release-specific App Store report, 1.0.1 localization/metadata file, release automation support for version/build parameters, and the signed Release configuration (`Apple Distribution`, manual provisioning) into the **current Core-enabled XcodeGen specification**; regenerated the matching Xcode project without reverting modern Core SwiftPM dependencies. **Did not import** the old 1.0.1 Xcode project or its direct-palette implementation: canonical main already uses reviewed ArvectumCore SwiftPM (2026-10-13). The public IPA remains the source of truth for its shipped binary.
- **Ухват:** imported release-proven iOS and watchOS app/extension code, localization, privacy manifests, brand assets, recording, transfer, widgets, Inbox and tests from `release/what-1.0.1`. Kept current main product roadmap (including note reminders and ChickMark handoff) and source domains unchanged. Included only P0 release source documentation; no research pipeline or private RuWordNet corpus copied.
- **ChickMark:** no release-branch merge: build15 source branch was already an ancestor of main. Fixes committed in main after upload, including Native Ads, **are not in the App Store build15**. A new patch release is necessary for them.
- **Pushkin/Where?:** no application source modifications. Where? remains paused.

## Engineering acceptance for imported source

- [x] Repo architecture contract: PASS.
- [x] SwiftPM shared dependency lock catalog: PASS.
- [x] WhatIOS: generic iOS Simulator Debug build PASS (Xcode 27, no signing).
- [x] WhatWatch: generic watchOS Simulator Debug build PASS (Xcode 27, no signing).
- [x] Фото/PDF: generic iOS Simulator build-for-testing PASS and generic iOS Release-configuration build PASS (Xcode 27, test signing disabled).
- [x] No ignored/untracked `RussianConceptGraph.json` or derived RuWordNet corpus in imported source or inspected signed IPA.
- [x] [PR #67](https://github.com/arvectum2/arvectum-tools/pull/67) merged 2026-10-15 at `e129efc`. All PR checks PASS. [Core CI 38756915944](https://github.com/arvectum2/arvectum-tools/actions/runs/38756915944) **SUCCESS, 10/10 jobs**: Core tests, Android, iOS consumer builds for all four apps, watchOS builds for What/ChickMark, and iOS behavioral/persistence tests for What/ChickMark. This is automated/simulator evidence, **not physical device QA**.
- [ ] Independent physical UI, cloud sync, permission and advertising acceptance remain application-specific tasks.
- [ ] Reproducible bit-for-bit rebuilding / supply-chain attestation not yet established.

## A0 closure and remaining release gates

- [x] Signed IPA checksums and metadata, ASC states, release source tags, GitHub/GitVerse main SHA and CI checked on 2026-10-15.
- [x] Selective source integration merged; no user-device changes or modification of previously submitted App Store IPA.
- [ ] Deterministic bit-for-bit rebuild of the previously submitted IPA needs separate signing/reproducibility attestation.
- [ ] Real-device capture/storage, CloudKit/HealthKit authorization, and production advertising acceptance remain under app-specific A1–A4. Unapproved submitted updates are not public releases.

See [A0 branch inventory](RELEASE_SOURCE_AUDIT_20261015.md) and [execution plan](EXECUTION_PLAN.md).
