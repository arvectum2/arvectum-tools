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
