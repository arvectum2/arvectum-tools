# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** As of 2026-10-13, What? 0.1.0 (10) is installed on physical iPhone 13 with a compact action row that keeps Play/Stop and Transcribe/Edit text readable and moves export/retranscription/archive/delete into an accessible overflow menu. Verified with screenshots from an iPhone 13 simulator at both standard and Accessibility Medium text sizes; long labels never wrap within a button. iOS simulator tests pass, physical compact UI confirmed more convenient by the user. Export was confirmed successful by the user in build 9; export internals are unchanged in build 10. Original 12 recordings, 12 .m4a files and 5 transcripts are byte-identical before/after upgrade. Companion Watch build 10 was successfully installed in-place on the physical Apple Watch SE via Xcode developer tunnel on 2026-10-13 (devicectl install returned success), but the tunnel disconnected again before an independent installed-version query. Watch queue status display and fast-transfer regression on build 10 await user confirmation. App Store submission pending.
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
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
