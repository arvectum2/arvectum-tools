# What? — Product Roadmap

**Updated:** 2026-10-11
**Status:** active development in `feature/what`; not released.
**Evidence:** [feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in feature branch).
- [x] Watch-face entry point and immediate recording UX (feature-branch implementation).
- [ ] Complete remaining disconnected-device, multiple-pending-recording and device-reboot acceptance cases.
- [ ] Reconcile final physical test evidence and prove no recorded thought is lost.

## P1 — Voice + text
- [ ] Preserve original audio as source of truth.
- [ ] Add retryable on-device transcription, playback, transcript corrections and timestamps.

## P2 — iPhone inbox
- [ ] Today/Yesterday views, playback, search, archive/delete and sync status.

## P3 — Apple Notes / Shortcuts
- [ ] Export and optional system integration without depending on cloud.

## P4 — Semantic memory
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
