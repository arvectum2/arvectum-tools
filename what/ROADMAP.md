# What? — Product Roadmap

## Active release checkpoint — 2026-10-14
**Brand:** Ухват (RU) / UhWhat? (international); What? was the working name and what/ remains the product directory. **Apple:** 1.0.0 build 5, App ID 6822476399, under review (owner-confirmed 2026-10-14); not yet published. The submitted changes live on [release/what-1.0.0](https://github.com/arvectum2/arvectum-tools/blob/release/what-1.0.0/what/ROADMAP.md), commit ebe3d06, not yet integrated into main.

**North star: Catch the thought before it disappears. Analyze it later.** Native one-tap Watch and iPhone capture, original-audio durability and reliable transfer outrank advanced AI search.
- [x] Release branch implements iPhone capture-first home, Inbox/Archive, local transcripts, search/export, widget, RU/EN branding; physical upgrade preserved all 33 backed-up files.
- [x] Watch queue survived offline reboot and automatic short-note transfer was observed on physical devices; UUID/retry/ACK deduplication implemented.
- [ ] Repeat physical ACK-loss, offline batch, reboot and background delivery acceptance; prove original audio remains playable and capture meets target <=2s ready-state p95 (unverified).
- [ ] Validate exact build 5 iPhone+Watch end-to-end capture and follow Apple's review decision. Physical iPhone has build 5 but Apple Watch still runs 1.0.0 (3); bring Watch to matching build only after safeguarding its existing transfer queue. [Physical QA evidence](docs/PHYSICAL_QA_2026-10-14.md).
- [ ] Exclude experimental RuWordNet-derived graph and model research from shipping app; private derived corpus has unresolved commercial distribution rights.
- [ ] Integrate reviewed, shippable release work into main without losing local recordings or source/build provenance.

The P0–P5 baseline below reflects older main; the release branch contains later implementation work. Do not treat speculative Ask Memory models as a 1.0 release gate.


**Updated:** 2026-10-14
**Status:** P0 + initial iPhone playback/on-device transcription implementation on 2026-10-11; **not released to App Store**. Local developer build installed on paired physical iPhone after backing up all 7 existing recordings; manual playback and transcription acceptance still open.
**Evidence:** [historical feature-branch roadmap snapshot](docs/history/ROADMAP-feature-what-2026-10-11.md).
**Shared principles:** [Core](../core/CORE_PRINCIPLES.md); **Growth:** [Growth](../growth/ROADMAP.md).

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [ ] Complete remaining disconnected-device, multiple-pending-recording and device-reboot acceptance cases.
- [ ] Reconcile final physical test evidence and prove no recorded thought is lost.

## P1 — Voice + text
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [ ] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection, retry/cancel controls and transcript corrections.

## P2 — iPhone inbox
- [ ] Today/Yesterday grouping, search, archive/delete and sync status; playback available in initial list.

## P3 — Apple Notes / Shortcuts
- [ ] Export and optional system integration without depending on cloud.

## P4 — Semantic memory
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
