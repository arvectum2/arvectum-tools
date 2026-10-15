# what — A5 isolated release candidate 1.0.2 (7)

**State as of 2026-10-15: SOURCE-CANDIDATE ONLY. Not uploaded, not submitted, not public.**
**ASC external source:** authenticated read-only lookup on 2026-10-15: public 1.0.0 (5); 1.0.1 (6) WAITING_FOR_REVIEW.
**Bundle:** `ru.arvectum.tools.what`. **Proposed** version/build: `1.0.2 (7)`.
**Source base:** `origin/main@657ce0d6bcce78cf35e07135ef5871da8e07c0ff`, plus ONLY the `what/ios/project.yml` version/build changes in this isolated release branch and this release document. No old release source is blindly merged.
**Release branch:** `release/what-1.0.2-build7-a5-20261015`.

## Included changes — source-only since last submitted build

PR #70: Watch durable transactional UUID queue (enqueue, ACK, crash recovery) and decodable AAC/duration verification on iPhone. Watch complication one-tap feature belongs to previously submitted 1.0.1, not newly invented here. No RuWordNet private corpus.

## App Store What’s New — draft, not posted

**ru-RU:** Повысили надёжность доставки голосовых заметок с Apple Watch. Повреждённые аудиофайлы не подтверждаются как доставленные и остаются в очереди.

**en-US:** Improved reliable delivery of Apple Watch voice notes. Damaged audio stays queued for another transfer instead of being acknowledged.

## Pre-submission gates

- [x] Isolated branch from frozen `657ce0d6bcce` base; no automatic merge to `main`.
- [x] Reserved unique marketing/build number; cross-target version consistency is enforced by `project.yml`. Managed signing export settings: [ExportOptions-A5-AppStore.plist](ExportOptions-A5-AppStore.plist).
- [ ] Clean generated Xcode project builds on generic iOS Simulator (and watchOS if applicable).
- [ ] Full app unit/UI regression and clean GitHub Actions release-branch checks.
- [x] **App Store-exported IPA** `WhatIOS.ipa` with SHA-256 `978e49a845db6311e81ba9d0d4bb2be18d9dd9a55ef9fdd84310b1c56db0fce5`; Xcode archive SUCCEEDED, export SUCCEEDED, team VML75VY94V. Exported IPA has production Store profiles, disabled `get-task-allow`, and matching version/build in **4/4 bundles**. Xcode may use an Apple Development profile in the intermediate `.xcarchive` for Watch/widget apps; **the exported IPA is independently re-signed**. [Machine-readable receipt](A5_SIGNED_IPA_RECEIPT_1_0_2_2026-10-15.json).
- [x] Extracted IPA validated: bundle version/build, App Store profile entitlements, `codesign --verify --strict` for all bundles; no RuWordNet-named assets bundled. Physical application behavior and exact signed archive reproducibility remain independent gates.
- [ ] **Physical/external:** Await decision for 1.0.1 (6); physical paired Watch/iPhone confirmation of complication one tap, Digital Crown background completion, offline/reconnect 3 recordings and duplicate-ACK cases. Sudden power failure before AAC finalization cannot be claimed lossless.
- [ ] **Apple:** actual new App Store version + build association, review notes and required locales only after preceding gates pass. No upload or submission in A5 draft phase.

## Existing QA evidence
- what/docs/A2_CAPTURE_DELIVERY_QA_2026-10-15.md
- Verified external version state is separate from the submitted build, local code tests and simulated user flows.
- Never use another app's signed IPA or release profile. No user data deleted, reinstalled, replaced, uploaded or reset in preparing this candidate.
