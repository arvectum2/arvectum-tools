# Arvectum Tools — integration baseline, 2026-10-11

## Purpose

Close the two *development task branches* into canonical `main`. This is a repository integration checkpoint, **not** a declaration that the What? product is finished, or that ChickMark 1.3 has been published. Release approval and hardware-only QA are separate gates.

## Changes merged

- What?: `feature/what` merged via `e746e08`. iOS + watchOS code, Watch complication, UUID envelope, durable Watch-to-iPhone transfer, file repository, ACK/deduplication and tests are now available in `main/what/ios/`.
- ChickMark: `feature/chickmark-multicheck` merged via `2ba838b`. Version 1.3 source, multi-check goals, Watch/widget bridge, migration, tests and localization are now in `main/chickmark/ios/`.
- No new App Store build was uploaded, and integration itself introduced no new storage schema change beyond the feature branches being merged.
- Existing published source tags remain unchanged. Later work must branch from the integrated `main`.

## Validation evidence

- `python3 core/tools/check_architecture.py` passed after both merges.
- What? `xcodebuild ... -scheme WhatIOS ... test` on iOS 27 simulator: passed, including duplicate delivery idempotence test.
- What? `xcodebuild ... -scheme WhatWatch -destination generic/platform=watchOS Simulator ... build`: passed.
- ChickMark `scripts/dependency_audit.py`: passed, five pinned packages verified.
- ChickMark `scripts/localization_audit.py`: passed RU/EN/ES, iOS/Watch/widget/Shortcuts.
- ChickMark iOS 27 simulator: **140 unit tests and 19 UI tests passed (0 failures)**; xcodebuild ended with `** TEST SUCCEEDED **`, exit code 0. Tests include multi-check, migration, persistent storage, Watch/widget bridge, multilingual store screenshots, VoiceOver/accessibility and core CRUD.
- Test output evidence on Mac mini: `/tmp/av-chick-tests.log` (unit/UI), `/tmp/av-what-tests.log` (iPhone), `/tmp/av-what-watch-build.log` (Watch).

## Remaining acceptance gates, not merge blockers

- What?: verify real Apple Watch disconnected capture, queue persistence after reboot, multiple pending voice files, sync/ACK across reconnection, and durable iPhone audio storage on an actual paired device. P1 transcription/inbox/search remain product backlog.
- ChickMark: validate existing *real* 1.2 SwiftData/CloudKit data upgrade, watch/widget delayed sync, notification behavior, advertising privacy and manual App Store 1.3 release state. An App Store submission is not proof of publication.
- Once physical-device evidence is available, make new scoped task branches. Do not resurrect permanent app development branches solely for future work.
