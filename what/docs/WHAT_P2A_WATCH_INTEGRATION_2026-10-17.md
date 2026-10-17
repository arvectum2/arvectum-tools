# UhWhat? P2a and Watch/Speech integration checkpoint — 2026-10-17

## Provenance / isolation

- New standalone worktree: /Volumes/ArvectumSSD/Arvectum/worktrees/what-multimodal-watch-integration-20261017
- Branch integration/what-multimodal-watch-20261017. Neither the original feature nor the physical QA11 release branch was replaced.
- Merge parents: feature/what-multimodal-20261016 (39c6175) and verified Watch-fix+Speech branch (42b2462). Initial merge commit 89e1162.
- The only two textual conflicts were RecordingLibraryView (retained both note-type filter and linked RU/EN locale Picker) and Xcode project (regenerated from combined XcodeGen spec, preserving iPad device family 1,2).
- Watch durable UUIDs/ACK and original audio storage are not intentionally migrated; new user text/video uses the additive local-notes ledger.

## Tests and diagnosis

- iOS Simulator compilation succeeded on Xcode 27.1.
- Full integrated final v2 simulator execution: **92 unit/integration tests, 3 skipped, 0 failures; 9 UI tests, 1 iPad-specific skipped, 0 failures**. Log: builds/what-multimodal-watch-integrated-20261017/integrated-full-v2.log (on Mac mini ArvectumSSD).
- A first UI test failure came from a mismatched accessibility query: the video sheet WAS open after a long press, with NavigationBar **identifier** Видеозаметка, preview, Stop and camera switch, but the test looked only at the navigation bar label. We inspected the on-simulator accessibility hierarchy, corrected the test query, and verified the targeted long-press test passed. A separate transient test clean-up issue came from trying to tap a video-sheet cancel control after the simulator had asynchronously dismissed it; final test terminates only the synthetic test app to avoid intermittent camera hardware states. No gesture implementation changed.
- Pure Watch launch-policy smoke and branded complication smoke tests passed with byte-identical Watch icon image and equivalent vector contours.
- The full v2 XCTest suites reported zero failures. At the time of writing, xcodebuild still had an active cleanup process and its xcresult bundle lacked Info.plist; **clean terminal exit/final xcresult integrity must be checked independently**. This is not server-side validation or physical camera acceptance.
- Warnings remain in VideoSegmentComposer: capture of non-Sendable AVAssetExportSession in a @Sendable callback. Simulator compilation passes; track before declaring video release ready.

## Open gates

- [ ] Full xcodebuild process exit and complete result bundle.
- [ ] iPad simulator or physical iPad UI acceptance; Mac mini's current simulator list shows iPhone Duo only.
- [ ] Provision separately signed multimodal QA bundle with unique ID; do not install new integrated production-ID binary over established QA or user data.
- [ ] Real-device text note creation, autosave, search, archive and restart; ensure legacy Watch voice notes survive.
- [ ] Real device short tap immediately starts audio, long press starts video without an unintended audio note.
- [ ] Back/front camera capture and audio continuity, physical interruptions, recovery, Stop/Discard, large files and permission failures.
- [ ] Watch offline transfer/ACK, audio/reboot automatic recovery after integration, and app privacy checks.
- [ ] Release scope, final signed archive, upload approval — NONE granted.

## Separate Speech QA12

The fixed Speech cancellation/retry race source is built as a **signed iPhone QA 1.0.2 (12)** on ArvectumSSD. At installation preparation, CoreDevice identified iPhone Nikita as unavailable; backup copy failed, therefore **QA12 was not installed**. Stable QA11 app and existing notes are untouched. Reconnect/unlock device, make a backup, then verify all source-file hashes before attempting in-place update. Apple Watch QA was not changed.
