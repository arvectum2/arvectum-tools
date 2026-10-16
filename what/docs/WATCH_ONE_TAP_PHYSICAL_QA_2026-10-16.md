# Watch one-tap physical acceptance — Ухват 1.0.2

**Gate:** BLOCKED — physical one-tap Watch entry PASS by owner report; saved/playable audio on iPhone PASS by owner report; Digital Crown no-Stop autosave PASS by owner report; offline Watch-to-iPhone delivery PASS by owner report; **reboot recovery FAIL** (missing on iPhone), despite previous offline no-duplicate PASS; release BLOCKED, original Watch QA data must be preserved.

## Verified on 2026-10-16 (Mac mini, Xcode 27.1)

- Fixed 1.0.2 source: `fix/what-watch-autostart-1.0.2` at `9fed057` (foreground capture is a fallback when the complication URL is not delivered).
- `WhatWatch` watchOS simulator build PASS; 5 Watch launch policy state checks PASS.
- iOS test suite PASS: 61 tests run / 3 skipped / 0 failures, plus 2 UI tests PASS.
- Simulator cold launch automatically attempted audio session activation. Simulator returned microphone/audio failure: no proof of recorded AAC.
- Debug-signed **separate** QA build **1.0.2 (7)** installed successfully on physical iPhone 13 as `ru.arvectum.tools.what.qa` (name: UhWhat QA) and physical Apple Watch SE as `ru.arvectum.tools.what.qa.watch` (name: UhWhat QA). Installed complication extension bundle ID: `ru.arvectum.tools.what.qa.watch.capturewidget`, signature verified.
- QA app is distinct from production bundle IDs; production Watch/iPhone note storage was not touched or reset. No physical Watch microphone activation or watchface tap has been performed by these checks.

## Manual hardware acceptance (still unchecked)

- [x] **User-reported physical PASS (2026-10-16):** added **Ухват QA — Запись** complication on physical Apple Watch SE; a single tap from watch face started recording immediately, with no second tap. Evidence: owner explicitly confirmed in chat «во! кайф! теперь сразу началась». Latency was not measured; stop/audio integrity/phone delivery have not yet been confirmed.
- [x] **User-reported physical PASS (2026-10-16):** after recording via Watch, a new note appeared in **Ухват QA** on iPhone and its audio played with sound. This followed the requested Stop-button test. User explicitly confirmed «запись появилась, звук есть». Exactly-once delivery under retries/ACK not separately proven.
- [x] **User-reported physical PASS (2026-10-16):** after 5–10 seconds of recording, user pressed Digital Crown without Stop and confirmed «сохранилось!». This establishes that the note was saved; independent playback verification of this particular Crown-interrupted note was not explicitly reported.
- [ ] Repeat from watch face when app was fully closed/previously used. Confirm exactly one new recording per tap, no duplicate.
- [x] **User-reported physical PASS (2026-10-16):** with iPhone switched off, made two Watch voice notes. After turning iPhone back on, notes synchronized; audio plays and chronological order is correct. User confirmed «синхронизировалось. звук есть, порядок правильный». Exact count and absence of duplicates were not explicitly stated, so dedup/ACK remain unchecked.
- [x] **User-reported physical PASS (2026-10-16):** previous offline batch arrived without duplicates; user said «предыдущие записи появлялись без дублей, там все ок».
- [ ] **FAIL — RELEASE BLOCKER (2026-10-16):** owner recorded a Watch QA voice note while iPhone was off, rebooted Watch, restored iPhone connection, but the new recording did not appear on iPhone. **Not established whether Watch still retains the audio. Do not uninstall/reset Watch QA or erase data.** Investigate durable queue, transfer activation and remote device availability before retrying.
- [ ] Validate duplicate-ACK and retry/reboot recovery before public release.

**Do not upload, submit, or publish any 1.0.2 build until all critical Watch-face capture checks pass, with a recorded physical result.** The signed QA build is NOT a candidate for production upload.

## Investigation (2026-10-16)

- Inspected Watch transfer source: queue persists to Documents/WhatOutbound/queue.json; originals .m4a are deleted only on durable ACK. Watch session activates at app init/appear, pumps after activation and transfer completion; if Watch app has not been relaunched post-reboot it may not have resumed transfers. This is a hypothesis, not yet proven on the actual device.
- Read-only devicectl device copy from for the Watch QA queue index timed out due to intermittent Watch CoreDevice connection. No recordings or containers modified.
- Recovery priorities: access existing Watch QA container without reinstalling; check queue index and .m4a presence; safely re-activate WCSession/force a non-destructive sync before updating Watch QA on hardware.

## Isolated source-level recovery mitigation (2026-10-16, not deployed to Watch QA)

- iPhone now sends a durable, deduplicated WatchConnectivity sync request when its session becomes active; UI foreground entry can request again after cooldown.
- Watch listens for that request and retries the local queue, preserving UUIDs and originals until ACK.
- Watch re-reads the durable queue index and scans for finished orphaned AAC upon app foreground/activation after first device unlock. An unreadable existing index is not overwritten.
- Verified on Mac mini: Watch Simulator build PASSED; nine focused iOS tests PASSED; original broader 62 unit / 2 UI tests PASSED before last rehydrate change. The newly added restore test is among the nine focused tests.
- **This does not prove the missing recording is recoverable or identify its cause. The installed physical Watch QA remains the previous build and was NOT uninstalled or replaced.**
- Next physical checkpoint: determine whether user finalized the recording before reboot, then read Watch's pending count or recover its queue before installing an updated Watch QA build. No production release.

## 2026-10-16 physical reboot failure — forensic update

- Owner clarified that **Stop was pressed and capture had ended before reboot**. The missing item was not an interrupted recording.
- **Read-only device retrieval SUCCEEDED:** Watch QA Documents/WhatOutbound/queue.json exists post-reboot and contains **one** pending envelope with duration **4.412 s**. Index copied to ArvectumSSD under restricted builds/what-watch-qa-20261016/recovery-evidence/; recording UUID/file name is not checked into git. Original Watch QA data remains untouched.
- **Audio copy NOT YET VERIFIED:** subsequent read-only copy of queued m4a failed with CoreDevice error 4000 / RemotePairingError 1001 (connection tunnel timeout). An existing queue index is not proof that the AAC file is intact until a copy/validation or successful iPhone playback succeeds.
- The source retry/unlock restoration patch in fix/what-watch-autostart-1.0.2 is not yet installed on Watch QA. Keep release gate BLOCKED.
- Next non-destructive check: restore connectivity with both devices unlocked/close together; open existing QA app on Watch to pump queue and check outstanding count, verify original 4.4-s note on iPhone. If still pending, obtain AAC copy for integrity validation before any QA update.
