# Фото и PDF под размер — Product Roadmap

**Updated:** 2026-10-13
**Ownership:** image/PDF sizing, document presets, export, app-specific UX, SDK integrations, QA and releases.
**iOS App Store:** v1.0.0 approved and published on 2026-10-11, after submission on 2026-10-10 (product owner confirmation). Apple App ID `6816346084`, bundle ID `ru.arvectum.tools.tosize`. [Public listing](https://apps.apple.com/ru/app/id6816346084). Android publication status is tracked independently.
**History and detailed specification:** [docs/history/ROADMAP-legacy-2026-10-11.md](docs/history/ROADMAP-legacy-2026-10-11.md). It is reference history, not a live checklist.
**Common principles:** [Core](../core/CORE_PRINCIPLES.md). **Acquisition/ASO and monetization experiments:** [Growth](../growth/ROADMAP.md).

## Current implemented capability (repository-recorded; validate against shipping build)
- [x] Local image file-size and dimension modes; document-photo presets.
- [x] PDF target-size mode added in 0.6.0 with local processing and rasterization warning.
- [x] Photo import from Files/iCloud, exact W×H, JPEG/PNG/HEIC export options, EXIF controls, print sheets.
- [x] International document presets RU/US/India/UK (country-specific constraints documented).
- [x] RU/EN localization, system Light/Dark UI and lower primary CTA placement.
- [x] Home native ad and result banner recorded as production integration in 0.5.1.
- [x] Store screenshots prepared showing before/after; this is a completed asset task, not a pending product feature.
- [x] iOS release v1.0.0 publicly launched, 2026-10-11.

## Release 1.0.0 — distribution verified

**Verified release record:** [App Store release 1.0.0 (build 12), 2026-10-11](docs/appstore/RELEASE_1.0.0_2026-10-11.md).

- [x] Submitted to App Review on 2026-10-10.
- [x] App Store Connect confirms iOS **1.0.0 (12)** uploaded on 2026-10-10, in review and then **Ready for Distribution** on 2026-10-11.
- [x] Product owner confirmed live App Store publication on 2026-10-11.
- [x] Recover build **12** source commit `0346d75`, signed IPA/archive and Apple submission evidence; merge the shipped source into canonical `main` and tag `photo-size-ios-v1.0.0-build12`.
- [ ] Verify public-storefront propagation of 1.0.0 (public iTunes lookup still showed 0.6.2 during this audit).

## iOS 1.0.1 (13) — submitted to App Review (WAITING_FOR_REVIEW, 2026-10-13)

- [x] Keep the advertising consent Accept/Decline buttons visible even with iOS 27's maximum accessibility text size by scrolling explanatory text separately.
- [x] Re-run 28 unit tests plus 5 simulator UI tests on iOS 27 with standard text size; 5 device-only Files tests skipped by design.
- [x] Reconfirm that extreme accessibility text size needs scrolling; the no-scroll regression applies to the standard text-size matrix only.
- [x] Signed archive and verified IPA 1.0.1 (13) exported and uploaded to App Store Connect (2026-10-13).
- [x] Prepared 20 localized release notes and a 1.0.1 draft in App Store Connect.
- [ ] Physical iPhone regression (Files/Photos, exports, PDF, ads and consent/ATT) and release acceptance.
- [x] Apple build 13 is VALID and attached; ru/en-US/en-GB screenshots and locale parity verified.
- [x] Physical iPhone 13 debug build installed, launched and screenshot captured: main screen and native demo ad visible.
- [x] Submitted 1.0.1 (13) to App Review 2026-10-13; Apple confirmed WAITING_FOR_REVIEW.
- [ ] Full physical Files import/export and ATT acceptance still need verification: XCTest UI runner timed out enabling automation, not an app assertion. Do not claim production ads tested. See [release handoff](docs/appstore/RELEASE_1.0.1_2026-10-13.md).
- [ ] Apple approval and public storefront verification.

## Next: post-release QA and maintenance
- [ ] Run device regression on image modes, document presets, PDF orientation, large-file memory and export.
- [ ] Confirm which ads/presets/locales are present in the published build (not just development history).
- [ ] Close or document known crashes/regressions and classify fixes for the next patch.

## Deferred / evidence-gated
- [ ] Batch processing: decide after usage data.
- [ ] Shortcuts/power-user extensions: only with demonstrated demand.
- [ ] More locales or document-market presets: only with actual market/search evidence.

## Guardrails specific to this app
- Never alter source originals; on successful target-size operation check output bytes against limit.
- PDF may rasterize: explicitly disclose loss of selectable/searchable text.
- Not a general PDF editor, scanner, OCR toolkit or AI retouching product.
- Ad rendering must not block export; concrete SDK/ad UX requirements stay here.
