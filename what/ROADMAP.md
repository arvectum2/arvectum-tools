# What? — Product Roadmap

## P0 release blocker — physical one-tap Watch capture (2026-10-16)

- [x] **Regression reproduced by owner on App Store 1.0.1:** Watch-face complication opens the app but does not start recording. Previous `widgetURL(what://capture)` assumption is not sufficient on physical Watch.
- [x] **Source fix for 1.0.2:** Watch starts capture when its scene becomes active (including cold appearance and return from Watch face), without waiting for `.onOpenURL`; keep deep link as a secondary trigger and prevent duplicate starts.
- [x] **Source/simulator checks:** Watch build PASS; physical widget URL is no longer required; simulator cold launch automatically attempted recording (simulator microphone/audio session failed, so real AAC remains unproved); pure launch policy check passed for 5 capture states. iOS regressions: 61 tests (3 skipped), 2 UI tests PASS. Repeated Watch-face and Crown interruption scenarios still require hardware.
- [x] **Isolated physical QA build installed:** separate `ru.arvectum.tools.what.qa` on iPhone 13 and `ru.arvectum.tools.what.qa.watch` on paired physical Apple Watch SE; watch complication extension embedded and signed. Production app/data unmodified. [QA protocol](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Physical one-tap capture (QA build) — user-confirmed 2026-10-16:** tapping the Watch-face QA complication immediately started a recording on Apple Watch SE, no second tap. [Evidence/checklist](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [ ] **Remaining physical release acceptance:** confirm audio is saved and playable on iPhone exactly once, repeat after Stop and Digital Crown, denied mic permission, offline recording/reconnect and reboot; no shipping before these critical regressions pass.
- [ ] **RELEASE BLOCKED**: do not upload, submit, or publish 1.0.2 or any later version until physical one-tap acceptance above passes and is recorded with evidence. Signed IPA / App Store validation / simulator tests alone do not satisfy this gate.

## A5 — isolated next-patch candidate (2026-10-15)

- [x] Created isolated A5 release source candidate **1.0.2 (7)** from main. [Release gate](docs/A5_RELEASE_CANDIDATE_1_0_2_2026-10-15.md).
- [ ] Signing, full independent CI, physical QA and Apple submission remain separate gates; source candidate is **not** an App Store upload or approval.


## Active release checkpoint — 2026-10-15

**Brand:** Ухват (RU) / UhWhat? (international), code directory what/.
**Public 1.0.0 (5):** READY_FOR_SALE independently rechecked in App Store Connect API 2026-10-15
(App ID 6822476399). **Submitted 1.0.1 (6):** Waiting for Review, recorded
2026-10-15. Exact details and release evidence belong to the
[1.0.1 release-branch roadmap](https://github.com/arvectum2/arvectum-tools/blob/release/what-1.0.1/what/ROADMAP.md);
release-proven iOS/watchOS source was **selectively integrated into main** 2026-10-15 via [PR #67](https://github.com/arvectum2/arvectum-tools/pull/67) (`e129efc`); private RuWordNet corpora and research pipeline were not copied.

**North star:** Catch the thought before it disappears. Reliable immediate
capture, durable original audio and Watch-to-iPhone delivery have priority.

- [x] iPhone capture-first UI, Watch recording, local Inbox/Archive,
  transcription, searchable text and sharing shipped in 1.0.0 (5).
- [x] Release 1.0.1 (6) source fixes complication to launch Watch recording
  in one tap, uses branded Watch glyph and saves active recording upon
  app backgrounding. Signed IPA and simulator tests passed, submitted.
- [x] A2 source-level queue and receiver hardening: atomic on-disk enqueue/ACK/recovery before in-memory mutations; iPhone rejects unreadable/corrupt AAC before ACK. 7/7 focused tests PASS; complete suite 61 executed, 0 failures, 3 skipped. Both Watch and iOS builds and GitHub PR CI pass. [PR #70](https://github.com/arvectum2/arvectum-tools/pull/70) merged into main at `2f9239f`. [A2 QA](docs/A2_CAPTURE_DELIVERY_QA_2026-10-15.md). Changes are **not** in Apple's submitted 1.0.1 (6) binary.
- [ ] Physical proof for 1.0.1: one Watch complication tap → audio,
  Digital Crown/background → saved playable audio on iPhone exactly once,
  including offline / ACK / reboot and duplicate-delivery scenarios.
- [ ] Measure real capture latency and playback survival; sudden power loss
  or force termination may leave unfinished AAC unplayable.
- [x] Shippable 1.0.1 source, widgets and tests integrated into main with
  source provenance, without the private RuWordNet corpus. No user-device
  records were modified in this merge; physical regression remains open.
- [ ] Keep semantic Ask Memory research out of release-critical P0.

**Updated:** 2026-10-15. **Shared Core:** [Core](../core/ROADMAP.md).
**Growth:** [Growth](../growth/ROADMAP.md).
**Note:** P0–P5 checklist below retains historic and research milestones.
The current main now includes the release source; unchecked device/research
acceptance cases must not be confused with absent capture, Inbox, transcript
or export features.

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Automated A2 queue crash/write-failure/offline-batch and receiver AAC integrity regression tests added; no real Watch devices tested yet.
- [ ] Complete remaining disconnected-device, multiple-pending-recording and device-reboot acceptance cases on a physical paired Watch and iPhone.
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

## P6 — Follow-up reminders for captured notes (post-1.0 backlog)
- [ ] **P1 · Revisit a note later:** after saving a new voice/text note (including one delivered from Watch), offer one-tap "Напомнить" with +1 / +2 / +3 hours from the time it becomes available on iPhone; allow per-note override, reschedule, cancel and mark reviewed. Keep recording/Watch transfer fast and unaffected by notification scheduling. No default reminders unless explicitly enabled by the user.
- [ ] **P1 · Optional auto-follow-up:** opt-in rule "new note → remind after 1/2/3 hours", with quiet-hour/notification-permission handling, duplicate protection by stable recording UUID and no reminders for deleted notes. Add a low-noise daily review/digest only as a subsequent option if individual alerts prove noisy.
- [ ] **P1 · ChickMark handoff:** optional local-only integration to create a distinct "Review this note" follow-up in ChickMark, **not** a recurring habit or an automatic habit completion. Carry the saved/edited transcription as the follow-up's full text, recording UUID, creation time and a deep link back to the original audio in Ухват. The notification itself defaults to privacy-safe generic text; showing transcription on the lock screen is a separate explicit choice.
- [ ] **P1 · Integration feasibility spike:** validate app-to-app transfer for the two signed iOS apps (App Group/shared container versus App Intents/Shortcuts/openURL), actual background/notification limits, permissions and behavior when ChickMark is not installed. Never require cloud, network or an always-running companion app. If unavailable, use Ухват's own local notification fallback.
- [ ] **Acceptance:** test Watch offline/delayed arrival, transcription still pending, edited transcription after handoff, app reinstall/upgrade, duplicate Watch deliveries, deleted/archived notes, ChickMark unavailable, denied notification permission, timezone/quiet hours, and tap-through to the correct audio. Do not silently copy private transcripts to shared or external destinations without opt-in.

## Later
- [ ] Optional clustering and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
