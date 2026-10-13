# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** Physical iPhone 13 now runs What? 0.1.0 (16). User confirmed voice capture returned in both Apple Voice Memos and What? after quitting iPhone Mirroring and rebooting the iPhone (quitting Mirroring alone did not fix it). A fresh post-reboot What? recording was extracted and independently verified on 2026-10-13: 4.500 seconds decoded AAC, peak amplitude ~0.502 and RMS ~0.071 (not digital silence), with a persisted, non-empty 44-character local transcript. This physically validates the iPhone capture → saved original audio → on-device Speech transcription path. Build 16 also refuses to transcribe older empty digital-zero AAC files, without deleting them. iOS simulator test suite passed. Signed build 16 installed on physical iPhone; post-upgrade full app-support byte comparison confirms **17 recordings, 17 original audio files and 8 transcripts** remain unchanged. P4 semantic paraphrase search, WidgetKit real-world launcher and interruption stress acceptance remain pending. Watch build 10 unchanged, App Store release not yet submitted.
**Evidence:** [historical feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Physical offline batch: three recordings queued while disconnected, 3/3 received after opening iPhone app; visible Cancel also confirmed. Watch-to-iPhone automatic background delivery latency remains unverified.
- [x] Fix potential stuck Watch queue after a lost ACK: allow rate-limited retry with original UUID; activate WCSession on Watch background launch. Code validated by automated tests; physical Watch build 5 installed (2026-10-13), manual launch/reboot/automatic background delivery checks pending.
- [x] Physical recovery of one previously stuck Watch note in build 6: queue cleared without opening iPhone What?, note received and playable. The internal transport was not logged.
- [x] Physical follow-up: two consecutive short recordings automatically cleared the Watch queue and appeared on iPhone without manually opening the app (2026-10-13).
- [ ] Finish fallback/ACK-loss stress tests and precise transfer-time instrumentation (physical checklist: [P0 reliability acceptance](docs/P0_RELIABILITY_ACCEPTANCE.md)).
- [x] User confirmed Watch pending queue survives a full offline device reboot (2026-10-13).
- [ ] Complete repeated end-to-end/ACK-loss and fallback testing; do not claim all reliability cases proven from a single success.

## P1 — Voice + text
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [x] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection and retry transcription.
- [x] Implement editable local transcript corrections and new manual text, cancel in-progress on-device recognition, and confirm before overwriting a prior transcript. Repository regression tests pass; delivered to physical iPhone build 7.
- [x] User confirmed editing, Save/Cancel and persistence after reopening on physical iPhone (2026-10-13).
- [ ] Test explicitly cancelling ongoing Speech recognition and preserving existing edited text.

## P2 — iPhone inbox
- [x] Delete with confirmation from iPhone list, including audio/transcript removal and durable tombstones preventing Watch redelivery; shipped to developer build 0.1.0 (3); confirmed on physical iPhone on 2026-10-13.
- [x] User confirmed deletion from the physical iPhone; the system confirmation dialog had no visible Cancel. Replaced with an explicit two-button alert in build 0.1.0 (4).
- [ ] Verify visible Cancel on physical iPhone, cancellation, and no reappearance after late Watch transfer (use a disposable recording only).
- [x] Inbox/Archive switcher, Today/Yesterday/Earlier sections, case-insensitive local transcript/date search, reversible archive with persisted UUID state, and per-recording local audio availability status. Delivered in build 8; physical UI acceptance pending.
- [x] User confirmed physical Inbox grouping, transcript search, Archive and Restore with audio playback (2026-10-13).
- [ ] Confirm archived state persists after restarting What? (covered by storage tests).
- [x] Implement last-reported pending count and timestamp via WatchConnectivity.applicationContext (build 9); queue snapshot stored on iPhone and never presented as current connectivity guarantee. Physical delivery check pending.
- [ ] True transfer progress/real-time connection status remains outside P2; a last-reported snapshot may be delayed by iOS/watchOS.

- [x] Compact iPhone recording controls, eliminating 4-button overflow and word wrapping. Primary Play and text action stay visible; secondary export/retry/archive/delete moved to More menu. Verified on iPhone 13 simulator at normal/Accessibility Medium font sizes and shipped to iPhone build 10 (physical confirmation pending).

- [ ] Physically verify iPhone receives the Watch queue snapshot after opening What? on Apple Watch build 10; validate timestamp and queuing/clearing states. The Xcode device tunnel remains intermittent despite successful in-place installation.\n\n## P3 — Apple Notes / Shortcuts
- [x] Implement local iOS share sheet exports for original audio (.m4a), editable transcript (.txt), or both; staged copies removed after sharing; source files untouched. Build 9, automated tests pass; physical sharing acceptance pending.
- [ ] Test Save to Files / Apple Notes / Shortcuts on physical iPhone; add direct Shortcuts actions only if user demand justifies the extra complexity.

## P4 — Semantic memory
- [x] Local transcript chunking, on-device embedding path (Apple NaturalLanguage), cache invalidation on transcript edit, deletion-safe derived vector storage, hybrid semantic/text retrieval with source attribution. Built for iPhone build 11 with simulator tests; physical model availability and ranking quality not confirmed.
- [x] Dedicated Smart search sheet showing date, matching snippet and match type; opens original audio and full transcript.
- [x] Offline lexical fallback if language assets absent; explicit opt-in to Apple Russian model download, never automatic.
- [ ] Physically test Russian meaning-based paraphrase retrieval, English text search, transcript edits, archived hits, deletion purge, and offline mode.
- [x] Fix rare one-word lookup regression: exact/lexical search for single words instead of accepting misleading mean-pooled semantic matches. Tested with "эдельвейс" and deliberately identical vectors (build 12).
- [x] Add visible count and explicit bulk offline transcription for notes missing saved text; auto-transcribe new Watch notes only if permission already granted, never overwrite existing manual transcripts.
- [x] Add Hide keyboard, keyboard Done accessory and swipe-to-dismiss in Smart search (build 12).
- [ ] Evaluate semantic ranking with 20–30 real Russian notes before asserting production quality.

## P4b — iPhone capture + widgets
- [x] Add native iPhone microphone capture and Stop/Save, discard, local source-of-truth storage, recovery manifests for interrupted writes, and automatic offline transcription if authorized.
- [x] Add iOS WidgetKit launcher in small/medium Home Screen and rectangular Lock Screen sizes; widget deep-link opens app and starts capture once foregrounded (no unsupported background microphone access).
- [x] Physical iPhone acceptance: record → save → AAC has actual voice → saved local transcript. Verified 4.5-second real-audio note, 44-character transcript and preservation across upgrade (2026-10-13).
- [ ] Physical acceptance remaining: record-widget placement/first-open/deep link, repeat capture after long interruption, Watch sync regression following iPhone change.
- [ ] Strengthen long interrupted iPhone recording reliability and audio session interruption tests.
- [x] User-confirmed microphone recovery: stopping iPhone Mirroring alone did not restore the mic; rebooting the iPhone did. Voice Memos and What? then successfully recorded audio (2026-10-13). The same on-device output source is still awaiting byte-level verification, and transcription was not yet independently confirmed.
- [x] Reject silent legacy files before invoking Apple's Speech recognizer, including during batch transcription. No silent file is deleted; audio remains as a diagnostic artifact.
- [ ] Verify new phone voice capture and actual transcript contents with microphone restored; test WidgetKit shortcut to recording physically. When iPhone is connected again, inspect the newest saved note and audio amplitude without changing user data.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
