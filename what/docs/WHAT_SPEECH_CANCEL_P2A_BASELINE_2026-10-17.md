# UhWhat? — Speech cancellation and P2a baseline, 2026-10-17

## Speech cancellation bug and fix

The previous PhoneStore checked only the recording UUID when delayed authorization or Speech final-result/error callbacks arrived. Following Cancel and immediate Retry on the **same recording UUID**, a previous attempt could be mistaken for the new one and overwrite an edited transcription.

SpeechAttemptGate now issues a unique UUID for each recognition attempt. All delayed Speech authorization and recognition callbacks must match BOTH the recording and attempt IDs. Cancel and Finish invalidate that token before asynchronous callbacks can mutate state. Audio repository schema, audio bytes, automatic transcription and Watch ACK/queue are unchanged.

The failure strings for denied Speech permission, unavailable on-device recognizer, silence, text-save failure and transcription error are translated RU/EN and explicitly state audio preservation.

## Verified synthetic and simulator tests

- 5/5 focused SpeechAttemptGateTests PASS: cancellation before permission callback, stale same-note retry, stale denied authorization during a new batch, corrected transcript integrity, denied-permission transcript integrity. They do not require or change real Speech permissions and do not assert successful real-device denial UX.
- Serial WhatIOS full suite PASS (Xcode 27.1 / iPhone Duo Simulator): 68 unit/integration tests (3 skipped), 5 UI tests, zero failures. Log on ArvectumSSD: builds/what-speech-cancel-race-20261017/full-serial.log.
- Earlier simultaneous simulator suites interfered with each other, causing a test-process crash and a transient UI test failure. Both test series were rerun separately, resulting in green results. Do not count interrupted overlapping runs as production acceptance.

## Existing multimodal M1 baseline

The separate feature branch feature/what-multimodal-20261016 already contains LocalNoteRepository, unified audio/text/video Inbox, text editor, long-press video, camera-switch segments, crash recovery, adaptive iPad layouts and opt-in reminders. It was not rewritten or cherry-picked into the release branch here.

- iOS Simulator build PASSED, under builds/what-multimodal-m1-baseline-20261017.
- 3/3 LocalNoteRepositoryTests PASSED when run serially: text autosave/relaunch without changing Watch audio index; unified Inbox filters; video copies and deletion without removing the source. Log: builds/what-multimodal-m1-baseline-20261017/m1-test-serial.log.
- Existing VideoSegmentComposer emits a Swift sendability warning regarding capture of AVAssetExportSession in a sendable closure. The video branch still needs review and physical camera QA.
- P2a branch has not been integrated with all tested Watch P0/P1 fixes. Do not install it over existing production or stable QA stores before safe integration and migration review.

## Open gates

- [ ] In-place iPhone QA test of cancelled/retried transcription on a newly created test note. Never edit or delete the previous corrected Russian test note.
- [ ] Optional physical denied-permission QA, without disrupting granted permissions in routine use.
- [ ] Integrate the existing multimodal feature branch and tested Watch fixes in a new, isolated worktree; perform full regression and signed QA with separate app IDs.
- [ ] Camera/video/iPad physical acceptance, and eventual owner decision on release scope.
- [ ] No App Store upload or review submitted.

## QA12 hardware blocker and independent P2a branch

Signed iPhone QA12 on ArvectumSSD: builds/what-speech-cancel-qa12-20261017/Build/Products/Debug-iphoneos/WhatIOSQA.app. CoreDevice reports iPhone Nikita unavailable, usage assertion error 4016 when backing up QA Application Support. No installation attempted. Existing iPhone QA11, Watch QA10 and production data remain unchanged. Restore trusted connection first, back up existing data and check hashes before in-place upgrade.

P2a integration is preserved in separate remote branch integration/what-multimodal-watch-20261017 with its own checkpoint in what/docs/WHAT_P2A_WATCH_INTEGRATION_2026-10-17.md. Full integration test case counts are green; Xcode result-finalization, physical camera testing and signed dedicated multimodal QA remain open. No App Store upload.


## QA12 in-place physical iPhone installation and SHA-256 verification (2026-10-17)

After owner said «готово», trusted CoreDevice connectivity to physical iPhone 13 was restored. Inventory showed QA bundle ru.arvectum.tools.what.qa version 1.0.2 (11). Confirmed locally signed iPhone QA (12) build from builds/what-speech-cancel-qa12-20261017/Build/Products/Debug-iphoneos/WhatIOSQA.app (signed with QA-only ID).

Performed pre-install read-only devicectl device copy from for QA iPhone Application Support to ArvectumSSD at builds/what-speech-cancel-qa12-20261017/device-backup/iphone-support-before-1242. It included 22 files totaling 907507 bytes; recorded individual SHA-256 in manifest-before-1242.json. In-place CoreDevice install returned 0; fresh app inventory confirmed **1.0.2 (12)**. Re-read the entire QA Application Support into iphone-support-after-1242 and compared manifest-after-1242.json against original: **22 files before, 22 after, 0 missing, 0 added, 0 changed SHA-256**.

This proves application-support file contents were byte-identical immediately after install, before user exercised the new feature. It does not itself prove active speech-cancellation behavior or future storage durability.

No App Store upload; no production app uninstall/reinstall; no Watch app update or queue manipulation. Watch still last confirmed QA10. Physical owner cancellation/retry and original audio check are now the remaining QA12 acceptance gate.


## QA13 — deterministic physical cancellation check (2026-10-17)

QA12 owner found manual retry finishes too fast to cancel, neither pass nor fail. QA13 implements a temporary opt-in diagnostic ONLY in the local isolated QA source worktree, NOT in production/PR #84: under Sync diagnostics toggle «Задержать результат повторной расшифровки на 25 секунд». This in-memory switch resets on app relaunch and delays only the final real Speech callback from the explicit manual repeat; incoming automatic notes still transcribe immediately. The delayed callback checks the exact same recording UUID and Speech attempt token after 25 seconds; cancellation invalidates the token and should prevent replacement of manually corrected text. Audio repository and Watch delivery are unchanged.

QA 1.0.2 (13) signed, QA bundle ID verified, installed in place on iPhone 13; inventory confirmed version. Pre-install and post-install private QA Application Support snapshots saved on ArvectumSSD in builds/what-speech-cancel-hold-qa13-20261017/device-backup, with 23/23 SHA-256-identical files, no additions or removals. No production app, Watch or user notes removed; no public upload.

Physical procedure: on iPhone QA13 open «Мои записи» -> «…» -> «Диагностика синхронизации», enable 25-second QA-only hold, tap «Готово»; ONLY on the latest disposable QA test note edit the text to include «Контроль отмены 13»; choose «Повторить расшифровку» -> «Заменить текст» and tap the in-progress «Отмена» button; wait >=30 seconds; the marker and original audio should remain intact. Disable the test toggle after checking. Physical acceptance remains pending user report.

## QA13 physical follow-up (2026-10-17)

After installation and the guided delayed-retry test, owner reported verbatim «Измененный текст сохраняется, исходный звук сохраняется». **Physical preservation of the edited transcript and original audio PASS.** The reply did not explicitly say whether the in-progress Cancel button was pressed. **Cancel-action and stale-result suppression on physical iPhone remain unconfirmed** until owner answers that one point. Do not substitute fast result completion or data preservation alone for an observed cancellation event. QA-only hold remains outside production source; remind owner to disable it after the test.
