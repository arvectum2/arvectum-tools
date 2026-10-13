# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** As of 2026-10-13, build 0.1.0 (7) is installed on physical iPhone 13 and adds local transcript editing, manual text entry, explicit transcription cancellation, and overwrite confirmation. Physical test confirmation for the new UI is pending. The Apple Watch app remains on working build 6. All twelve existing recordings/audio files and transcription data were checked byte-identical against a backup after installing iPhone build 7. Watch-to-iPhone delivery works with the iPhone app closed; the user confirmed the prior reboot-recovery test plus **two new consecutive short recordings delivered immediately, with Watch queue clearing automatically both times**. Reliability under all fallback/ACK-loss scenarios remains a separate acceptance task. Not released to App Store.
**Evidence:** [historical feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Physical offline batch: three recordings queued while disconnected, 3/3 received after opening iPhone app; visible Cancel also confirmed. Watch-to-iPhone automatic background delivery latency remains unverified.
- [x] Fix potential stuck Watch queue after a lost ACK: allow rate-limited retry with original UUID; activate WCSession on Watch background launch. Code validated by automated tests; physical Watch build 5 installed (2026-10-13), manual launch/reboot/automatic background delivery checks pending.
- [x] Physical recovery of one previously stuck Watch note in build 6: queue cleared without opening iPhone What?, note received and playable. The internal transport was not logged.
- [x] Physical follow-up: two consecutive short recordings automatically cleared the Watch queue and appeared on iPhone without manually opening the app (2026-10-13).\n- [ ] Finish fallback/ACK-loss stress tests and precise transfer-time instrumentation (physical checklist: [P0 reliability acceptance](docs/P0_RELIABILITY_ACCEPTANCE.md)).
- [x] User confirmed Watch pending queue survives a full offline device reboot (2026-10-13).
- [ ] Complete repeated end-to-end/ACK-loss and fallback testing; do not claim all reliability cases proven from a single success.

## P1 — Voice + text
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [x] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection and retry transcription.
- [x] Implement editable local transcript corrections and new manual text, cancel in-progress on-device recognition, and confirm before overwriting a prior transcript. Repository regression tests pass; delivered to physical iPhone build 7.\n- [ ] Physically verify editing/save/cancel/persistence after reopening and cancellation during recognition.

## P2 — iPhone inbox
- [x] Delete with confirmation from iPhone list, including audio/transcript removal and durable tombstones preventing Watch redelivery; shipped to developer build 0.1.0 (3); confirmed on physical iPhone on 2026-10-13.
- [x] User confirmed deletion from the physical iPhone; the system confirmation dialog had no visible Cancel. Replaced with an explicit two-button alert in build 0.1.0 (4).
- [ ] Verify visible Cancel on physical iPhone, cancellation, and no reappearance after late Watch transfer (use a disposable recording only).
- [ ] Today/Yesterday grouping, search, archive and sync status; playback available in initial list.

## P3 — Apple Notes / Shortcuts
- [ ] Export and optional system integration without depending on cloud.

## P4 — Semantic memory
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
