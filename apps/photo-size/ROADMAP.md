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

## Release 1.0.0 — completed distribution gate
- [x] Submitted to App Review on 2026-10-10 (product owner confirmation).
- [x] Passed App Review on 2026-10-11 (product owner confirmation).
- [x] App Store Connect dashboard verified on 2026-10-11: `Фото и PDF под размер`, iOS `1.0.0`, status `Ready for Distribution` (authenticated Safari visual verification, Mac mini).
- [x] Publication confirmed by product owner on 2026-10-11.
- [ ] Verify propagation of public storefront metadata: Apple iTunes lookup (RU) still returned `0.6.2` on 2026-10-11, despite App Store Connect showing `1.0.0 Ready for Distribution`.
- [ ] Open App Store Connect version detail to obtain exact build number, review events and uploaded build provenance; dashboard status alone does not disclose build number. Safari GUI read is available via screenshot, but scripted navigation is waiting for explicit macOS screen/control permission.
- [ ] Align release tag and the checked-in iOS `MARKETING_VERSION` with the archived shipping source **only after** verifying the exact build; the default branch currently declares `0.6.0 (8)`.

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
