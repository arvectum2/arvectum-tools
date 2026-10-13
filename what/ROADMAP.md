# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** What? iPhone build 0.1.0 (15) implements source-input diagnosis and a strict real-audio gate after physical build 14 created a 6.600000-second, all-zero AAC file despite receiving a full stream of AVAudioEngine input buffers. Confirmed with Apple decoding that the 6.6-second file's RMS/peak/nonzero frame counts were all zero, while older spoken recordings had expected nonzero amplitudes. Fix: explicitly prefer built-in iPhone microphone when available, show the actual selected iOS input port on capture screen, and reject silent PCM or decoded AAC before recording enters Inbox or triggers transcription. Staged failed recordings are retained; crash recovery validates audio duration and actual signal rather than importing silence. The build compiles for simulator and test target; native Swift regression checks confirmed physical silent AAC rejected, good speech AAC accepted, synthetic buffers encoded/validated. Physical iPhone build 15 installed, with full-byte verification of 16 recordings, 16 original M4A files, 7 transcripts and all staged files. Actual microphone acceptance pending. Existing 16 recorded notes and 7 transcripts retained. Other audio/Watch pipelines unchanged; no App Store release yet.
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
- [ ] Physical acceptance: record/save/reopen/playback/transcribe; record widget setup, first-open confirmation, launch into capture, and unchanged Watch sync.
- [ ] Strengthen long interrupted iPhone recording reliability and audio session interruption tests.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
