# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** Development-only build 0.1.0 (4) installed on physical iPhone 13 on 2026-10-13; not released to App Store. User verified actual deletion in build 3. Build 4 replaces the dismissible action sheet with a two-button alert (Cancel/Delete permanently), awaiting visual confirmation. Before build 4, six remaining audio recordings and transcripts were backed up; all app data was verified byte-identical after installation.
**Evidence:** [historical feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [ ] Complete remaining disconnected-device, multiple-pending-recording and device-reboot acceptance cases (physical checklist: [P0 reliability acceptance](docs/P0_RELIABILITY_ACCEPTANCE.md)).
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
