# Фото и PDF под размер — Product Roadmap

## Active release checkpoint — 2026-10-15

**Published iOS baseline:** **1.0.1 (13)**, owner-confirmed and independently verified **READY_FOR_SALE** via authenticated App Store Connect API on **2026-10-15**. Previous version 1.0.0 (12)
was published 2026-10-11. The signed 1.0.1 build was submitted for review
2026-10-13 from the release/photo-size-ios-1.0.1 branch.
Owner confirmation and an authenticated ASC API lookup both supersede the
old under-review state; per-region storefront propagation was not checked.
Apple App ID 6816346084; bundle ID ru.arvectum.tools.tosize.
[Public App Store listing](https://apps.apple.com/ru/app/id6816346084).

- [x] 1.0.1 (13) published — owner-confirmed 2026-10-15.
- [x] 1.0.1 signed upload, 20 localised release notes, consent text-size fix,
  28 iOS unit and 5 simulator UI tests recorded in release branch.
- [x] Verified exact App Store version 1.0.1 READY_FOR_SALE and build 13 VALID
  via authenticated ASC API 2026-10-15.
- [ ] Verify regional public storefront indexing if required by a target market.
- [ ] Post-release physical Files/Photos import, image/PDF export, PDF
  orientation and large-file memory, ATT/consent and live ad fill QA.
  A demo ad or UI test alone cannot establish real advertising impressions.
- [x] Original signed source tagged (`photo-size-ios-v1.0.1-build13`),
  archived IPA checksum verified, release automation/metadata and signing
  integrated with Core-based main via PR #67; older direct-palette project
  deliberately not merged.
- [ ] Independently verify Android publication; none confirmed so far.

**Updated:** 2026-10-15.
**Ownership:** image/PDF sizing, presets, export, UX, app-specific SDK, QA and releases.
**Evidence:** [1.0.0 release](docs/appstore/RELEASE_1.0.0_2026-10-11.md),
[1.0.1 release branch](https://github.com/arvectum2/arvectum-tools/blob/release/photo-size-ios-1.0.1/photo-pdf-to-size/ROADMAP.md),
[physical QA](docs/PHYSICAL_QA_2026-10-14.md).
**Historical roadmap:** [archive](docs/history/ROADMAP-legacy-2026-10-11.md).
**Core:** [common infrastructure](../core/ROADMAP.md).
**Growth:** [distribution and ASO](../growth/ROADMAP.md).

## Current implemented capability (repository-recorded; validate against shipping build)
- [x] Local image file-size and dimension modes; document-photo presets.
- [x] PDF target-size mode added in 0.6.0 with local processing and rasterization warning.
- [x] Photo import from Files/iCloud, exact W×H, JPEG/PNG/HEIC export options, EXIF controls, print sheets.
- [x] International document presets RU/US/India/UK (country-specific constraints documented).
- [x] RU/EN localization, system Light/Dark UI and lower primary CTA placement.
- [x] Home native ad and result banner recorded as production integration in 0.5.1.
- [x] Store screenshots prepared showing before/after; this is a completed asset task, not a pending product feature.
- [x] iOS release v1.0.0 publicly launched, 2026-10-11.

## Distribution history and current 1.0.1 follow-ups

- [x] 1.0.0 (12) published 2026-10-11, signed source and archive recorded.
- [x] 1.0.1 (13) signed, uploaded and sent to App Review on 2026-10-13.
- [x] 1.0.1 (13) publicly released by 2026-10-15 (owner confirmation).
- [x] Accessibility consent fixes and automated QA recorded on release branch.
- [ ] Associate exact public 1.0.1 build with source SHA, release tag,
  public storefront evidence and reproducible signed archive.
- [ ] Complete physical post-release validation of Files/PDF/ads/ATT.

## Maintenance: Core and dependency alignment (2026-10-13)

- [x] Replace direct Core palette source inclusion with the local `ArvectumCore` SwiftPM dependency; keep product-specific adaptive colors here.
- [x] Confirm iOS Yandex Mobile Ads 8.6.0 matches the Core catalog and checked-in SwiftPM lock; keep stable native/banners implementation while adopting Core.
- [x] Extend scoped CI to verify Core dependency contracts and to respond to Core manifest/catalog edits; ensure Android version-catalog changes run Android CI.
- [x] Xcode 27 validation: 4 Core tests, 28 iOS unit tests, 5 simulator UI tests passed (5 physical-Files UI tests skipped by design); Android test/lint/assemble passed.
- [ ] Run real-iPhone advertising checks (native + banner, consent yes/no,
  ATT status) and export regression as **post-release 1.0.1 QA**.
- [ ] Use physical QA findings to gate any **future** corrective patch;
  do not retroactively describe the published 1.0.1 as a candidate.

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
