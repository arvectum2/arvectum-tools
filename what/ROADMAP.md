# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** Build 0.1.0 (6) installed on physical iPhone 13 and Apple Watch SE on 2026-10-13; direct phone repository verification confirmed all nine earlier notes were byte-identical after updating iPhone. Physical fast-path delivery test pending: add immediate watchOS-to-iOS transfer for short audio using WatchConnectivity.sendMessageData, with a durable-store reply and existing background transferFile fallback. Physical Watch/phone build 5 previously installed; offline batch (3/3) and reboot queue persistence passed. The next disposable recording did not background-deliver within the observation window even with Watch UI open: physical test blocker until build 6 fast-path is tested. Not released to App Store.
**Evidence:** [historical feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Physical offline batch: three recordings queued while disconnected, 3/3 received after opening iPhone app; visible Cancel also confirmed. Watch-to-iPhone automatic background delivery latency remains unverified.
- [x] Fix potential stuck Watch queue after a lost ACK: allow rate-limited retry with original UUID; activate WCSession on Watch background launch. Code validated by automated tests; physical Watch build 5 installed (2026-10-13), manual launch/reboot/automatic background delivery checks pending.
- [ ] Verify immediate short-audio delivery using live WatchConnectivity in build 6 (phone app closed), and background fallback when live messaging is unreachable; complete deferred background delivery checks (physical checklist: [P0 reliability acceptance](docs/P0_RELIABILITY_ACCEPTANCE.md)).
- [x] User confirmed Watch pending queue survives a full offline device reboot (2026-10-13).
- [ ] Reconcile final physical test evidence and prove no recorded thought is lost.

## P1 — Voice + text
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [x] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection and retry transcription.
- [ ] Editable transcript corrections and explicit transcription cancellation.

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
