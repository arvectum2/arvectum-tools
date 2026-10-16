# Watch one-tap physical acceptance — Ухват 1.0.2

**Gate (2026-10-17):** CORE PHYSICAL ACCEPTANCE PASS — one-tap Watch launch, Stop/save/audio, offline transfer/order/no duplicates, and automatic Watch reboot recovery/audio/no duplicates verified by owner on physical QA 1.0.2 (8). Earlier QA build (7) reboot failure is preserved below for diagnosis and resolved in QA (8). Public release remains blocked pending remaining targeted edge-case checks, production signing, and release authorization.

## Verified on 2026-10-16 (Mac mini, Xcode 27.1)

- Fixed 1.0.2 source: `fix/what-watch-autostart-1.0.2` at `9fed057` (foreground capture is a fallback when the complication URL is not delivered).
- `WhatWatch` watchOS simulator build PASS; 5 Watch launch policy state checks PASS.
- iOS test suite PASS: 61 tests run / 3 skipped / 0 failures, plus 2 UI tests PASS.
- Simulator cold launch automatically attempted audio session activation. Simulator returned microphone/audio failure: no proof of recorded AAC.
- Debug-signed **separate** QA build **1.0.2 (7)** installed successfully on physical iPhone 13 as `ru.arvectum.tools.what.qa` (name: UhWhat QA) and physical Apple Watch SE as `ru.arvectum.tools.what.qa.watch` (name: UhWhat QA). Installed complication extension bundle ID: `ru.arvectum.tools.what.qa.watch.capturewidget`, signature verified.
- QA app is distinct from production bundle IDs; production Watch/iPhone note storage was not touched or reset. No physical Watch microphone activation or watchface tap has been performed by these checks.

## Manual hardware acceptance (historical results and pending checks)

- [x] **User-reported physical PASS (2026-10-16):** added **Ухват QA — Запись** complication on physical Apple Watch SE; a single tap from watch face started recording immediately, with no second tap. Evidence: owner explicitly confirmed in chat «во! кайф! теперь сразу началась». Latency was not measured; stop/audio integrity/phone delivery have not yet been confirmed.
- [x] **User-reported physical PASS (2026-10-16):** after recording via Watch, a new note appeared in **Ухват QA** on iPhone and its audio played with sound. This followed the requested Stop-button test. User explicitly confirmed «запись появилась, звук есть». Exactly-once delivery under retries/ACK not separately proven.
- [x] **User-reported physical PASS (2026-10-16):** after 5–10 seconds of recording, user pressed Digital Crown without Stop and confirmed «сохранилось!». This establishes that the note was saved; independent playback verification of this particular Crown-interrupted note was not explicitly reported.
- [x] **QA (8) final physical regression PASS (2026-10-17):** one Watch complication tap -> audio capture -> Digital Crown -> iPhone note playable without duplicates. Owner explicitly confirmed «Все супер, звук есть, дублей нет». Fully-closed app state was not separately reported.
- [x] **User-reported physical PASS (2026-10-16):** with iPhone switched off, made two Watch voice notes. After turning iPhone back on, notes synchronized; audio plays and chronological order is correct. User confirmed «синхронизировалось. звук есть, порядок правильный». Exact count and absence of duplicates were not explicitly stated, so dedup/ACK remain unchecked.
- [x] **User-reported physical PASS (2026-10-16):** previous offline batch arrived without duplicates; user said «предыдущие записи появлялись без дублей, там все ок».
- [x] **Historical QA (7) failure, RESOLVED on QA (8):** owner had recorded with iPhone off, pressed Stop and rebooted Watch; background transfer originally did not restart. The original 4.412-s queued note was recovered upon manual opening of Watch QA (7). In QA (8), automatic delivery after the same reboot sequence passed with audio and no duplicates. Do not treat the earlier failure as still active.
- [x] **Physical reboot/reconnect delivery with no duplicates (QA 8):** owner reported automatic iPhone delivery, playable audio, and exactly one copy after Watch restart without manual Watch app launch. A single trial cannot exercise every network/ACK race.\n- [x] **QA (8) final one-tap + Crown + playback + no-duplicates PASS.** A fully force-closed app and repeated network/ACK races are not independently tested.

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

## Recovery result (2026-10-16)

- **Owner-reported PASS — missing note was delivered after manually opening the existing Watch QA app:** user placed Watch near iPhone, opened QA app on Watch (which automatically began a new recording), and confirmed: «да, теперь появилась предыдущая запись».
- This confirms the **prior pending note survived reboot and was eventually delivered**; it does not confirm automatic post-reboot sync, media playback of that specific note, or deduplication during reboot.
- Strongly suggests WatchConnectivity resuming/pumping only when Watch app enters foreground. The 1.0.2 sync-request + index-unlock recovery source fix remains untested on physical Watch. DO NOT release until the phone-triggered recovery passes with no manual Watch launch.

## Revised physical QA build 8 staging (2026-10-16)

- A separate, signed QA 1.0.2 (8) build was generated from the recovery-fix branch. Both QA identifiers remain unchanged: iPhone ru.arvectum.tools.what.qa, Watch ru.arvectum.tools.what.qa.watch, complication ru.arvectum.tools.what.qa.watch.capturewidget. Production apps are not changed.
- **iPhone QA build 8 installed in-place successfully** (same app bundle identifier); pre-upgrade backup of the QA app's Application Support is on ArvectumSSD. Read-only post-upgrade verification: 13 files before, 13 after, no missing paths, all sizes unchanged.
- **Watch QA build 8 NOT installed**: Apple Watch not currently reachable via Mac mini CoreDevice, and user has not confirmed that a recording isn't active. Keep the existing Watch QA build 7 and all Watch user data untouched. Signed Watch QA build 8 remains staged in builds/what-watch-recovery-qa-20261016.
- **NEXT GATE:** ensure Watch QA capture is stopped, unlock Watch, keep it alongside Mac mini/paired iPhone until CoreDevice connects; install the matching signed Watch QA build 8 in-place (never uninstall) and repeat the reboot/offline sync test **without manually opening the Watch app**.

## QA build 8 deployment to physical devices (2026-10-16)

- User confirmed Watch was unlocked and Watch QA capture was stopped before deployment.
- Mac mini CoreDevice reconnected to the paired physical Apple Watch SE. Existing Watch QA identified as 1.0.2 (7).
- **Read-only Watch backup succeeded before deployment:** Documents/WhatOutbound/queue.json recorded 0 pending envelopes. Backed up complete WhatOutbound directory (one index file) to restricted ArvectumSSD builds/what-watch-recovery-qa-20261016/device-backup/.
- **Watch QA 1.0.2 (8) installed successfully IN PLACE**, bundle ru.arvectum.tools.what.qa.watch unchanged; no uninstall, no container reset. The installer reported successful installation, and its subsequent initial installed-app listing confirmed 1.0.2 (8).
- **iPhone QA 1.0.2 (8)** had already been installed in place; 13 Application Support files were preserved across upgrade and a backup exists.
- Post-upgrade read-only Watch queue check was attempted but CoreDevice pairing tunnel timed out; therefore post-upgrade Watch queue index was **not independently read**. No modification or deletion was performed as part of this check.
- **Pending physical release test:** with iPhone switched off, record on Watch QA build 8, press Stop, reboot Watch, unlock Watch after reboot WITHOUT opening Watch QA, switch on iPhone, open iPhone QA build 8 and wait 2–3 minutes. Confirm that the recording appears automatically and plays, without another tap on the Watch app; inspect for duplicates. App Store release remains BLOCKED until acceptance passes.

## User acceptance: automatic transfer after reboot on QA build 8 (2026-10-17)

- **USER-REPORTED PHYSICAL PASS — automatic delivery:** following the prescribed test of Watch QA 1.0.2 (8), the owner stated «Появилась запись! Ура!». In this test iPhone was off while recording on Watch, Stop was pressed, Watch was rebooted and unlocked without opening Watch QA, then iPhone QA was opened after iPhone startup. The missing-note issue from build 7 did not reproduce: note appeared automatically, without a manual Watch app launch.
- **Owner confirmation of audio and exactly-once delivery:** user explicitly stated «Звук есть, дублей нет» immediately after the automatic post-reboot sync test. Marked PASS for this exact QA (8) reboot recording. No independent on-device audio checksum, so this is physical user playback acceptance, not a formal bitwise comparison.
- This is one complete successful physical reboot-recovery acceptance trial, not proof of every possible network-retry failure mode. The originally failing case is resolved in QA (8); remaining targeted regression checks and production release steps are tracked separately, so public release has not been submitted.

## Full final-branch simulator regression (2026-10-17)

- After the Watch reboot recovery patch and successful physical QA (8) playback/dedup confirmation, ran full WhatIOS scheme test suite on Mac mini Xcode 27.1, iPhone Duo iOS simulator.
- **PASS:** 63 unit/integration tests executed with 0 failures, 3 skipped; 2 UI tests executed with 0 failures; xcodebuild TEST SUCCEEDED, exit status 0.
- Test log is stored on ArvectumSSD under builds/what-reboot-recovery-final-gate-20261017/test-ios.log. This is simulator regression evidence, not a production release upload or another physical verification.

## Final QA (8) one-tap and Crown regression acceptance — 2026-10-17

- After verifying QA (8) automatic post-reboot sync, owner performed prescribed regression: one tap on Apple Watch-face QA complication -> several seconds of capture -> Digital Crown instead of Stop -> playback on iPhone.
- Owner explicitly reported «Все супер, звук есть, дублей нет».
- **PASS:** watch-face one-tap launch, Digital Crown save/delivery, original audio playable, no duplicate notes. This is the post-fix physical regression test, not just older QA (7) acceptance.
- This and automatic post-reboot QA (8) sync close the reproduced P0 physical Watch capture/sync blockers. Apple upload still requires release approval and current CI.
