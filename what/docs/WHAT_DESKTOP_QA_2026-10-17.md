# What? / Ухват — desktop-only multimodal checkpoint (2026-10-17)

## Scope and provenance

- Independent ArvectumSSD worktree: `worktrees/what-desktop-qa-20261017`, branch `feature/what-desktop-qa-20261017`.
- Base `integration/what-multimodal-watch-20261017` at `82e32a9`; neither existing production/QA release nor a paired device was touched.
- Test logs and derived data are stored under the **local, untracked** `.qa/` folder on ArvectumSSD, not in the repository or on user devices.

## Code and verification

- `VideoSegmentComposer.compose` uses `AVAssetExportSession.export(to:as:)` asynchronously for iOS 18+; on iOS 17 the existing completion-handler export is retained behind a narrowly scoped immutable one-shot session wrapper. This keeps iOS 17 compatibility while removing unsafe direct captures in the callback. Existing crash-safe staging and journal/ACK paths are unchanged.
- Changed two local property-list encoder variables from `var` to `let`; serialization format is unchanged.
- Clean iOS Simulator **BUILD SUCCEEDED, exit 0**, Xcode 27.1. No `VideoSegmentComposer.swift` Sendability warning in the updated build. A separate watchOS Simulator **WhatWatch BUILD SUCCEEDED, exit 0**, confirming the shared PropertyListEncoder change compiles for Watch too; this is not physical Watch acceptance.
- On the updated composer, **14 synthetic XCTest cases passed with zero failures**: 5 `VideoCameraSwitchTests`, 9 `VideoCaptureRecoveryTests`. Checks exercise actual video/audio track composition, one-clip handling, repair/idempotent recovery, and preserving the legacy audio ledger.
- Before code changes, one targeted iPhone Duo Simulator UI test `testLongPressGoesToVideoNotAudio` passed: long press routes to video. No UI gesture implementation was changed.

## Environment limitations / explicit unfinished gates

1. **Test finalization:** both focused simulator runs reported all test cases passing but `xcodebuild` did not immediately exit or complete its `.xcresult` bundle. The iOS 27.1 simulator build `24A94232` logged `invalidDigitCount(94232)`. Case-level PASS is not equivalent to complete `xcodebuild TEST SUCCEEDED`; further Xcode/runtime repair may be needed. Build-only execution exited successfully.
2. **iPad:** although `project.yml` and `What.xcodeproj` both target iOS device family `1,2` (iPhone/iPad), iPad Air 11-inch (M4) creation returned CoreSimulator error 403 (“Incompatible device”) and iPad Pro 13-inch (M5) reported no compatible installed runtime. The single installed iOS 27.1 runtime currently exposes an iPhone Duo simulator. Thus iPad portrait/landscape/Split View QA remains open; do not label it passed.
3. **Physical-device gating:** iOS 17 fallback export, back/front camera switch during a real recording, audio continuity, hardware interruptions, low storage, actual permission dialogs and Watch ACK integration were not retested. No new .ipa or App Store build was uploaded or installed.

## Next actions when environment or devices become available

- With a compatible iPad simulator/runtime, exercise existing `testIPadLandscapePreservesCaptureTextEditorAndLibrary` plus portrait and compact windows; then confirm physical layout.
- With iPhone/Watch access, back up user/QA data before installing an isolated P2a bundle; test video/audio, camera switch, text autosave, Watch one-tap/ACK and interrupt/recovery cases. Do not overwrite an existing signed app by accident.
- Investigate Xcode's `invalidDigitCount` and result-bundle finalization separately from app crashes. Keep multimodal release and production IPA isolated until physical acceptance and explicit release authorization.

## Follow-up simulator diagnosis (2026-10-17)

- Confirmed Xcode 27.1 / build 27A9275, iOS 27.1 / runtime build 24A94232, iPhone Duo simulator available, 43 registered iPad device types.
- Creating iPad Air 11-inch M4, iPad Pro 11-inch M4, iPad mini A17 Pro, and iPad 10th generation against this runtime consistently fails with CoreSimulator 403 `Incompatible device`. This is a runtime/device compatibility failure, not evidence of a UI code failure.
- `simctl runtime list -v` reports iOS 27.1 as `Ready`, but signature state `Unknown`; watchOS 27.0 is `Verified`. Signature verification was initiated; no destructive runtime removal, simulator reset, or reinstall was performed. Further verification or compatible runtime installation remains open.

## Second simulator investigation

- iPhone Duo (iPhone19,4) boots successfully using the installed iOS 27.1 runtime.
- SDK build and installed runtime build both equal `24A94232`; `simctl runtime match list -v` selects that runtime normally.
- iPad Pro 11-inch M5 also fails with CoreSimulator 403; automatic runtime selection reports `Could not find an available runtime for device type` even though iOS 27.1 is listed Ready.
- This establishes an iPad runtime compatibility/registration issue distinct from a total CoreSimulator failure. The iOS runtime's signature still reports Unknown. A signature verification command was attempted but no conclusive successful verification was returned.
- Existing iPhone Duo simulator and installed runtime were preserved; no destructive reset or reinstall was attempted. iPad simulator acceptance remains BLOCKED pending a compatible runtime or Apple tooling fix.

## Root cause confirmed: device-restricted runtime

`xcrun simctl list runtimes -j` exposes only one `supportedDeviceTypes` entry for iOS 27.1: `iPhone Duo`. Inspecting `Contents/Resources/profile.plist` of the installed iOS 27.1 runtime reveals `restrictedToDeviceTypes = [com.apple.CoreSimulator.SimDeviceType.V68]`. This is the direct cause of CoreSimulator 403 for every iPad, despite iPad types being installed separately. Xcode's SDK and runtime builds match; modifying the app cannot solve it. A standard iOS simulator runtime download was started with `xcodebuild -downloadPlatform iOS -exportPath /Volumes/ArvectumSSD/Arvectum/DevTools/SimulatorRuntimeDownloads -architectureVariant arm64`; install/verification and iPad acceptance are pending download completion. Do not modify the signed/restricted runtime profile in place or delete the existing working iPhone Duo device.
