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
- [x] 6/6 unsigned iOS/watchOS Simulator builds PASS: Photo/PDF iOS, Pushkin iOS, Uhvat iOS, ChickMark iOS, Uhvat watchOS, ChickMark watchOS.
- [x] 6/6 Chinese iPhone Simulator XCUITest PASS: Photo/PDF photo, PDF and AXXXL (3/3), Pushkin navigation (1/1), Uhvat AXXXL home (1/1, no recording), ChickMark synthetic new habit (1/1, no CloudKit).
- [x] 35/35 native Swift localization XCTest PASS: Pushkin CoverageCatalogTests 14/14, Uhvat LanguageFallbackTests 12/12 (full suite rerun), ChickMark LocalizationTests 9/9.
- [x] Inspected compiled app and extension resources: zh-Hans.lproj is embedded in all four iOS apps plus Watch/Widgets.

## Release gates

- [ ] Native Chinese editorial/legal review of ads/ATT,
  ID documents, data loss/backup, HealthKit, Siri and privacy labels.
- [ ] Physical iPhone/Watch Dynamic Type/VoiceOver,
  permissions and non-destructive user-data upgrade QA.
- [ ] Explicit owner approval required per new Apple build submission.
  No App Store/TestFlight uploads or publication performed.

Stacked draft PR chain #141 → #142 → #143 → #144 → #145 → #146 → zh-Hans PR.


## Regression triage / evidence

One pre-existing Uhvat LanguageFallbackTests assertion expected an English
fallback for Simplified Chinese. Now that Simplified Chinese is bundled,
the correct resolved interface language is Chinese. Updated the obsolete
assertion and reran the complete suite: 12/12 PASS. The original failing
run is retained in evidence and not counted as a passing test.

Traditional Chinese locales (zh-Hant, zh-TW, zh-HK, zh-MO) must not
silently become Simplified Chinese, and this is covered by Swift tests.
The UI locale does not promise Chinese offline speech-recognition support.

Native QA: isolated iPhone 17 Pro / iOS 27.0 Simulator, synthetic fixtures.
No production user audio, CloudKit/HealthKit, TestFlight, App Store
metadata, or public versions were modified. Raw logs, xcresult packages,
and status JSON are stored on the authorized Mac mini SSD.
