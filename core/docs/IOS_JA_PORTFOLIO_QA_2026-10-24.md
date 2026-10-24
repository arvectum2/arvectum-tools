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
- [ ] Native unsigned iOS 4 + watchOS 2 Simulator builds: verify logs.
- [ ] Japanese iOS UI smoke: photo/PDF/AXXXL (3), Pushkin (1),
  Uhvat (1), ChickMark (1): verify actual results.
- [ ] App Swift locale unit suites: verify actual results.
- [ ] Check ja.lproj inside compiled iOS and embedded watch/widget apps.

## Remaining release gates
- [ ] Native Japanese editorial review for legal consent, document
  photos, data deletion, Apple Health and Apple Shortcuts terminology.
- [ ] Real physical VoiceOver, Watch, Dynamic Type, consent,
  native Japanese font line-breaks and non-destructive update QA.
- [ ] Explicit version-specific owner approval before upload,
  TestFlight or any public App Store update. None performed.

Stacked PR order: #141 -> #142 -> #143 -> #144 -> #145 -> JA.
