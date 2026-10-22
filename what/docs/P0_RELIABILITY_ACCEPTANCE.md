# What? P0 — physical reliability acceptance

**Devices:** paired Apple Watch + iPhone 13 with What? developer build.
**Rule:** use new disposable recordings only; never delete preexisting private voice notes.
**Pass criteria:** each successful recording appears exactly once on iPhone, its original audio plays, and no pending Watch audio is deleted before phone storage is acknowledged.

**Current verified physical status:** see [Watch/iPhone deduplicated acceptance matrix](PHYSICAL_WATCH_ACCEPTANCE_DEDUP_2026-10-22.md). Historical unchecked rows below predate later physical passes and are not an instruction to rerun them.

## Checks to run

- [x] **Offline batch (partial physical pass on 2026-10-13):** turn off the actual Watch-to-iPhone link (verify Watch is disconnected, not merely airplane mode with Bluetooth still active). On Watch, record and save three *distinct*, numbered short voice notes. Verified 3 waiting for iPhone, reconnected, all three appeared after opening iPhone app. **Still verify automatic background delivery without opening iPhone and audio distinctness. User confirmed Watch pending count cleared to zero after 3/3 arrived.**
- [ ] **Reboot with pending queue (partial already 13.10):** Watch retained one queued audio after reboot of build 5; it arrived later after installing build 6 and opening Watch. Full current-build reboot + first unlock + automatic background delivery remains unverified. Avoid repeating on personal devices without a safe approved procedure.
- [x] **Lost ACK / same-UUID physical replay (19.10):** Watch suppressed one real ACK, resent the original, and received a second real ACK. iPhone indexed the UUID only once; Watch queue cleared. [Physical report](PHYSICAL_WATCH_LOST_ACK_REDELIVERY_2026-10-19.md). Distinct offline batch replay stress is a separate open gate.
- [ ] **Deletion versus late transfer:** delete one disposable note on iPhone, then allow a previously queued duplicate delivery of the same UUID; verify it stays deleted. This needs instrumented replay for determinism, not a manual new recording with another UUID.
- [ ] **Visible cancellation:** swipe one existing disposable recording, confirm that the system alert visibly shows Cancel and Delete permanently; press Cancel, verify recording and audio remain intact.

## Automated coverage (iOS receiver)

- Multiple unique files delivered after receiver restart with duplicate resend: testMultipleOfflineTransfersRetainDistinctAudioThroughReceiverRestart.
- Invalid metadata fails without indexing or copying: testInvalidTransferNeverCreatesARecordingOrAudioFile.
- Late resend after deletion, partial cleanup recovery, and distinct-recording preservation are also covered by repository tests.

**Do not mark P0 physically accepted solely because simulator or repository tests pass.** Note Watch and iPhone model, test timestamp, and counts for every physical pass.

## Apple background-delivery expectation

WCSession.transferFile is opportunistic and may be delayed by watchOS/iOS for power management. Do not promise immediate delivery after reconnection. The iPhone app must not need to be opened to eventually receive background transfers, but this remains a physical acceptance target, not a guaranteed timing SLA. A lost acknowledgement should trigger another transfer under the 90-second retry gate when the Watch app executes, using the same UUID.

## Physical installation and developer-connection evidence (2026-10-13)

- Paired physical Apple Watch SE running watchOS 26.6 was visible to Xcode as *available (paired)* but the developer tunnel had disconnected; iPhone 13 remained connected.
- Watch Developer Mode remained enabled; Watch/iPhone consumer pairing remained healthy.
- Restored developer connection without resetting devices by running `xcrun devicectl manage pair --device <watch-UDID>` against the existing pairing. Verified `Device State: connected` and a tunnel IP in CoreDevice.
- Installed signed What? watch app build 0.1.0 (5) directly using `devicectl device install app`. Verified installed bundle version 5 (previous version was 2), device remains connected.
- `devicectl device process launch` timed out despite successful install, so launching the app on the watch by hand is **not yet verified**. Watch data container export also timed out. Do not claim on-watch P0 acceptance from these commands.
- No device was unpaired from its consumer companion, reset, or erased.


## Short-audio fast path (build 6 installed; first physical end-to-end pass)

- Uses immediate WatchConnectivity.sendMessageData for audio <= 768 KiB when the Watch app is active and the iPhone can be woken in the background.
- Independently queues background transferFile for offline/unreachable or oversized recordings.
- The iPhone writes the original audio to durable repository storage, then sends an immediate reply and redundant queued ACK. Watch erases its copy only after successful storage confirmation.
- Both paths share the recording UUID and repository duplicate/deletion protection.
- Physical finding: with build 5, an offline rebooted recording stayed in Watch queue after reconnection and after opening Watch app, while the iPhone remained at nine prior recordings. The user had not yet opened the iPhone app for this test at the time of inspection.
- [ ] Reopen What? on Watch with the iPhone app closed and linked; record a disposable 2-second note. Check Watch pending count clears and iPhone eventually displays exactly one playable copy.
- [x] Previously stuck pending recording cleared its Watch queue and appeared in iPhone What?, with successful audio playback, after build 6 was installed. The user opened only the Watch app to initiate the check. This demonstrates complete end-to-end delivery without launching the iPhone UI, but does not identify the exact internal channel.
- [x] User confirmed two new consecutive short recordings cleared the Watch queue automatically, and both appeared on iPhone without manually opening the iPhone app (2026-10-13).\n- [ ] Repeat stress tests after ACK loss / longer offline windows / larger audio; record exact timing and UI duplicate counts.
- [ ] Inspect logs/diagnostics for actual fast-path vs background file routing and timing when necessary.
