# ChickMark 1.3 screenshot masters — not uploaded

Generated 2026-10-10 using iPhone 17 Pro iOS 26.5 Simulator and the real 1.3 SwiftUI screens (debug-seeded synthetic data).

- `en/`, `ru/`, `es/`: three raw PNGs each.
- `01_today.png`: habit list with independent 3/5 check-ins.
- `02_detail.png`: calendar history and stats.
- `03_manage.png`: habit management and groups entry.
- Native pixel dimensions: **1206 × 2622** each; these are raw masters, not necessarily accepted as final App Store screenshot sizes.
- No personal data; synthetic data is injected in DEBUG only by `--seed-screenshot-demo`.
- No Apple upload, marketing publishing or public release.

## Editorial gates
- [ ] Check each language's visual truncation/layout against source PNGs, especially RU and ES.
- [x] Raw Watch screenshots for EN/RU/ES on a watchOS 27 simulator (see ../1.3-raw-watchSE3/).
- [ ] Final App Store-accepted Watch screenshot dimensions and native editorial review.
- [ ] Export final App Store-compatible dimensions with correct crop/device family and no stretching.
- [ ] Add App Store caption/benefit hierarchy (if useful) after feature UI freeze.
- [ ] Confirm App Store Connect accepted sizes before uploading.

The XCUITest methods `testStoreScreenshotsEnglish/Russian/Spanish` produce kept XCResult screenshot attachments with reproducible fixture data. The source screenshots in this directory were exported from those attachments. Russian title assertions were corrected and separately retested.
