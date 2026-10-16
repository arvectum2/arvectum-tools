# Watch one-tap physical acceptance — Ухват 1.0.2

**Gate:** BLOCKED — waiting for actual complication-tap acceptance on physical Watch.

## Verified on 2026-10-16 (Mac mini, Xcode 27.1)

- Fixed 1.0.2 source: `fix/what-watch-autostart-1.0.2` at `9fed057` (foreground capture is a fallback when the complication URL is not delivered).
- `WhatWatch` watchOS simulator build PASS; 5 Watch launch policy state checks PASS.
- iOS test suite PASS: 61 tests run / 3 skipped / 0 failures, plus 2 UI tests PASS.
- Simulator cold launch automatically attempted audio session activation. Simulator returned microphone/audio failure: no proof of recorded AAC.
- Debug-signed **separate** QA build **1.0.2 (7)** installed successfully on physical iPhone 13 as `ru.arvectum.tools.what.qa` (name: UhWhat QA) and physical Apple Watch SE as `ru.arvectum.tools.what.qa.watch` (name: UhWhat QA). Installed complication extension bundle ID: `ru.arvectum.tools.what.qa.watch.capturewidget`, signature verified.
- QA app is distinct from production bundle IDs; production Watch/iPhone note storage was not touched or reset. No physical Watch microphone activation or watchface tap has been performed by these checks.

## Manual hardware acceptance (still unchecked)

- [ ] On Apple Watch, edit watch face and add **Ухват QA — Запись** complication, not production Ухват. From watch face, tap QA complication once. Confirm preparing → timer starts **without any second tap**.
- [ ] Stop after several seconds. Confirm saved status and exactly one playable note in **Ухват QA** on iPhone.
- [ ] Return to watch face using Digital Crown while recording and confirm finalized playable note reached iPhone.
- [ ] Repeat from watch face when app was fully closed/previously used. Confirm exactly one new recording per tap, no duplicate.
- [ ] Validate offline Watch → iPhone transfer, ACK and reboot recovery on physical devices before public release.

**Do not upload, submit, or publish any 1.0.2 build until all critical Watch-face capture checks pass, with a recorded physical result.** The signed QA build is NOT a candidate for production upload.
