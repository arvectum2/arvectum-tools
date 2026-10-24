# Core C5.6 — Simplified Chinese (zh-Hans), iOS-first

Started 24 October 2026.

## Scope and actual release boundary

Nine complete **source** locales across all four active apps:
EN/RU/ES/FR/DE/PT-BR/IT/JA/ZH-Hans. This is not App Store release.
All 10 active iOS/watchOS/widget target bundles now have zh-Hans source copy.
Android has not been expanded.

| Product | iPhone | Apple Watch | Phone widget | Watch widget/complication |
| --- | ---: | ---: | ---: | ---: |
| Photo/PDF | 155 | - | - | - |
| PUSHKIN | 151 | - | - | - |
| Uhvat | 231 | 6 | 6 | 5 |
| ChickMark | 302 | 22 | 16 | 5 |

**899 Chinese Simplified Localizable.strings records** in 10 bundles.
Additional system permission InfoPlist text and Siri AppShortcuts
translated. Translations require editorial verification by native speakers.

## Source checks

- [x] All ten zh-Hans localized source catalogs complete, genuine
  translated strings, no English placeholder catalogs.
- [x] ATT/advertising and photo document caution text; Watch/iPhone
  microphone/camera/speech permissions; Apple Health data sharing
  and writing consent; Siri applicationName macro preserved.
- [x] Runtime uses zh-Hans for Simplified Chinese, accepts zh-CN;
  traditional zh-Hant/TW/HK/MO not silently treated as Simplified.
- [x] Interface language is separate from local offline ASR availability.
- [x] Core 9-language catalog/key/format/companion audit 45/45 PASS.
- [x] XcodeGen regenerated four iOS projects and Chinese UI smoke tests.
- [ ] Unsigned 4 iOS and 2 watchOS native builds: log actual results.
- [ ] iPhone Simulator Chinese UI Photo/PDF, Pushkin, Uhvat, ChickMark.
- [ ] Native Swift language unit tests.
- [ ] Verify zh-Hans.lproj in actual compiled app/Watch/widget artifacts.

## Release gates

- [ ] Native Chinese editorial/legal review of ads/ATT,
  ID documents, data loss/backup, HealthKit, Siri and privacy labels.
- [ ] Physical iPhone/Watch Dynamic Type/VoiceOver,
  permissions and non-destructive user-data upgrade QA.
- [ ] Explicit owner approval required per new Apple build submission.
  No App Store/TestFlight uploads or publication performed.

Stacked draft PR chain #141 → #142 → #143 → #144 → #145 → #146 → zh-Hans PR.
