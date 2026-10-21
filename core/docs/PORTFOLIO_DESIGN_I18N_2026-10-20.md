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


## L2.6 + L3.5 follow-up on 21 October

- ChickMark dynamically lists languages that are actually packaged and
  complete relative to the English Localizable.strings keys. Unsupported
  system languages FR, JA, HI, ZH default to EN; an available Spanish
  system locale chooses ES. Existing Russian and explicit overrides
  still work. iOS Simulator build and 4/4 targeted unit tests PASS.
- Pushkin 151 authored ES strings; XcodeGen project regenerated and
  compiled en/es/ru localizations confirmed inside the app. Runtime
  reads the Spanish source bundle for PC labels and uses the same
  English keys; Russian copy remains stable. 1 aplicación and
  2 aplicaciones format correctly.
- Simulator screenshot shows Spanish Historial, Buscar notificaciones,
  Aplicaciones and Ajustes. Stored example notification bodies stay in
  their source language, as user/data content should.
- Pushkin two focused unit tests PASS, Python localization 12/12 PASS.
  Spanish UI test exists but its Xcode runner was interrupted twice
  before saving a valid result; the UI test is not marked PASS.
- Android French locale APK/Gradle verified in the previous iteration.
  Remote Android emulator lifetime caused loss of test session before
  any French screenshot; LaunchAgent EX_CONFIG, agent unregistered.
  French Android visual QA remains open.
- Changes remain in feature branch, no store/release actions.


## L3.6 and L4.2 — UhWhat? Spanish iPhone, Watch, widgets

- Added true ES catalogs to WhatIOS: 204 original + nine newly
  discovered RU/EN home/VoiceOver phrases = 213, Watch 6, PhoneWidget
  6, WatchComplication 5. All four ES bundles are compiled and verified.
- The previously supported Spanish speech selection now uses an actual
  Spanish UI runtime. CaptureBrand handles complete dynamic messages
  and Spanish note counts. Unsupported languages use English.
- First real simulator screenshot showed Catch that thought, Tap for
  audio, All notes and 0 notes unexpectedly in English. They came
  from an old isRussian UI ternary, not indexed by earlier extraction.
  Replaced the home screen's old RU/EN branching, including accessible
  labels and hints, with consistent localizer calls. Next screenshot
  confirms full Spanish copy on the home screen.
- On AXXXL, Texto was broken into two lines and the Video CTA became
  disproportionately large. Bounded typography only on these compact
  actions. Final screenshot shows both labels intact, with the main
  large Spanish heading preserved. Simulator reverted to large text.
- Source/build tests PASS; What localization XCTest 5/5, UI smoke and
  forced accessibility5 XCUITest 2/2, Python catalog tests 14/14.
- Native language review, other screens and real watchOS/device
  accessibility are not approved or claimed. No store publishing.


### Earlier QA blockers investigated, not falsely closed (21 Oct)

- Pushkin Spanish UI runner: a complete alternate simulator test revealed
  a false-positive test at the line requiring the already-selected History
  tab to be hittable. Existing production navigation and Spanish
  screenshot were intact; the test now checks the Apps/Settings actions
  actually used for navigation. Later runs were interrupted or hung
  during Xcode UI automation, so there is still no completed PASS for
  that corrected test. Preserve the gate until a stable rerun.
- French Android small_phone: existing development APK includes FR
  sources. Background emulator processes closed with their remote
  session; a temporary launch agent with explicit HOME/AVD environment
  remained stuck in dynamic-loader file opening without registering an
  ADB device. It was stopped and unregistered, leaving no persistent
  test daemon. No French Android screenshots or device QA were claimed.
- What regression audit now tests that every CaptureBrand literal source
  used on iOS, Watch and widgets has both native RU and ES keys, and
  catches a future direct isRussian string ternary on the capture screen.
  Python source checks 14/14 PASS.

- The corrected Pushkin Spanish UI smoke passed build-for-testing compilation on 21 Oct. XCUITest execution is still an open gate after runner hangs/interruptions.


## L2.7 + L3.7, 21 October — German Android and source bypass inventory

- Added 93 real German strings to Android Photo/PDF, including all
  processing errors, parameters and numbered positional placeholders.
  English remains default for every unimplemented system language.
- Android Gradle assembleDebug and testDebugUnitTest succeeded offline;
  JVM 6/6 with no failures (task reused cache). AAPT2 dump confirmed
  DE language resources inside the generated APK. No emulator/device
  screenshot was claimed.
- Six actual Android resource packs now exist: EN, RU, ES, pt-BR,
  FR and DE; 44 of the 50 planned languages are not yet translated.
- The localized-source risk inventory now detects direct Russian/
  English conditional ternaries which previously bypassed actual
  Spanish localizations. The deliberate bilingual What brand name
  is the only reviewed exception. Python catalog suite 16/16 PASS.
- Pushkin Spanish standalone UI test-without-building hung without a
  valid assertion outcome. Its QA process was terminated, and the
  gate is still open. No main merge, remote push or store release.

## 21 October L3.8 + L4.3: verified results

Italian Android Photo/PDF: 93 real strings in values-it, 7/50 target
language packs including English source, 43 not yet translated.
Gradle assembleDebug + testDebugUnitTest succeeded offline (6/6 JVM).
AAPT2 confirmed Italian resources in the debug APK. Locale safety tests
17/17 pass. Android FR/DE/IT visual QA remains open.

Pushkin ES: the first completed UI test showed a selected-tab
hittability assumption was false. A second completed test showed that
the tab is titled 'Aplicaciones' but its screen is titled 'Aplicaciones
y configuración'. Both assertions were corrected; actual tap/navigation
flow is unchanged. Xcode result
Test-ArvectumNotify-2026.10.21_09-45-34-+0300.xcresult is PASS 1/1.
Earlier failed or interrupted attempts do not count as successes.
Full device and VoiceOver QA are still required.

All changes stay on the feature branch and no release is authorized.

## 21 October L3.9: NL + PL and partial Android emulator recovery

- Dutch values-nl/strings.xml: 93 translations. Polish
  values-pl/strings.xml: 93 translations. Source IDs exactly
  match English, positional format placeholders preserved.
- Gradle :app:assembleDebug + :app:testDebugUnitTest PASS
  with JDK17 and offline Android SDK. 6 JVM test cases pass,
  zero failures/errors. AAPT2 dump of the built debug APK
  confirms both localized app names and on-device-processing
  privacy messages inside NL and PL resource configurations.
- Python localization audit and regression tests pass 19/19.
  The locale registry correctly states 9/50 Android development
  language packs, 41 target locales untranslated.
- Android SDK small_phone AVD (Android 16) booted fully
  and adb installation of the debug package succeeded, but
  the remote connection dropped before changing the app
  language or capturing a screen. Emulation remains a
  **partial infrastructure success**, NOT Android locale
  visual QA. FR/NL/PL RTL/device/layout verification open.
- The system disk was not used for repository builds;
  build/test logs and generated release-independent APKs
  remain on external ArvectumSSD. No App Store actions.


## Android visual regression L4.4–L4.5 (21 October afternoon)

Confirmed debug APK running in Android 16 small_phone emulator,
app-specific locales set to FR, NL, PL and screenshots captured.
French and Polish initial screens fit; Dutch originally split
Bestandsgrootte inside one word. Adaptive ModeSelector now measures
localized text with Compose rememberTextMeasurer and chooses 3/2/1
columns, avoiding broken navigation captions.

At fontScale 1.6 the original NL screenshot clipped the primary
Foto kiezen button and hid the privacy notice. Scrollable
SelectionContent and ResultContent, plus hiding decorative footer
at enlarged sizes, make both reachable. Confirmed by top/bottom
screenshots on disposable emulator with the 160% system font.

Android full APK build and 9/9 JVM PASS (6 existing, 3 new layout
logic cases), no test failures. Screenshots/logs retained in the
external SSD QA folder. This proves selected initial-screen layouts,
not TalkBack or full file picker/processing on physical Android.


## L3.10 on 21 Oct: French iOS Pushkin

The Pushkin iPhone app now contains French as a fourth development
language (EN/RU/ES/FR), 151 complete localized source keys. The
historical PushkinCopy Russian dictionary was preserved, and Spanish
and French now share a bundle-based source resolver, with English
fallback for other unsupported locales. French one and plural counts
are handled explicitly.

Actual generated Xcode bundle contains fr.lproj/Localizable.strings.
iOS Simulator debug build passed; French unit tests passed. New
FrenchLocalizationUITests uses French system language and exercises
History, Apps & Setup and Settings; xcresult
Test-ArvectumNotify-2026.10.21_15-15-27-+0300.xcresult shows
1 passed, 0 failed. Python i18n audit/tests pass 20/20.

The French translations still require native editorial review and
physical device accessibility and Shortcuts QA, prior to any release.

## 21 October L3.11 — ChickMark French, all bundles

- Full French source coverage of ChickMark main iPhone 302, Watch 22,
  iPhone Widget 16 and Watch complication 5; 345 keys, no missing
  placeholders. Two French privacy/Health authorization strings on
  both iPhone and Watch.
- Fixed French count-only templates to avoid plural agreement errors
  when the system passes exactly 1 (use neutral abbreviated units
  such as j and sem., or labels such as Semaines : 1/2).
- Existing dynamic locale resolver discovers fr.lproj only when
  complete. Swift tests updated for language selection and French
  today/progress/habit strings, while untranslated device languages
  retain the English fallback.
- XcodeGen project regenerated. iOS Simulator debug scheme build PASS
  with embedded FR localizations in all four targets. LocalizationTests
  5/5 PASS. FrenchLocalizationUITests 1/1 PASS on in-memory test
  storage with iCloud disabled. Python localization suite 21/21 PASS.
- No native speaker review or physical iPhone/Watch/VoiceOver approval.
  No TestFlight, App Store publishing or main merge.

Android separate follow-up: a synthetic PNG was produced and placed in
the Android 16 emulator photo library. Repeated desktop connection
drops prevented a verified photo-picker selection and successful
compression/save. Keep Android full E2E QA open; prior FR/NL/PL
visual and enlarged-font tests remain proven separately.


## 21 October Android L4.6 — real image processing on emulator

An Android-specific Debug-only QA route was added without changing the
Release source set: ImagePipelineQaReceiver is exported only in the
Debug manifest and requires android.permission.DUMP. Both Debug APK
manifest inspection and the Release merged manifest verified its
absence from Release. The verifier builds deterministic 900x700
synthetic PNG pixels, feeds a FileProvider URI to the real ImageStorage
and CompressionEngine, and saves each output through ImageStorage.save
to an app-private local JPEG.

The confirmed machine report from an Android 16 Emulator is:
  status=passed, sourceBytes=2199482, compressedBytes=479009,
  maximumBytes=500000, resizedWidth=400, resizedHeight=311,
  passportWidth=620, passportHeight=797, passportDpi=450,
  savedOutputs=3.
All output files were decoded and checked for expected dimensions;
the passport EXIF DPI was read via ExifInterface. No user photos,
real media provider authorization, cloud accounts or production data
were accessed. Report: ArvectumSSD/Arvectum/tmp/
portfolio-design-i18n-qa-20261020/android-pipeline-qa-result-final.json.

Offline assembleDebug and testDebugUnitTest PASS (9 JVM tests).
Release manifest generation PASS and debug QA receiver absent from
the Release manifest. A repeatable shell runner exists with an
external SSD-only QA output guard; the trial runner invocation was
interrupted by RDC and does not count as another successful test.
3 new Python source-isolation checks brought the combined core suite
to 24/24 PASS.

Keep separate open gate: actual Android Photo Picker GUI selection,
Compose result screen, and system Documents SaveDocument/export.
The engine path is verified, the complete customer journey is not.


## Android L4.7 real picker partial E2E (21 October)

The system Photo Picker had previously been queried too early: after
allowing time, it was visibly opened in Android 16. Its synthetic
image was selected and confirmed with Done. The real Compose app
displayed the 900x700, 1.84 MB source; a 500 KB preset, PNG/JPG
warning, and Compress to 500 KB were displayed. The action was tapped,
but the remote connection was lost before a result screen.

New real GUI host runner qa_photo_picker_emulator.sh and Python driver
qa_photo_picker_e2e.py with synthetic-only media and independent
system SaveDocument verification. Source-isolation and syntax tests
passed, 27 Python tests in total. A background launchctl attempt
exited with EX_CONFIG 78 and was removed. There is NO valid
Photo Picker-to-export complete PASS yet, despite L4.6 independent
production engine test passing. Retest until exported JPEG and a
status=passed JSON report are captured.

## Android L4.8 and L3.12 — closed and proven 21 Oct 17:00

Using tmux detached execution, the Android 16 emulator completed the
previously blocked REAL app Photo Picker-to-SaveDocument user flow.
Proof is machine report:
- ArvectumSSD/Arvectum/tmp/portfolio-design-i18n-qa-20261020/
  tmux-photo-picker-qa/qa-photo-picker-report.json: status passed
- Seven stages: synthetic image, real Android Photo Picker, compression
  requested, actual Compose result, Documents SaveDocument, system
  Save tapped, exported JPEG verified in Downloads
- output 479169 bytes (<500000), valid 900x700 JPEG confirmed via sips;
  SHA-256 available in the retained external QA files

The run found a shipping UX defect: an English UI exported a file
suffixed in Russian. MainViewModel no longer hardcodes three Russian
suffixes. New Android resource file export_filenames.xml exists for
EN/RU/ES/PT-BR/FR/DE/IT/NL/PL with 3 locale-appropriate filename
suffixes each. Localized QA audit now validates all 96 strings
(93 main UI + 3 filename), not just one monolithic resource XML.

A SECOND actual system Photo Picker → compression → SaveDocument run
passed 7/7 after rebuilding:
- tmux-photo-picker-localized-qa2/qa-photo-picker-report.json
- systemUri ends with /19-compressed.jpg, actually saved in Downloads
- exported file 479169 bytes, below 500 KB target
- Android Gradle Debug/JVM PASS 9/9, Python tests 29/29

Remaining non-release gates: physical Android, TalkBack, large-font
across every screen, other image/document modes and non-synthetic
media. No Apple/Google store action, no main merge.

## What/Uhvat L3.13 — interface and speech independent (21 October)

Source code confirmed the previous shared speech/UI preference:
CaptureBrand.interfaceLocale returned selectedTranscriptionLocale, and
RecordingLibrary's picker was labelled Interface and speech language.
The same choice unexpectedly switched both transcription and visual UI.

Changed the visible RU/EN/ES locale resolver to choose the supported
iOS per-app/device language, with English fallback. The original
persisted dictation locale still controls SFSpeechRecognizer and its
on-device-only eligibility; audio/notes and user selection data were
untouched. Removed unnecessary view remounting on speech changes,
renamed the menu to Speech recognition language, and added a
translated system Settings link for the independent interface language.
Fixed a separate translated-UI bug in Today/Yesterday/Earlier day
sections that had bypassed Spanish.

WhatIOS iPhone resources now contain 217 key-complete EN/RU/ES entries,
same printf argument compatibility; Watch/complication/widget counts
unchanged. Focused Xcode iOS Simulator tests pass 10/10, including
crossed device/speech languages RU+EN and ES+EN. Combined Python tests
30/30 pass, plus localization audit. Evidence:
isolated-what-v2/Logs/Test/Test-WhatIOS-2026.10.21_17-15-03-+0300.xcresult.
Product migration caveat: previously users could change UI from the
combined dictation menu; this changes to iOS app Settings by design,
so review discoverability with users before any release.


## L4.9/L4.10, 21 October — real diagnostics and iPad Spanish AXXXL

Legacy SyncDiagnosticsLocalizationUITests incorrectly required a
selected dictation language to change the live interface. After
L3.13, this contradicted the actual iOS settings contract. Tests
now exercise RU/EN/ES diagnostics under their actual iOS app locale
and verify that Russian UI remains Russian when selecting English
speech recognition and after relaunch. The English picker choice
is correctly displayed as Английский in Russian UI, which the
revised test uses. Actual iPhone 17 Pro simulator xcresult at
17:46:28: 10/10 PASS.

Added SpanishLocalizationUITests focused test on isolated iPad:
testSpanishMixedNotesLibraryAXXXLAccessibleNavigation uses the
existing debug-only synthetic local note store and accessibility5.
Checks Spanish filters, Hoy header, English speech setting not
affecting interface, Settings button at least 44pt and hittable,
then executes Apple full system accessibility audit (description,
hit region, trait, text clipping). iPad xcresult at 17:49:08:
PASS 1/1, screenshot kept in test result. Core Python 31/31 PASS.

SmartSearchView is experimental and defined but not invoked by a
live screen. It contains additional dynamic English strings;
no claim of complete Smart Search localization is made. Enabling
it requires separate full RU/ES copy, model/download and VoiceOver
review. Physical VoiceOver/iPad/Watch and human linguist signoff
still block releases.


## L4.11 — What Spanish large-font Done action (21 Oct)

iPhone/iPad QA uncovered the actual 36 pt nav-toolbar Done button.
Applying frame to the toolbar label did not enlarge the XCUIElement
frame. Also learned that ContentView-only accessibility5 injection
does not propagate into TextNoteSheet, so true system accessibility
font settings are required for a valid modal-editor test.

In production TextNoteSheet, an accessibility-size condition moves
the translated Done action into a bottom safeAreaInset (minWidth 88,
minHeight 52) above the keyboard; normal font preserves the standard
navigation button. The same what.text.done identifier is used in
both branches. The QA launch now sets the global accessibility font
category. No personal notes were modified.

Actual Xcode results:
 iPhone Test-WhatIOS-2026.10.21_18-30-44-+0300.xcresult
 1 passed 0 failed;
 iPad Test-WhatIOS-2026.10.21_18-31-37-+0300.xcresult
 2 passed 0 failed.
These cover Spanish editor accessible label and 44+pt button, safe
dismissal, and Spanish settings under independently selected English
speech. Python 32/32 tests and Debug compilation passed.
Additionally, the original ordinary-size iPhone capture and empty
text editor flow was rerun after the production change:
Test-WhatIOS-2026.10.21_18-33-04-+0300.xcresult, 1/1 PASS.
Physical VoiceOver/iPhone/iPad and editorial QA remain open.
