# Ухват / UhWhat? 1.0.0 (5) — physical QA evidence, 2026-10-14

State: App Store build 5 under review (owner-confirmed), not yet publicly released.

## Verified by CoreDevice
- [x] Physical iPhone 13 has ru.arvectum.tools.what 1.0.0 (5) installed and non-activated launch succeeded.
- [x] Paired physical Apple Watch SE has ru.arvectum.tools.what.watch 1.0.0 (3), NOT the release branch's intended build 5.
- [x] CoreDevice Watch connection recovered sufficiently to list installed apps; its container backup request subsequently failed due to a developer tunnel timeout.
- [x] No Watch app update or data deletion attempted; original pending recordings not knowingly disturbed.
- [ ] Save the existing Watch queue before installing matching build 5; retry Watch tunnel only when reachable. Do not reinstall on hope of preserving unsynced recordings.
- [ ] Confirm iPhone/Watch release build pairing and app foreground stability.

## Critical manual acceptance still open
- [ ] iPhone capture button to audible saved recording and original playback (without iPhone Mirroring occupying the microphone).
- [ ] Watch complication tap to saved audio, three distinct notes while offline, reboot with a pending note and eventual transfer after reconnecting.
- [ ] Verify each audio appears once on iPhone, same UUID across retries and Watch queue deletes only after iPhone ACK.
- [ ] Verify cancellation preserves audio, edited transcripts are not overwritten, export succeeds.
- [ ] Measure actual physical tap-to-mic readiness; target ready-state p95 <= 2s remains unverified.
- [ ] Confirm existing user recordings remain present; use disposable new notes for all destructive tests.

Prior release branch records preservation of 33 backed-up files, but this session did not re-export or recompare the personal archive.
