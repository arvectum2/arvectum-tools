# Core C5 — iOS-first localization acceptance (24.10.2026)

## Target and priority
Portfolio priority ordered iOS -> watchOS -> Android; don't expand the existing
Android 9/50 source catalogs while the four active iOS applications have only
RU/EN/ES/FR. The next iOS source wave targets DE, PT-BR, IT, JA and zh-Hans
for **each** product; the long-term portfolio registry holds 50 target locales.
A translated catalog does not constitute an App Store release.

## Source implementation
- Photo/PDF: add real French strings for all **155** UI keys, French
  InfoPlist display name and advertising disclosure. No English placeholder
  catalog is counted as translation.
- Core: ensure four complete matching catalog sets RU/EN/ES/FR in all
  **10 active iOS bundles** (Pushkin 1, Photo/PDF 1, ChickMark 4, Uhvat 4).
- Core: enforce source catalog parity and placeholder types in a new regression
  test and encode platform priority + next iOS wave in the localization manifest.
- Photo/PDF French and Spanish XCTest scenarios: photo processing, PDF
  processing, max accessibility font mode grid and advertising consent.
- Tests dismiss optional App Store update dialog in RU/EN/ES/FR using the
  corresponding Later action. Published Photo/PDF 1.0.2 triggered that dialog
  in an older simulator build. This is not a production UI change.

## Actual results on Mac mini / Xcode 27.1, iOS 27.0

- [x] Localization source audit: PASS.
- [x] Core Python unittest localization portfolio: **34/34 PASS**.
- [x] French Localizable.strings and InfoPlist.strings: plutil PASS.
- [x] Photo/PDF unsigned iOS Simulator build: BUILD SUCCEEDED,
  FR resources inspected inside generated .app.
- [x] **FrenchLocalizationUITests: 3/3 PASS, 0 failures**, dedicated iPhone 17 Pro Simulator.
- [x] **SpanishLocalizationUITests: 3/3 PASS, 0 failures** after optional-update
  alert dismissal (label 'Más tarde'). No production or personal data modified.
- [x] Original failure triaged with captured simulator screenshot showing
  a modal App Store 1.0.2 update prompt obscuring otherwise available controls;
  re-run confirmed all 6 localized workflows PASS independently.

Result bundles/logs were stored locally on Mac mini SSD as QA evidence,
not uploaded to GitHub. Only code, unit/UI tests and textual evidence are
part of this PR.

## Explicitly NOT complete
- [ ] Native/editorial proofreading of French (especially privacy/consent,
  regional document specs and nuanced interface copy).
- [ ] Real-device FR VoiceOver rotor/gestures, permissions, mobile ad/no-fill,
  document/large image edge cases, safe public app upgrade and iPad multitasking.
- [ ] Build/review/submit of any new Photo/PDF version to Apple: **no upload,
  no publication without explicit per-version owner authorization**.
- [ ] Other 5 iOS locales: planned only; do not mark translated.
- [ ] 41 additional Android translations: deferred, not abandoned.

Current public Photo/PDF 1.0.2 is unaffected. The change remains in draft
PR #141 until review and appropriate release gates are addressed.
