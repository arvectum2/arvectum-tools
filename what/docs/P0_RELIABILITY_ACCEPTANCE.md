# What? P0 — physical reliability acceptance

**Devices:** paired Apple Watch + iPhone 13 with What? developer build.
**Rule:** use new disposable recordings only; never delete preexisting private voice notes.
**Pass criteria:** each successful recording appears exactly once on iPhone, its original audio plays, and no pending Watch audio is deleted before phone storage is acknowledged.

## Checks to run

- [ ] **Offline batch:** turn off the actual Watch-to-iPhone link (verify Watch is disconnected, not merely airplane mode with Bluetooth still active). On Watch, record and save three *distinct*, numbered short voice notes. Verify Watch pending count is at least three. Reconnect. Wait for all three to arrive; verify each unique audio and pending count returns to zero.
- [ ] **Reboot with pending queue:** disconnect again, record a new disposable note, and reboot Watch *before* reconnecting. Confirm pending count and queued audio still exist after restart. Reconnect and verify the note transfers and plays on iPhone.
- [ ] **Duplicate and ACK safety:** keep the link connected across a retry/relaunch. Ensure the three notes each appear only once on iPhone even if transfers repeat. Confirm the watch removes a local recording only after phone acknowledgement.
- [ ] **Deletion versus late transfer:** delete one disposable note on iPhone, then allow a previously queued duplicate delivery of the same UUID; verify it stays deleted. This needs instrumented replay for determinism, not a manual new recording with another UUID.
- [ ] **Visible cancellation:** swipe one existing disposable recording, confirm that the system alert visibly shows Cancel and Delete permanently; press Cancel, verify recording and audio remain intact.

## Automated coverage (iOS receiver)

- Multiple unique files delivered after receiver restart with duplicate resend: testMultipleOfflineTransfersRetainDistinctAudioThroughReceiverRestart.
- Invalid metadata fails without indexing or copying: testInvalidTransferNeverCreatesARecordingOrAudioFile.
- Late resend after deletion, partial cleanup recovery, and distinct-recording preservation are also covered by repository tests.

**Do not mark P0 physically accepted solely because simulator or repository tests pass.** Note Watch and iPhone model, test timestamp, and counts for every physical pass.
