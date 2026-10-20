# Design → localization integration checkpoint

Date: 20.10.2026. Repository: arvectum-tools. Branch: feature/portfolio-design-i18n-20261020.

## Baselines and sequencing

- Design source: feature/unified-design-system-20261019 at ce5cd1f; its D4.6 simulator acceptance remains subject to physical G1–G3 and review G4.
- Localization source: feature/portfolio-i18n-50 at 79a8b26, integrated by merge 99e7b83.
- Feature-only integration: no App Store/TestFlight/review/public metadata changes.
- Pushkin project regenerated with XcodeGen to reconcile Core sources and new English catalog.

## Localization completed

- 50-pack registry and shared iOS catalog audit, plus four new English What keys from merged design.
- Android Photo Resizer: 93 English and Russian resource keys. Default values/ is English, values-ru/ Russian; Compose UI, statuses and formatted sizes now use resources.
- Typed Android errors and fallbacks now use resource IDs, to follow device locale.
- Localization CI watches Android resources; audit checks parity, format args, references and untranslated Compose literals.

## Checks

- SwiftPM Core: swift test --package-path core, 21/21 PASS on merged branch.
- Python localization: 4/4 tests PASS, shared catalog audit PASS including Android.
- Android Mac mini/JDK 17/SDK 37: assembleDebug and testDebugUnitTest BUILD SUCCESSFUL. Log: /Volumes/ArvectumSSD/Arvectum/tmp/portfolio-design-i18n-qa-20261020/android-final4.log.
- Android device visuals and full post-merge iOS build matrix remain separate validation gates. Do not attribute older four design-branch build results to the merge.

## Open next

1. Finish dynamic SwiftUI/localized source extraction, and then create genuine reviewed translated catalogs for each locale tier.
2. Android's remaining 48 packs, legal/permission wording, plural rules and RTL QA.
3. iOS/watchOS/widgets/Shortcuts localization and screen-reader/large-text checks.
4. Independent review and explicit per-release owner authorization.

## Post-merge iOS compile qualification

After merge, building the ArvectumNotify iOS target succeeded. Other attempted merged-tree iOS builds are **not accepted**: ChickMark and Photo encountered a KSCrash Swift Package header-search failure (`KSCrashNamespace.h`) in target-only builds using shared DerivedData; a generic simulator scheme invocation also could not compile the watchOS app icon as an iOS asset, and the What build was interrupted. These attempts do not prove an i18n source regression, but must not be counted as green merged-tree builds. A clean app-scheme iOS simulator matrix remains an explicit pre-integration gate. Earlier D4.6 4/4 PASS describes the unmerged design source only.

Final Android repeat (after removing Russian-only unused SizeUnit labels): `android-final5.log`, `assembleDebug` and `testDebugUnitTest` BUILD SUCCESSFUL, 6 JVM tests; app source was not published.
