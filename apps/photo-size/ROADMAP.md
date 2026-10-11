# Фото и PDF под размер — Product Roadmap

**Updated:** 2026-10-11
**Ownership:** image/PDF sizing, document presets, export, app-specific UX, SDK integrations, QA and releases.
**iOS App Store:** v1.0.0 approved and published on 2026-10-11, after submission on 2026-10-10 (product owner confirmation). Apple App ID `6816346084`, bundle ID `ru.arvectum.tools.tosize`. [Public listing](https://apps.apple.com/ru/app/id6816346084). Android publication status is tracked independently.
**History and detailed specification:** [docs/history/ROADMAP-legacy-2026-10-11.md](docs/history/ROADMAP-legacy-2026-10-11.md). It is reference history, not a live checklist.
**Common principles:** [Core](../../docs/CORE_PRINCIPLES.md). **Acquisition/ASO and monetization experiments:** [Growth](../../docs/GROWTH_ROADMAP.md).

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
- [ ] Locate and verify exact source commit or archive for uploaded build **12**. Current Git `main` is still **0.6.2 (10)**; a version bump alone is not proof of provenance.
- [ ] Verify public-storefront propagation of 1.0.0 (public iTunes lookup still showed 0.6.2 during this audit).

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
