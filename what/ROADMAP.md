# What? — Product Roadmap

**Updated:** 2026-10-13
**Status:** iPhone currently runs What? 0.1.0 (18). Physical Ask memory feedback identified that semantic retrieval FAILED all three one-word conceptual probes: "цветок" should find "эдельвейс", "журнал" should find "дневник", "красота" should find "эстетика". Diagnosis: LocalSemanticSearch intentionally disabled *all* single-word semantic queries, even in Ask memory; GroundedMemoryAnswer further removed many semantic hits with a second overly strict score gate. Build 19 corrects Ask memory to use semantic vectors even for single-word queries, compares query vectors against both passage and locally encoded contextual term vectors, displays explicit model-availability status including an optional user-consented Russian-model installation action, and retains strict one-word lexical matching in Find notes. The result UI emphasizes candidate excerpts and source-verification rather than fabricated answers. Full iOS simulator unit suite passed (48 tests). Build 19 signed, installed on physical iPhone 13, and 17 recording records, 17 original audio files, 15 transcripts and all other preinstall app-support files remained byte-identical. Real iPhone Russian contextual model similarity benchmark and user acceptance still pending; dedicated Xcode physical model probe was blocked by the locked iPhone and cancelled before affecting data. Source audio, transcripts and original index remain unchanged. No App Store submission.
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

- [x] Compact iPhone recording controls, eliminating 4-button overflow and word wrapping. Primary Play and text action stay visible; secondary export/retry/archive/delete moved to More menu. Verified in simulator and user confirmed the new layout is more convenient on physical iPhone (2026-10-13).

- [x] User confirmed last-reported Watch queue status in the iPhone UI after Watch build 10 installation. Normal Watch-to-iPhone delivery is so quick that the queue usually reads 0; the technical line is now hidden in Sync diagnostics (2026-10-13).
- [ ] Validate pending-count transitions by disconnecting devices and reconnecting; do not assume the visible zero proves fully live connectivity.\n\n## P3 — Apple Notes / Shortcuts
- [x] Implement local iOS share sheet exports for original audio (.m4a), editable transcript (.txt), or both; staged copies removed after sharing; source files untouched. Build 9, automated tests pass; physical sharing acceptance pending.
- [x] User confirmed original share-sheet export works on physical iPhone. Exact external destinations (Files / Notes / Shortcuts) not yet independently enumerated (2026-10-13).
- [ ] Validate individual export destinations as needed; add direct Shortcuts actions only if user demand justifies the complexity.

## P4 — Semantic memory
- [x] Local transcript chunking, on-device embedding path (Apple NaturalLanguage), cache invalidation on transcript edit, deletion-safe derived vector storage, hybrid semantic/text retrieval with source attribution. Built for iPhone build 11 with simulator tests; physical model availability and ranking quality not confirmed.
- [x] Dedicated Smart search sheet showing date, matching snippet and match type; opens original audio and full transcript.
- [x] Offline lexical fallback if language assets absent; explicit opt-in to Apple Russian model download, never automatic.
- [ ] Physically test Russian meaning-based paraphrase retrieval, English text search, transcript edits, archived hits, deletion purge, and offline mode.
- [x] Fix rare one-word lookup regression: exact/lexical search for single words instead of accepting misleading mean-pooled semantic matches. Tested with "эдельвейс" and deliberately identical vectors (build 12).
- [x] Add visible count and explicit bulk offline transcription for notes missing saved text; auto-transcribe new Watch notes only if permission already granted, never overwrite existing manual transcripts.
- [x] Add Hide keyboard, keyboard Done accessory and swipe-to-dismiss in Smart search (build 12).
- [ ] Evaluate semantic ranking with 20–30 real Russian notes before asserting production quality.
- [x] Build 17: strict token-boundary exact/prefix search for one-word queries; e.g. "тест" matches "тест", "тестовое" but not "текст". No approximate-spelling matches or one-word semantic guesses.
- [x] Build 17: searchable derived aliases for recognized Russian counting shorthand "раз 2345": "два", "три", "четыре", "пять" match "раз 2345" (lower-ranked Number match); standalone number 2345, years and identifiers do not spuriously match number words. Original ASR text is untouched.
- [x] Regression tests for both user-provided cases plus end-to-end LocalSemanticSearch with a deliberately misleading vectorizer passed in iOS simulator.
- [x] Independently validated search matcher on a backup of real iPhone transcripts: query "два" matched both notes containing "раз 2345"; a text-only note did not match "тест"; tests do not expose note contents.
- [x] User confirmed both real physical iPhone UI queries work correctly on build 17 (2026-10-13). New normalization issues should be fixed with evidence, not overly broad fuzzy matching.
- [x] Build 18 separates exact/number matches from semantic-only results in the Find notes UI, so source relevance is visible at a glance.
- [ ] Evaluate semantic ranking with 20–30 genuine user-confirmed Russian paraphrases on the physical iPhone. Russian NLContextualEmbedding assets are not installed on Mac mini, so benchmark results from that Mac would not reflect the actual iPhone model.

## P4b — iPhone capture + widgets
- [x] Add native iPhone microphone capture and Stop/Save, discard, local source-of-truth storage, recovery manifests for interrupted writes, and automatic offline transcription if authorized.
- [x] Add iOS WidgetKit launcher in small/medium Home Screen and rectangular Lock Screen sizes; widget deep-link opens app and starts capture once foregrounded (no unsupported background microphone access).
- [x] Physical iPhone acceptance: record → save → AAC has actual voice → saved local transcript. Verified 4.5-second real-audio note, 44-character transcript and preservation across upgrade (2026-10-13).
- [x] User confirmed on physical iPhone: What? iOS Home Screen widget adds successfully and tapping it opens the in-app microphone capture screen directly (2026-10-13). This validates widget placement and deep-link routing, not audio capture quality from the widget.
- [ ] Physical acceptance remaining: complete a voiced recording launched specifically from the widget with a clean iOS microphone route, then confirm saved audio and automatic transcription; repeat capture after long interruptions and Watch sync regression following iPhone change.
- [ ] Strengthen long interrupted iPhone recording reliability and audio session interruption tests.
- [x] User-confirmed microphone recovery: stopping iPhone Mirroring alone did not restore the mic; rebooting the iPhone did. Voice Memos and What? then successfully recorded audio (2026-10-13). The same on-device output source is still awaiting byte-level verification, and transcription was not yet independently confirmed.
- [x] Reject silent legacy files before invoking Apple's Speech recognizer, including during batch transcription. No silent file is deleted; audio remains as a diagnostic artifact.
- [x] Verified first post-reboot direct iPhone capture in backup: 4.5-second AAC with nonzero signal and a 44-character persisted transcript (2026-10-13). The newly confirmed widget routes into capture; actual widget-originated audio still needs retesting after ensuring microphone works outside iPhone Mirroring.

## P5 — Ask Your Memory
- [x] P5 initial extractive answer mode (build 18): Ask memory directly from Smart search; question-word filtering improves lexical retrieval, 3 strongest verbatim transcript excerpts maximum, source date and original playable audio, clear no-evidence response. No generated summaries or unsupported facts.
- [x] Regression tests include Russian question filler ("Где я оставил ключи?"), archived-source-compatible recording references, answer suppression when no transcript mentions query, weak semantic score filtering, and 3-source cap.
- [ ] Physical iPhone acceptance of Ask memory, including relevant source links and honest no-evidence behavior.
- [x] Root cause of Ask memory single-term semantic failure: P4's safety gate for Find notes also disabled semantic retrieval in Ask mode; P5's separate semantic filter compounded the issue. Build 19 separates policies by mode and compares short conceptual queries against word vectors as well as whole-passage vectors. No hand-coded list of the user's three synonyms is used.
- [x] Added a model-availability notice and optional user-approved model installation in Ask memory, including for one-word queries.
- [ ] **Blocker:** evaluate actual Apple Russian contextual embedding quality on physical iPhone for conceptual pairs and tune minimum similarity. Mac mini Russian model is not installed; a direct iPhone Xcode model probe was blocked by the physical iPhone lock screen. Simulator deterministic tests validate wiring but not true Russian concept proximity.
- [ ] Later P5 extension: genuinely synthesized private answers if an appropriate, accurate on-device generative model becomes available, with claim-by-claim passage attribution and strict abstention. Never imply extractive retrieval is a generative Q&A model.

## Later
- [ ] Optional clustering, digests, reminders and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
