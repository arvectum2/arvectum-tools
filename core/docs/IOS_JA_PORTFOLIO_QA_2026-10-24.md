# Core C5.5 — Japanese (JA) iOS-first source localization

Date: 24 October 2026.

## Scope / no production releases

Japanese is now the eighth full SOURCE locale in all ten active
iOS/watchOS/widget bundles, across four active apps.
The code translation is a draft pending native Japanese proofreading
and actual physical device acceptance, not an App Store release.

| App | iPhone | Watch | Phone widget | Watch widget/complication |
| --- | ---: | ---: | ---: | ---: |
| Photo/PDF | 155 | - | - | - |
| PUSHKIN | 151 | - | - | - |
| Uhvat | 231 | 6 | 6 | 5 |
| ChickMark | 302 | 22 | 16 | 5 |

Total 899 Japanese Localizable.strings entries across 10 targets.
Available source locales: EN/RU/ES/FR/DE/PT-BR/IT/JA.
Android not expanded.

## Done — engineering source milestone

- [x] Japanese iPhone/Watch/widgets strings and full key/printf format parity.
- [x] Japanese InfoPlist camera/microphone/speech, ATT/ad/privacy,
  HealthKit read/write and ChickMark Siri AppShortcuts; macro
  applicationName preserved.
- [x] Locale selection: real JA bundle in PushkinCopy/CaptureBrand,
  Japanese counters, Japanese autonym in ChickMark, ja_JP numeric locale.
  Offline Japanese transcription is NOT implied by Japanese UI language.
- [x] Core portfolio eight-language source audit 43/43 PASS.
- [x] XcodeGen regenerated four project files.
- [x] **6/6 unsigned Simulator builds PASS**: Photo/PDF iOS, PUSHKIN iOS, Uhvat iOS, ChickMark iOS, Uhvat watchOS, ChickMark watchOS.
- [x] **6/6 final Japanese iOS XCUITest PASS** on isolated iPhone 17 Pro / iOS 27.0: Photo/PDF photo, PDF, AXXXL (3/3), Pushkin navigation (1/1), Uhvat AXXXL synthetic home (1/1), ChickMark synthetic new habit (1/1).
- [x] **32/32 Swift localization XCTest PASS**: Pushkin 13/13, Uhvat 11/11, ChickMark 8/8.
- [x] Confirmed ja.lproj in actual compiled iPhone, embedded Watch and Widget application bundles.

## Remaining release gates
- [ ] Native Japanese editorial review for legal consent, document
  photos, data deletion, Apple Health and Apple Shortcuts terminology.
- [ ] Real physical VoiceOver, Watch, Dynamic Type, consent,
  native Japanese font line-breaks and non-destructive update QA.
- [ ] Explicit version-specific owner approval before upload,
  TestFlight or any public App Store update. None performed.

Stacked PR order: #141 -> #142 -> #143 -> #144 -> #145 -> JA.

## Test incident and evidence

The initial JA Photo/PDF accessibility mode test expected the alternative
Japanese wording 写真をサイズ変更 while the app correctly rendered
写真のサイズを変更. The test expectation was corrected and the AXXXL
UI test was rerun independently with PASS (1/1). The initial failure
is retained in source logs, and the other Photo/PDF photo and PDF UI tests
passed on the first run (2/2). Count the final independent rerun only.

Simulator tests used synthetic fixture data without personal Watch recordings
or user CloudKit changes. Raw logs and xcresult are stored on Mac mini SSD.
