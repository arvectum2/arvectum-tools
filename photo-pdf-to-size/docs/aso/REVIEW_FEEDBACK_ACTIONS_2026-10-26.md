# App Store feedback implementation / staged listing, 26 October 2026

**No App Store Connect changes, no review submission, no screenshots uploaded.**

## Feedback and actions
- [x] In-app photo/PDF source content remains entirely on iPhone. Removed direct ATT request, positive advertising consent and location forwarding in source. Preserved Yandex ads with user consent disabled; **transitive SDK manifest still declares Device ID tracking**, so label cannot honestly be changed to "nothing tracked". [Privacy audit](../appstore/APP_PRIVACY.md).
- [x] Technical document size presets: Schengen 35×45mm, China visa digital 354×472 px 40–120KB, Canada passport print 50×70mm. Regional requirements vary and an official application can reject edited photos; these presets are technical dimensions, not a guarantee.
- [x] English, British and Canadian/Australian App Store names and subtitles already drafted in 20-locale metadata. Refreshed EN/RU titles and search intent in `metadata-2026-10-26-review.json`. The currently live Russian-only listing is not updated.
- [x] First screenshot's claim is an actual observed result, **2.92 MB → 472 KB** (source `01-weight.png`), rather than a fabricated 2.4 MB figure. Second highlights true dimensions **5184×3456 → 600×400 px**. Different tasks are identified immediately.
- [x] Captured actual revised China visa and PDF views in a clean DEBUG simulator with advertising and the unrelated update prompt disabled. **12 staged 1320×2868 JPEG screenshots** for RU/en-US/en-GB, verified visually: no “Demo Ad” creative. SHA-256 in screenshot-review-manifest-2026-10-26.json. Image sets remain draft, never uploaded.
- [ ] Accessibility Nutrition Labels: draft only; real AXXXL and layout tests exist, physical VoiceOver/contrast/manual acceptance remains required before asserting support for specific Apple features.
- [ ] Metadata and privacy nutrition answers require explicit live App Store listing approval; signed artefacts alone are not permission.

## Accessibility section — proposed verification

Only select Apple accessibility features that work for **all core user tasks** on the final binary. Candidates: **VoiceOver**, **Larger Text**, **Dark Interface**, **Sufficient Contrast**. XCTest covers several AXXXL and accessibility scenarios but cannot certify complete physical VoiceOver navigation, processing, Files picker and export flow. Test them, document pass/fail and then select exact App Store labels; do not fill unverified checkboxes.

## Local design
Four screens at iPhone large-screen resolution (1320×2868 marketing composite) with clear numeric headings, original app UI, no live ad or fake downloaded document:
1. Compression to KB, a genuine **2.92 MB → 472 KB** result.
2. Pixel dimensions, genuinely **5184×3456 → 600×400**.
3. China visa photo preset from the updated app, with other regions explicitly mentioned as available.
4. PDF before/after under a chosen 100 KB limit, if the genuine QA fixture can be processed to this value.

The thumbnail may include Apple simulator status bar, but no synthetic “Demo Ad” / Yandex creative, no claim of guaranteed visa acceptance, and no assertion of zero SDK telemetry. Marketing images are staged locally, **not uploaded**.

## Actual rendered preview paths

- `store-assets/appstore/review-20261026/ru/iphone-6.9/`: 01 photo KB, 02 pixel dimensions, 03 China visa, 04 PDF.
- `store-assets/appstore/review-20261026/en-US/iphone-6.9/`: 01 photo KB, 02 pixel dimensions, 03 China visa, 04 PDF.
- `store-assets/appstore/review-20261026/en-GB/iphone-6.9/`: 01 photo KB, 02 pixel dimensions, 03 China visa, 04 PDF.

Screenshot 01/02 source is a real, earlier on-device result showing 2.92 MB→472 KB and 5184×3456→600×400. Source has an older top bar label; re-capture with the final approved Release binary before publication. Screenshots 03/04 are from the current iOS 27.0 simulator and have no SDK ads or update overlays. Final human design and claims review is still a release gate.
