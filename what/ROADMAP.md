# What? — Product Roadmap

## P0 release blocker — physical one-tap Watch capture (2026-10-16)

- [x] **Regression reproduced by owner on App Store 1.0.1:** Watch-face complication opens the app but does not start recording. Previous `widgetURL(what://capture)` assumption is not sufficient on physical Watch.
- [x] **Source fix for 1.0.2:** Watch starts capture when its scene becomes active (including cold appearance and return from Watch face), without waiting for `.onOpenURL`; keep deep link as a secondary trigger and prevent duplicate starts.
- [x] **Source/simulator checks:** Watch build PASS; physical widget URL is no longer required; simulator cold launch automatically attempted recording (simulator microphone/audio session failed, so real AAC remains unproved); pure launch policy check passed for 5 capture states. iOS regressions: 61 tests (3 skipped), 2 UI tests PASS. Repeated Watch-face and Crown interruption scenarios still require hardware.
- [x] **Isolated physical QA build installed:** separate `ru.arvectum.tools.what.qa` on iPhone 13 and `ru.arvectum.tools.what.qa.watch` on paired physical Apple Watch SE; watch complication extension embedded and signed. Production app/data unmodified. [QA protocol](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Physical one-tap capture (QA build) — user-confirmed 2026-10-16:** tapping the Watch-face QA complication immediately started a recording on Apple Watch SE, no second tap. [Evidence/checklist](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Physical audio delivery/playback (QA build) — user-confirmed 2026-10-16:** Watch recording appeared as a new note on iPhone and audio played with sound after the Stop-button scenario. [QA evidence](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Physical Digital Crown interruption (QA build) — user-confirmed 2026-10-16:** recording was saved after Digital Crown without Stop. [QA evidence](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md). Playback of this specific recording was not explicitly confirmed.
- [x] **Physical offline Watch batch delivery (QA build) — user-confirmed 2026-10-16:** two notes recorded while iPhone switched off; after reconnection they synchronized, played with sound and retained order. [QA evidence](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Offline batch dedup QA — user-confirmed 2026-10-16:** prior two notes were delivered without duplicates.
- [x] **P0 reboot transfer regression — reproduced in QA7, FIX VERIFIED in QA8 (2026-10-17):** initial saved recording was not delivered after reboot until manually reopening Watch QA; after recovery patch, offline-saved note reached iPhone automatically post-reboot with playable audio and without duplicates. [Historical failure and physical retest](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Source-level recovery + physical verification:** iPhone queues background-deliverable WatchConnectivity recovery request at activation/foreground; Watch re-reads persisted queue after unlock and reschedules pending UUIDs. The previously failing physical reboot-to-iPhone scenario succeeded on QA8.
- [x] **Final targeted one-tap/Crown physical regression — QA8 PASS (2026-10-17):** Watch complication one tap -> record -> Digital Crown -> iPhone playable audio with no duplicates. Reboot automatic delivery/audio/no-duplicate separately passed on QA8. Force-quit/repeated network-edge tests remain optional robustness follow-ups.
- [x] **Post-reboot forensic evidence:** physical Watch QA index recovered read-only: one pending envelope, duration 4.412 s, after owner-confirmed Stop before restart. AAC file transfer to Mac failed due to watch connection timeout; original file integrity remains unverified.
- [x] **Physical reboot note recovered by manual Watch relaunch — user-confirmed 2026-10-16:** previously missing 4.412-s queue entry appeared on iPhone when existing Watch QA was opened after reboot. Underlying automatic wake/retry remains broken; patched source still requires a physical test. [QA evidence](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Recovery QA build (8) staging history:** iPhone upgraded first, verified 13 Application Support files intact and backed up on ArvectumSSD; Watch upgraded in place after link restoration. See completed physical verification below.\n- [x] **Matched physical recovery QA8 installed (2026-10-16):** Watch and iPhone QA installed in place as 1.0.2 (8), Watch pre-upgrade queue was empty/backed up, no app removals. [Subsequent physical reboot acceptance PASS](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Automatic physical Watch reboot recovery — QA8 FULL USER PASS (2026-10-17):** after Stop → Watch reboot → iPhone return, recording arrived automatically without reopening Watch QA. Owner independently confirmed audio playback and no duplicates («Звук есть, дублей нет»). [Acceptance evidence](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [x] **Full final-branch iOS regression (2026-10-17):** 63 unit/integration tests (3 skipped), 2 UI tests, zero failures on iPhone Duo Simulator. Physical QA (8) reboot delivery/audio/dedup separately confirmed by owner.
- [x] **Production 1.0.2 (7) locally built and exported for App Store (2026-10-17):** full Release archive and IPA export succeeded; four signed bundles have production IDs, Apple Distribution certificate, get-task-allow=false, strict codesign PASS, SHA-256 39ae71cc0c3d65d92d6998823f600e7861c44a91cec75762d33155e3faa99dc6. [Release evidence](docs/WHAT_1_0_2_FINAL_RELEASE_READINESS_2026-10-17.md).\n- [ ] **FINAL RELEASE GATE:** PR #84 CI/review, current App Store Connect state/build checks, explicit owner authorization to upload/submit and server-side validation. No upload/publication has occurred; do not silently submit.

## A5 — isolated next-patch candidate (2026-10-15)

- [x] Created isolated A5 release source candidate **1.0.2 (7)** from main. [Release gate](docs/A5_RELEASE_CANDIDATE_1_0_2_2026-10-15.md).
- [ ] Signing, full independent CI, physical QA and Apple submission remain separate gates; source candidate is **not** an App Store upload or approval.


## Адаптация iPad / iPhone Duo — 2026-10-16

**Статус:** бэклог; реализация iPad **частично есть только в feature/what-multimodal-20261016**, а не в текущей main и не в опубликованной версии. [Общая матрица Core](../core/DEVICE_ADAPTATION_ROADMAP.md).

**Инфраструктура (16.10.2026):** Xcode 27.1 активна; частичная поддержка iPad уже реализована в feature/what-multimodal-20261016. Первый пилот адаптивного Core — библиотека/редактор. WH-D0…D3 остаются открытыми; Duo QA ждёт runtime iOS 27.1 (T3/T4). Проверка физической камеры и Watch — отдельно.

- [ ] **WH-D0 · Подтвердить baseline:** перенести/сверить M5a из multimodal feature-ветки и готовность iPad target family 1,2 без случайного включения в релиз.
- [ ] **WH-D1 · iPad:** сохранить одну большую круглую кнопку (короткое нажатие — аудио; долгое — видео), отдельный плюс для текстовой заметки; проверить editor, библиотеку, камеру, кнопки Стоп и смены камер, portrait/landscape/Split View/Stage Manager, VoiceOver.
- [ ] **WH-D2 · iPhone Duo:** закрытый экран — один жест записи и быстрая библиотека; раскрытый — полноценная библиотека/редактор. При fold/unfold во время видео, переключения фронтальной камеры, аудиозаписи или незавершённого текста не терять медиа/черновик и не запускать дубль записи. Watch одно касание сохраняется без изменений.
- [ ] **WH-D3 · QA и отдельный релиз:** симулятор на обоих размерах Duo, реальные разрешения Camera/Mic, recover journal, большие записи, жесты, background/foreground, Watch ACK, уведомления о заметках и App Store assets. Отсутствие Duo runtime фиксировать как блокер физической/симуляторной приёмки, а не как успешно пройденный тест.

## Active release checkpoint — 2026-10-15

**A5 RC:** [Ухват 1.0.2 (7)](../core/A5_SIGNED_RELEASE_CANDIDATES_20261015.md) подписан, iPhone/Watch/complication/widget проверены, CI PASS, **не загружен в ASC**. Отправленная 1.0.1 (6) ещё WAITING_FOR_REVIEW; физическая 1-tap/ACK/офлайн-проверка остаётся OPEN.

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

**Updated:** 2026-10-16 (multimodal text/audio/video + iPad backlog added; no application code or release binary changed). **Shared Core:** [Core](../core/ROADMAP.md).
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

## P1 — Voice + transcribed text (existing; not a manually typed note)
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [ ] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection, retry/cancel controls and transcript corrections.

## P2 — iPhone inbox
- [ ] Today/Yesterday grouping, search, archive/delete and sync status; playback available in initial list.

## P2a — Unified multimodal capture on iPhone and iPad (new backlog, 2026-10-16)

**Target experience and device matrix:**

**Capture controls (mandatory UX contract):** On **iPhone and iPad**, keep the existing **large round recording button** as the primary control: **short tap → start audio recording immediately**, **long press → start video capture with the camera** (no Text/Audio/Video selection menu). The small **`+` button opens a new typed text note only**. Watch keeps its **one-tap audio** complication and audio-only interface. Distinguish a long press from a short tap before triggering capture: a long press must never accidentally start an audio recording first. Keep obvious recording state, haptic/visual feedback, Stop/Save/cancel and permission handling for both media types.

| Device | Text note (typed) | Audio note | Video note |
| --- | --- | --- | --- |
| **Apple Watch** | — | **Yes — one-tap voice capture**, existing primary flow | — |
| **iPhone** | **Yes — compose and edit** | **Yes — keep existing fast audio capture** | **Yes — record with camera in app** |
| **iPad** | **Yes — compose and edit** | **Yes — record with microphone** | **Yes — record with camera in app** |

**Status:** backlog only; the current iOS Xcode target uses `TARGETED_DEVICE_FAMILY = 1` (iPhone only), so **native iPad support is not implemented or validated**. Existing on-device Speech audio transcription does **not** mean manually composed text notes are already supported. Preserve the current Watch capture-first/ACK reliability before introducing new capture modes; none of these changes are in the public or Apple-submitted releases.

- [ ] **M1 · Unified local note model:** one inbox for `text`, `audio`, and `video`, with stable UUID, creation/edit timestamps, explicit media kind, optional body/transcription, local original-media URL and source device. Keep Watch audio IDs, migration, ACK/dedupe and existing archives backward-compatible; never replace original media with generated text.
- [ ] **M2 · Native text note (iPhone/iPad):** `+` → Text, instant empty editor with keyboard focus, manual typing and editing, reliable local draft/autosave, cancel/delete safeguards and optional title. Text must work offline without Speech permission, microphone or camera.
- [ ] **M3 · Preserve fast audio (iPhone/iPad):** a **short tap on the existing large round record button** starts the existing audio recording immediately (no mode chooser); support playback, transcription (with explicit permission), edit transcription separately from original audio and reuse stable note identity. On Watch retain **audio-only** complication → immediate recording, with no new selection screen.
- [ ] **M4 · Native video note (iPhone/iPad):** a **long press on the same large round record button** starts video capture with the device camera **inside Ухват**, without an intermediate mode chooser; provide clear recording/Stop state, elapsed timer and preview. Resolve short-vs-long press before starting audio so a video gesture never leaves a stray audio note; show haptic/visual confirmation. Ask Camera/Microphone permissions only when needed, handle refusal and interruption, and never record without an explicit user action. Save original video locally atomically; support preview/playback, poster frame, size/duration indication and safe delete/export. If video speech-to-text is added, it must be optional and must not overwrite the video. Importing existing library videos is a separate enhancement, not a prerequisite for recording.
- [ ] **M5 · iPad-first-class UI:** expand iOS device family to include iPad, make text editor/recorders/camera preview and Inbox usable in portrait, landscape, split view and large text; ensure iPhone-specific layouts, Share sheet, permission copy, icons and Store device assets remain correct. Do not claim an iPad release until actual build and device/simulator QA passes.
- [ ] **M6 · One Inbox, sensible presentation:** preserve the **large round recording button** (short tap = audio; long press = video) and add a separate unobtrusive **`+` for typed text notes only** on iPhone/iPad; no three-way capture menu. Provide a discoverable long-press hint without cluttering the capture screen, plus type indicators, inline text, thumbnails/previews and type filters; preserve search, archive/delete, timestamps, per-note links and notification-reminder eligibility. Video assets remain local-first; sharing/synchronization across iPhone and iPad is **not automatically implied** by supporting both devices and needs a separate opt-in architecture decision.
- [ ] **M7 · Acceptance and safe release:** tests for app restart mid-draft, background/low storage while recording, media integrity after interruptions, cancelled capture, camera/mic/Speech denied, large video, deletion without orphan files, old audio-model migration, Watch offline/ACK regression, gesture arbitration (short tap audio; long press video; no unintended audio), long-press discoverability and accessibility alternatives for users unable to hold the button, iPhone+iPad layouts, permission/privacy descriptions and no implicit cloud uploads. Gate shipping behind iPhone/iPad physical QA and its own signed release; do not alter already submitted IPA or any existing user's notes.

**Proposed delivery order:** M1 + M2 (typed text first), then M3 (shared audio interface), M4 (video), M5–M7 (iPad/adaptive Inbox + acceptance). New capture modes must remain secondary to Watch's one-tap audio workflow and the existing durable queue.

## P3 — Apple Notes / Shortcuts
- [ ] Export and optional system integration without depending on cloud.

## P4 — Semantic memory
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## P6 — Follow-up reminders for captured notes (post-1.0 backlog)
- [ ] **P1 · Revisit a note later:** after saving a new text/audio/video note (including audio delivered from Watch), offer one-tap "Напомнить" with +1 / +2 / +3 hours from the time it becomes available on iPhone; allow per-note override, reschedule, cancel and mark reviewed. Keep recording/Watch transfer fast and unaffected by notification scheduling. No default reminders unless explicitly enabled by the user.
- [ ] **P1 · Optional auto-follow-up:** opt-in rule "new note → remind after 1/2/3 hours", with quiet-hour/notification-permission handling, duplicate protection by stable recording UUID and no reminders for deleted notes. Add a low-noise daily review/digest only as a subsequent option if individual alerts prove noisy.
- [ ] **P1 · ChickMark handoff:** optional local-only integration to create a distinct "Review this note" follow-up in ChickMark, **not** a recurring habit or an automatic habit completion. Carry the saved/edited transcription as the follow-up's full text, recording UUID, creation time and a deep link back to the original audio in Ухват. The notification itself defaults to privacy-safe generic text; showing transcription on the lock screen is a separate explicit choice.
- [ ] **P1 · Integration feasibility spike:** validate app-to-app transfer for the two signed iOS apps (App Group/shared container versus App Intents/Shortcuts/openURL), actual background/notification limits, permissions and behavior when ChickMark is not installed. Never require cloud, network or an always-running companion app. If unavailable, use Ухват's own local notification fallback.
- [ ] **Acceptance:** test Watch offline/delayed arrival, transcription still pending, edited transcription after handoff, app reinstall/upgrade, duplicate Watch deliveries, deleted/archived notes, ChickMark unavailable, denied notification permission, timezone/quiet hours, and tap-through to the correct audio. Do not silently copy private transcripts to shared or external destinations without opt-in.

## Later
- [ ] Optional clustering and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
