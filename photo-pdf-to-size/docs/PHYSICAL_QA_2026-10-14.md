# Фото и PDF под размер iOS 1.0.1 (13) — physical QA evidence, 2026-10-14

Historical state **as of 2026-10-14**: submitted to Apple and still under review. **Superseded 2026-10-15** by ASC READY_FOR_SALE confirmation of 1.0.1 (13). Current follow-ups and simulator/source patch findings are in [A4 post-release QA](A4_POST_RELEASE_QA_2026-10-15.md); this document preserves the earlier physical evidence.

## Verified by CoreDevice
- [x] Physical iPhone 13 has ru.arvectum.tools.tosize version 1.0.1 (13) installed.
- [x] Non-activated physical iPhone launch command succeeded.
- [x] Release branch already records 28 unit tests and 5 simulator UI tests, but those do not replace the pending physical checks.

## Critical manual acceptance still open
- [ ] Import new disposable fixtures from Photos and Files; keep originals unchanged.
- [ ] Export original dimensions, exact WxH and target file size across JPEG, PNG, HEIC; verify output bytes under size target.
- [ ] Test multi-page PDF orientation and large-file memory limits; check rasterization warning.
- [ ] Test RСЯ native/banner load with real production IDs and consent Accept/Decline + ATT statuses; debug demonstration ads do not prove production inventory.
- [ ] Confirm consent controls remain visible at maximum accessibility text size.
- [ ] Preserve user documents; never use personal Files as disposable fixtures.

Prior physical XCTest runner reportedly timed out during device automation setup; not evidence that the app itself failed a feature test.
