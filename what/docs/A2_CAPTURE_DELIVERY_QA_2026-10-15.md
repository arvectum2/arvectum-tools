# Ухват — A2: Watch capture and reliable delivery

**Checkpoint:** 2026-10-15. Changes are post-submission source fixes, not part of the 1.0.1 (6) binary already sent for Apple review. The last authenticated App Store check on 2026-10-15 found 1.0.1 WAITING_FOR_REVIEW.

## Investigated flow

1. Watch complication uses widgetURL(what://capture); CaptureView.onOpenURL calls startCapture without deliberately requiring another tap. Only a real Watch-face tap can establish the OS routing behavior.
2. Watch records AAC, attempts to finalize on background/Digital Crown, and stores UUID-named audio and a durable outbound queue. A force-quit or sudden loss of power before AAC finalization can still leave incomplete audio.
3. WatchConnectivity uses live delivery plus background transferFile with stable recording UUID, and iPhone RecordingRepository deduplicates repeated receipt.
4. The Watch must not delete its original audio until the iPhone has durably saved it and acknowledged that UUID.

## A2 corrections

- Atomic queue transitions: WatchDurableQueue first commits a new queue.json, then updates in-memory queue; used for enqueue, ACK removal and recovery after failure. If writing the index fails, current state and original audio remain intact.
- AAC integrity on the receiver: before sending ACK, iPhone validates the transferred file is decodable, has plausible file size and recorded duration. Corrupt or header-only audio is not acknowledged; Watch keeps its original for retry.
- No changes to app data schema, cloud permissions or commercial license assets. No user device files modified. No change to the already-submitted App Store binary.
- New GitHub what-ios-ci workflow tests capture reliability and compiles Watch app + complication on changes to What source.

## Engineering checks

- [x] Architecture and shared SwiftPM dependency catalog PASS.
- [x] iOS Simulator build-for-testing PASS; watchOS Simulator build PASS; Xcode 27.
- [x] New focused A2 tests: **7/7 PASS** on isolated iPhone 17, iOS 27 simulator. Cases: offline multi-recording durable queue, repeated ACK, disk commit failure on enqueue/ACK, recovered orphan index, corrupted AAC rejected, playable generated AAC accepted and mismatched duration rejected, p95 percentile helper.
- [x] Complete WhatIOSTests: **61 tests, 0 failures, 3 skipped** (54 pre-existing tests + 7 new). This is not physical-device acceptance.
- [ ] GitHub CI acceptance/PR and mirrored main SHA: verify separately after push.
- [ ] Physical paired Apple Watch/iPhone acceptance: cannot mark complete from simulators.

## Physical acceptance still required

- [ ] Tap the complication on real Watch face: recording must begin in **one tap** without another Record button. Collect at least 10 local tap-to-microphone-ready timings and report observed median/p95. No note contents in logs.
- [ ] During recording press Digital Crown, then verify the completed AAC is playable and shows expected duration on Watch and iPhone, including after reopening both apps.
- [ ] Record three distinct notes with connectivity off; reconnect and verify three playable files on iPhone, exactly once each, original file retained until ACK and Watch queue reaches zero only afterward.
- [ ] Simulate lost ACK/repeated delivery; verify same UUID does not create duplicate notes or resurrect deleted/archived ones.
- [ ] Check denied microphone, app background interruption, encoding failure, out-of-space handling, and power interruption warnings. Do not claim zero loss for power failure before file finalization.
- [ ] Confirm Watch+iPhone bundle contents exclude private RuWordNet-derived corpus and release patch under a future version after Apple review status is known.

This QA evidence is source/simulator-only. No microphone permission or user records on a physical iPhone or Watch were modified.
