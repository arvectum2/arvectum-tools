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


## L2 follow-on — same day

- Reviewed remaining interpolation in active SwiftUI screens. Added
  core/tools/localization_portfolio.py --inventory-dynamic and a JSON source
  risk register (17 candidate expressions at this checkpoint); it is not a
  complete translation catalog.
- Added Pushkin pc() literal extraction (+70 previously omitted English keys,
  now 151 in its main bundle) and made its group label a position-independent
  format string: Group %d / Группа %d.
- What displayed note counts now inflect 1/2/5/11/21 correctly in Russian and
  1 vs several in English; language-specific unit checks added. Remaining
  locales and native .stringsdict plurals are unimplemented.
- Xcode iOS build on clean, isolated derived data after merge: Pushkin,
  Photo/PDF, and What simulator app schemes succeeded. Prior tests from
  unmerged design branch do not count towards these.
- ChickMark's clean merged branch app-scheme build still requires retry;
  the previous build was interrupted, and target-only retries had a KSCrash
  header error. Do not mark four of four green yet.
- Device, live integration and release gates remain unchanged.


## L3.1 Spanish Android source pack

- Added complete Spanish values-es/strings.xml with 93 genuinely translated
  UI, status, sizes and processing-error phrases, not English copies.
- English/Russian/Spanish resource keys and format arguments pass the shared
  localization audit; six Python localization tests pass.
- Android Gradle assembleDebug and testDebugUnitTest are green with Spanish
  resources; log android-spanish.log.
- Draft needs human editorial/physical-device review. No store submission.
- ChickMark's merged simulator build remains unconfirmed because the last
  attempt was interrupted without a successful exit status.


## Final checks and design follow-up

- Pushkin with the new Group format compiled successfully on an isolated
  iOS Simulator build (pushkin-l2.log).
- What with corrected note counts compiled successfully in an isolated iOS
  Simulator build (isolated-what-v2.log). Direct Foundation/Swift binary QA
  validated 12 Russian and English count cases. The targeted XCTest attempt
  was interrupted, so it is not reported as a passing XCTest suite.
- Android file-size UI was made more localization-friendly: three mode
  controls grow vertically, allow up to three lines, primary/secondary
  buttons use minimum heights instead of fixed heights, and the header can
  wrap its translated title. Final offline Gradle build and 6 JVM tests are
  green in android-spanish-layout-final.log.
- English default Android locale remains unchanged for unsupported system
  languages. Neither Spanish screen QA nor native translator review is done.


## L2.4–L2.5: Russian UI catalogs and dynamic text

- Current merged feature branch iOS builds: ChickMark
  chickmark-v4.exit=0, Pushkin pushkin-ru-retry.exit=0,
  What what-l2-final-catalog.exit=0 and Photo/PDF
  photo-l2-final-catalog.exit=0. Build artifacts remain on ArvectumSSD
  in Arvectum/tmp/portfolio-design-i18n-qa-20261020.
- Pushkin now has 151 Russian keys: 143 from existing bilingual microcopy
  and 8 new source-complete translations. Compiled app has EN/RU resources.
- What now has RU catalogs in iPhone (204 keys), Watch (6), Phone Widget
  (6) and Watch Complication (5), confirmed in compiled app bundles.
  Ambiguous shared words such as Archive and Discard need contextual QA.
- Dynamic bilingual strings now use whole formatted sentences for Watch
  transfer state, local recorder route, screen reader filters, search
  counters, interrupted video recovery and speech transcription errors.
- Photo/PDF has four positional-format UI metadata templates and properly
  inflected Russian PDF page counts including 2, 11 and 21. Source-level
  unresolved interpolation candidates dropped from 17 to 5 (the remaining
  simple numeric SwiftUI expressions are in ChickMark). Computed strings
  beyond these source patterns still require review.
- Source structure/placeholder and native bilingual-copy consistency
  checks pass, Python 8/8. Xcode xcresult test summaries verified:
  Photo PDF morphology 1/1 PASS and What language fallback/dynamic format
  4/4 PASS, no failures.
- Language QA, visual tests, physical Watch, real Shortcuts/Files and
  separate independent release approval remain open. Nothing is
  merged into main or submitted to App Store.

## L3.2–L3.3 follow-on: es_ES iOS Photo, pt_BR Android Photo

- iOS Photo/PDF: authored a real Spanish copy pack of 155 Localizable
  keys; translated CFBundleDisplayName and NSUserTrackingUsageDescription
  in es.lproj/InfoPlist.strings. XcodeGen project updated, both resources
  present inside the built PhotoPodRazmer.app; Debug Simulator build PASS.
- Run app with -AppleLanguages (es), -AppleLocale es_ES:
  simulator consent sheet displays the full Spanish privacy disclosure
  and both reachable choices. Screenshot photo-es-consent-simulator.png
  saved in temporary external SSD QA directory after taking it in /tmp.
- SpanishLocalizationUITests covers synthetic photo and PDF workflows
  end-to-end with locale override and screenshot attachments. Both
  targeted UI test cases passed in Test-PhotoPodRazmer result at 22:28.
- Android pt-BR 93 natural-language source translations in
  app/src/main/res/values-pt-rBR/strings.xml, including processing errors,
  dimensions and localized format placeholders; aapt2 dump confirms
  pt-rBR content inside app-debug.apk.
- Android assembleDebug and testDebugUnitTest PASS offline with JDK 17,
  locale structural audit and Python regression tests PASS. Android now
  has EN/RU/ES/pt-BR development catalogs; 46 further target languages
  await real translations and QA.
- Native speaker copy review, RTL, physical devices, real ads, system
  permissions, and release approvals are still open. No merge/main
  changes, store update, or app submission.


### Unconfirmed stress gate (not a failed assertion)

- A third es_ES/AXXXL simulator run was attempted twice, but both
  xcodebuild invocations were interrupted before writing a complete
  xcresult or an assertion result. They are **unverified**, not PASS or
  FAIL. This case is left out of the committed passing test suite until
  stable execution is possible. Spanish normal-size workflows 2/2 PASS
  are independently confirmed from xcresult.


## L3.4 / L4.1 executed on 21 October: French Android and Spanish AXXXL

The earlier unconfirmed AXXXL attempt above is now resolved as an
engineering/regression gate, not blanket accessibility acceptance.

- Root problem: at the system's AXXXL content size, Spanish mode
  captions and six size presets were truncated in the fixed single-row
  layout. Photo and Files import labels were squeezed into a 62pt row.
  Actual screenshot evidence is kept on ArvectumSSD.
- Fixed: adaptive two-column mode navigation and chip grids at Dynamic
  Type accessibility sizes; mode captions bounded at accessibility1
  only for navigation so that four controls stay discoverable, each
  retains the full VoiceOver label; import buttons now stack on iPhone
  at accessibility type, PDF picker height adapts.
- iOS Photo/PDF build PASS. Re-ran SpanishLocalizationUITests, including
  both photo/PDF workflows and the new AXXXL navigation case: Xcode
  result Test-PhotoPodRazmer-2026.10.21_00-32-05-+0300.xcresult
  **3 passed, 0 failed, 0 skipped**. The targeted AXXXL run before
  the full rerun also passed 1/1. Reset QA Simulator content size to
  original large; no global test state left altered.
- Added French Android locale: 93 authored translations.
  JDK17 Android assembleDebug and testDebugUnitTest PASS (6 JVM tests
  with 0 failures). AAPT2 dump confirmed French strings inside the
  generated APK. Python audit/catalog regression 11/11 PASS.
- French becomes Android's fifth development language after English,
  Russian, Spanish, and Brazilian Portuguese. Other 45 target languages
  are not yet translated. Copy review and physical device tests are
  still pending. No main merge, pushes, TestFlight or store actions.
