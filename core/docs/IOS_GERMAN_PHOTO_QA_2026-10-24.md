# Core C5.1 — German iOS Photo/PDF pilot, 24 October 2026

## Scope and platform priority

Priority: iOS -> watchOS -> Android. A fifth iOS source locale (German) was
added to Photo/PDF ONLY. Other iOS apps (ChickMark, Pushkin, Uhvat)
retain four source locale catalogues (EN/RU/ES/FR); the portfolio has
NOT achieved a fifth shared language. Android remains 9/50 draft/source
catalogs for Photo/PDF, with no expansion here.

## Code

- [x] German Localizable.strings: all 155 keys match English; 153 distinct
  translated values and format patterns, including image/PDF processing,
  privacy and consent, export, errors, documents and accessibility text.
- [x] German InfoPlist.strings: display name and tracking permission copy.
- [x] GermanLocalizationUITests.swift: real Simulator test flows for
  photo processing, PDF processing and AXXXL accessible navigation.
- [x] Optional update dialog handled in German via Später.
- [x] Screenshot review found the preset label Benutzerdefiniert truncated
  on the main screen. Changed it to Eigene; added regression assertions.
- [x] Core unit regression checks complete German catalogue and
  printf placeholder type parity.
- [x] Machine-readable locale registry records DE pilot without
  representing it as a public release.

## Actual results on Mac mini

- [x] localization_portfolio.py --report:
  Photo/PDF five complete source catalogues (de, en, es, fr, ru);
  all other iOS products four. This is structural, not editorial QA.
- [x] Python Core localization unit tests: 35/35 PASS, 0 FAIL.
- [x] plutil -lint for German InfoPlist and Localizable: PASS.
- [x] XcodeGen + iOS Simulator successful build with German
  source strings inside built application bundle.
- [x] iOS 27.0 iPhone 17 Pro isolated Simulator: DE UI 3/3 PASS,
  0 failures after short-chip fix; AXXXL, synthetic photo/PDF,
  save CTA and custom-size control tested.
- [x] Manual on-device simulator screenshot visual review.
- [x] No personal files, no production release action or submission.

## Open release gates

- [ ] Human/native proofreading of privacy/consent, documents and nuance.
- [ ] Physical iPhone/iPad VoiceOver, long text, real Photos/Files,
  OS permissions, ad-fill/no-fill, data-safe upgrade QA.
- [ ] German for Pushkin, Uhvat + Watch/widgets and ChickMark +
  Watch/widgets; none of those locales completed by this pilot.
- [ ] Explicit approval for each specific App Store upload or review.

Branch: feature/photo-de-ios-20261024, stacked on feature/photo-fr-localization-20261024 (draft PR #141).
