# Фото и PDF под размер iOS 1.0.1 (13) — physical QA evidence, 2026-10-14

State: submitted to Apple and still under review, per owner on 2026-10-14. Do not claim public 1.0.1 until approval.

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
