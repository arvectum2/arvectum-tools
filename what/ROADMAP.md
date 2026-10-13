# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** Build 0.1.0 (5) installed on physical iPhone 13 on 2026-10-13 with all 9 recordings and associated audio preserved byte-identically after the update; Watch app build 0.1.0 (5) installed on physical Apple Watch SE (watchOS 26.6) after recovering the developer tunnel; command-line launch timed out, so actual on-watch launch and recording remain to be checked. Build 5 includes ACK retry hardening and early WatchConnectivity activation, and physical offline batch results from 2026-10-13. Build 4 was previously installed on physical iPhone 13; the user confirmed the two-button Cancel dialog and 3/3 Watch recordings delivered on opening the iPhone app. Automatic background delivery without opening the iPhone is still unverified (Apple schedules background file transfers opportunistically). Not released to App Store.
**Evidence:** [historical feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Physical offline batch: three recordings queued while disconnected, 3/3 received after opening iPhone app; visible Cancel also confirmed. Watch-to-iPhone automatic background delivery latency remains unverified.
- [x] Fix potential stuck Watch queue after a lost ACK: allow rate-limited retry with original UUID; activate WCSession on Watch background launch. Code validated by automated tests; physical Watch build 5 installed (2026-10-13), manual launch/reboot/automatic background delivery checks pending.
- [ ] Complete remaining device-reboot acceptance and deferred background delivery checks (physical checklist: [P0 reliability acceptance](docs/P0_RELIABILITY_ACCEPTANCE.md)).
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
