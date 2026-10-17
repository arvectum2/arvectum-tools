# What? — Product Roadmap

## P0 reopened — branded complication on physical Apple Watch (2026-10-17)

**RELEASE STOP.** Owner reports current published complication is a generic microphone and separate QA complication is a blank square. **Watch complication must show the recognizable UhWhat app icon, not an SF microphone or empty square.** [Full audited roadmap matrix](docs/WHAT_ROADMAP_AUDIT_2026-10-17.md).

- [x] Reused identical PNG Watch app icon bytes for full-color Watch complication.
- [x] Added a native vector silhouette from the exact existing UhWhat icon contours for system-tinted faces and accessoryCorner; no forced monochrome template on the full-color icon.
- [x] Built watchOS simulator target successfully, verified asset catalog contains WhatComplicationIcon; branded resource regression smoke test passes.
- [x] **Physical QA9 staged:** in-place signed 1.0.2 (9) installed on paired iPhone and Apple Watch SE with unchanged QA bundle IDs; pre/post Watch pending count 0, 17/17 iPhone QA Application Support file paths and sizes preserved. Installation does NOT prove the icon visually displays.
- [x] **Physical QA9 branded-icon PASS — owner 2026-10-17:** on actual Apple Watch face, icon is correct (not mic or blank square); owner also confirmed the recording was saved. Other families/tint combinations not separately examined. [Physical QA](docs/WATCH_BRAND_COMPLICATION_QA_2026-10-17.md).
- [x] **QA9 owner test flow PASS:** user confirmed «проверка прошла. значок правильный, запись сохранилась» for the requested Watch complication test. Explicit audio playback and no-duplicates on this specific QA9 recording were not separately stated; both were proven on prior QA8 and can be checked again if needed.
- [x] **Roadmap source audit refined (2026-10-17):** 27 traceable requirements (4 ready, 12 partial, 11 not ready); P4/P5 have prototype sources but no exposed navigation, P2 code is present but physical acceptance is pending. [Detailed audit](docs/WHAT_ROADMAP_AUDIT_2026-10-17.md).\n- [ ] **Owner release-scope agreement still OPEN:** review remaining P1/P2 QA and decide whether 1.0.2 is a focused reliability/brand fix or waits for later features. Previous IPA (SHA-256 39ae71cc...) is **superseded** and must not be uploaded.

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
- [x] **Physical disconnected Watch and reboot acceptance PASS (QA8):** two Watch notes recorded with iPhone OFF transferred in order with sound and no duplicates; separate Watch reboot with queued audio automatically delivered and playable without manually opening Watch app. QA9 branded complication also physically accepted. [Hardware evidence](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md).
- [ ] **P0 robustness still open:** repeated disconnects, ACK races under adverse conditions, forced termination during unfinished AAC write and unexpected power loss. Earlier successful tests do not prove an absolute no-loss guarantee.
- [x] **Core physical acceptance evidence consolidated** for one-tap, Digital Crown, queue, audio/dedup and reboot; physical P1/P2 QA9–11 findings and remaining limitations separately logged. [Physical Watch QA](docs/WATCH_ONE_TAP_PHYSICAL_QA_2026-10-16.md) / [iPhone QA](docs/WHAT_IPHONE_P1_P2_PHYSICAL_QA_2026-10-17.md).
- [ ] **Absolute no-loss under all failure scenarios NOT proven:** treat catastrophic file corruption, low storage and force-power-off cases as future stress/robustness acceptance, never a universal guarantee.

## Isolated physical P2a QA staged — 2026-10-17

- [x] Separate source QA branch qa/what-multimodal-physical-20261017 with iPhone ID ru.arvectum.tools.what.p2aqa, independent sandbox, distinct URL scheme and no embedded Watch app.
- [x] Signed physical iPhone build PASS; strict code signature and distinct ID verified.
- [x] Targeted QA simulator UI tests PASS 2/2, TEST SUCCEEDED (text note through plus, video through long press).
- [ ] Installation and physical M1–M4 acceptance pending: trusted iPhone currently unavailable. No existing QA13/production app or Watch updates.
- [ ] Full iPhone video/audio/camera/interruptions and iPad/Watch later acceptance; keep release on hold. See docs/WHAT_P2A_ISOLATED_PHYSICAL_QA_2026-10-17.md.

## P2a isolated integration checkpoint — 2026-10-17

- [x] Merged existing multimodal feature source with tested Watch P0/P1 fixes in **separate worktree**, preserving the original feature/release branches.
- [x] Resolved two source/generator conflicts: combined note-type Picker and linked RU/EN language Picker, regenerated Xcode project for iPhone + iPad families.
- [x] Integration compiled; simulator **92 unit/integration (3 skipped) and 9 UI (1 iPad skipped), 0 test-case failures**. Targeted long-press run also returned TEST SUCCEEDED.
- [ ] **Runner finalization issue:** integrated full test process remained alive for 6+ minutes after test-case completion without TEST SUCCEEDED or a finalized xcresult Info.plist; the stale test runner was terminated. Resolve this Xcode result reporting issue before calling the overall full test a clean terminal run.
- [x] Watch one-tap launch policy and branded complication smoke checks PASS. UI accessibility test for long press now recognizes actual video panel identifier; original video gesture needed no code fix.
- [ ] Separate fully signed **multimodal QA app identity** and physical test of text/video, camera switching and legacy audio/Watch synchronization before any merge to a release.
- [ ] iPad simulator/device not currently configured; physical iPad layout verification remains open.
- [ ] Review AVFoundation Sendability warning in VideoSegmentComposer and physical interruptions/low-storage before video is shippable.
- [ ] Do not include P2a in prior production IPA; no App Store upload authorized. [Integration evidence](docs/WHAT_P2A_WATCH_INTEGRATION_2026-10-17.md).

## P1 cancellation/race follow-up and P2a M1 baseline (2026-10-17)

- [x] Speech recognition now checks a unique per-attempt token as well as the recording UUID; late callbacks from a cancelled previous attempt, including after immediate retry of the same note, are ignored.
- [x] Speech denial, on-device recognition unavailability, silence and transcription errors now have RU/EN explanations; original audio/Watch delivery logic unchanged.
- [x] 5 focused synthetic tests PASS; serial full simulator suite PASS: 68 unit/integration (3 skipped) + 5 UI, zero failures.
- [x] Existing M1 source in separate multimodal feature branch builds with Xcode 27.1 and passes 3 isolated LocalNoteRepositoryTests. The work is not yet integrated with latest Watch fixes.
- [ ] Physical cancellation QA on isolated iPhone build: create a NEW throwaway test note, cancel a running re-transcription, verify saved audio and corrected text intact. Do not alter existing reviewed notes.
- [ ] P2a integration in separate worktree, complete Watch reliability regression and physical iOS video/text acceptance. No mixing into old release IPA.
- [ ] Existing production 1.0.2 IPA remains superseded. No App Store upload without a release-scope decision.

## P1/P2 UI defects after QA10 acceptance — 2026-10-17

- [x] **Physical QA10 English Speech auto-recognition PASS:** user set English, Watch note «The blue lighthouse is next to seven green apples.» appeared as exact automatic transcript; retry/replace produced the same text; locale returned to Russian. Corrected earlier Russian QA note was not overwritten.
- [x] **Physical QA10 diagnostics Russian labels PASS.**
- [x] **Navigation defect FIX in source:** diagnostics modal now has localized «Готово» / Done to dismiss back to recording library; previously no close/back action.
- [x] **UI/Speech language mismatch FIX in source:** Russian ↔ English language setting on iPhone updates both application UI and Speech recognizer locale, live and persisted across restart. Existing stored choices retained. Spanish Speech maintains English-interface fallback clearly labeled until full Spanish UI is available.
- [x] **Full regression PASS (2026-10-17):** 63 unit/integration tests (3 skipped, 0 failures), 5 UI tests (0 failures), Xcode TEST SUCCEEDED. Includes diagnostics RU/EN dismissal and live RU→EN→RU setting/persistence; no changes to Watch queue or automatic Speech. [Evidence](docs/WHAT_IPHONE_P1_P2_PHYSICAL_QA_2026-10-17.md).
- [x] **Isolated QA 1.0.2 (11) installed on iPhone in-place:** 22/22 existing QA Application Support files checked byte-identical by SHA-256 before/after. Watch still on QA10 as far as confirmed installations; no Watch reset/uninstall.
- [x] **Physical QA11 acceptance PASS (owner, 2026-10-17):** Done closes diagnostics, English changes UI immediately, Русский restores Russian UI; recordings intact.
- [ ] **Spanish UI localization backlog:** es-ES Speech exists, untranslated interface fallback remains English.
- [ ] **Release on hold:** scope agreement required; previous IPA obsolete. No App Store upload.

## P1/P2 continuation — language and diagnostics UX (2026-10-17)

- [x] Localized previously English-only Sync diagnostics screen for RU/EN using existing CaptureBrand locale behavior; Watch queue metrics and Speech logic unchanged.
- [x] Added and passed Russian + English diagnostics navigation and label UI tests on iPhone Duo Simulator (**2 tests, 0 failures**).
- [x] QA 1.0.2 (10) installed in place on iPhone 13 and Apple Watch SE; all 4 bundle signatures verified. 21/21 iPhone QA storage files retain names/sizes, Watch queue 0 before/after upgrade. No QA or production app removal.
- [x] **Hardware UI gate QA10 PASS:** Russian diagnostics labels on physical iPhone confirmed by owner.
- [x] **Physical P1 English Speech/retry PASS (QA10, 2026-10-17):** Watch English note automatically transcribed perfectly; retry/replace gave the same text; recognition locale restored to Russian. Original audio replay of the EN note was not separately reported.
- [ ] **Other remaining P1 edge cases:** cancellation, permission denied, direct iPhone mic with Mirroring off (no application mic bug), and release-scope decision. [Step-by-step physical QA](docs/WHAT_IPHONE_P1_P2_PHYSICAL_QA_2026-10-17.md).
- [ ] **No public upload:** previous signed production IPA predates branded Watch complication and translated diagnostics, and is superseded.

## Active P1/P2 physical iPhone QA — 2026-10-17

- [x] Audit physical app scope: «Ухват QA» version 1.0.2 (9) is installed on iPhone 13; existing production storage and notes remain untouched.
- [x] Focused iPhone Duo Simulator regression: **14 tests, 0 failures**, covering transcript edits/persistence, search/day grouping, archive, original audio and text export, and delete isolation.
- [x] **Physical P1 automatic Russian Speech from Watch — owner-confirmed 2026-10-17:** Watch QA9 note automatically transcribed on iPhone: «Проверка охвата бирюзовой маяк стоит на полке номер семь напомнить про зелёный чай в субботу». Keep automatic transcription as default. Two observed deviations: «Ухвата» -> «охвата» and «Бирюзовый» -> «бирюзовой».
- [x] **Physical P1 corrected transcript persistence/audio PASS — owner 2026-10-17:** QA9 edited text survived ordinary app reopen, search found the note, original Watch-sourced audio remained playable.
- [ ] **Additional P1 edge cases:** permission denial, retry cancellation and direct iPhone microphone capture with Mirroring inactive (separate QA, not an application bug); English recognition/retry and language restoration physically passed.
- [x] **Physical P2 search PASS — owner 2026-10-17:** search locates the edited test transcript in iPhone QA9.
- [x] **Physical P2 archive/restore PASS — owner 2026-10-17:** synthetic QA9 note moved out of Inbox to Archive, text and audio retained, restored to Inbox with corrected transcript/playback intact. No deletion of other notes requested.
- [x] **Mirroring microphone question CLOSED — not an UhWhat defect (2026-10-17):** user identified iPhone Mirroring capturing camera/microphone as the cause. Remove this from app defect/release blockers. Optional direct iPhone mic QA only when Mirroring is off.
- [x] **Physical P1/P2 core acceptance PASS:** RU/EN automatic transcription, corrected text/audio/search, archive/restore, diagnostics, and QA11 language UI/Dismiss confirmed. [Evidence](docs/WHAT_IPHONE_P1_P2_PHYSICAL_QA_2026-10-17.md). No upload.

- [x] **Physical P2 Watch diagnostics PASS — owner screenshot 2026-10-17:** last reported Watch queue 0 at 09:43:42; 15 phone notes/15 stored audio files/10 transcripts. Last Watch report is a cached snapshot, not a live guarantee.
- [ ] **Optional P1/P2 edge cases:** retry cancellation, denied Speech permission, direct phone capture with Mirroring inactive (not an UhWhat bug) and release scope agreement. RU/EN switching and retry separately PASSED. No upload.
- [x] **Diagnostics RU/EN localization PASS:** earlier English screenshot came from QA9; QA10 user confirmed RU, QA11 confirmed live English/Russian switching.

## P1 — Voice + transcribed text (existing; not a manually typed note)
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [x] **Physical P1 PASS (QA9–11):** Watch-sourced audio played on iPhone; RU/EN audio notes auto-transcribed; user-corrected text persisted across reopen and remained searchable/playable; repeat recognition confirmed; RU/EN Speech language controls live UI and survives restart. [Evidence](docs/WHAT_IPHONE_P1_P2_PHYSICAL_QA_2026-10-17.md).
- [ ] **P1 edge cases open:** cancel mid-transcription and Speech permission denied on real devices (without erasing existing notes). Direct iPhone capture is a separate test with iPhone Mirroring inactive; the Mirroring mic conflict is not an app defect.

## P2 — iPhone inbox
- [x] **Physical P2 core inbox PASS (QA9–11):** transcript search, playable audio, archive/restore, cached Watch diagnostics view (last Watch pending report 0), and modal Done navigation physically confirmed. Corrected text/audio survived archive cycle. [Evidence](docs/WHAT_IPHONE_P1_P2_PHYSICAL_QA_2026-10-17.md).
- [x] **Automated repository P2 checks PASS:** Today/Yesterday grouping, archive+delete isolation and persistence/search exercised in isolated XCTest data; no real user notes deleted.
- [ ] **P2 optional physical QA remaining:** Today/Yesterday date boundaries, test-note deletion confirmation and failure handling, and delayed Watch status differences vs real-time state. Don't infer these from successful search/archive or a cached report.

## P2a — Unified multimodal capture on iPhone and iPad (new backlog, 2026-10-16)

**Target experience and device matrix:**

**Capture controls (mandatory UX contract):** On **iPhone and iPad**, keep the existing **large round recording button** as the primary control: **short tap → start audio recording immediately**, **long press → start video capture with the camera** (no Text/Audio/Video selection menu). The small **`+` button opens a new typed text note only**. Watch keeps its **one-tap audio** complication and audio-only interface. Distinguish a long press from a short tap before triggering capture: a long press must never accidentally start an audio recording first. Keep obvious recording state, haptic/visual feedback, Stop/Save/cancel and permission handling for both media types.

| Device | Text note (typed) | Audio note | Video note |
| --- | --- | --- | --- |
| **Apple Watch** | — | **Yes — one-tap voice capture**, existing primary flow | — |
| **iPhone** | **Yes — compose and edit** | **Yes — keep existing fast audio capture** | **Yes — record with camera in app** |
| **iPad** | **Yes — compose and edit** | **Yes — record with microphone** | **Yes — record with camera in app** |

**Implementation status (feature branch, 2026-10-16):** M1–M6 now have source-level implementation in feature/what-multimodal-20261016. iPhone simulator and iPad simulator targets build; the iOS unit suite completed 64 tests with 0 failures (3 existing skips). iPhone simulator UI test for new text note autosave/inbox passed; on iPad simulator both home/library navigation and new typed note UI tests passed. A separate iPhone simulator UI test verified that a long press routes to the video UI or its camera-unavailable alert instead of an audio sheet. Camera capture and the gesture still need **physical iPhone/iPad acceptance**. The existing iOS release / App Store binary is unchanged, and no private data was migrated or uploaded. This is **not a shipping decision**. iPhone ↔ iPad cross-device note sync remains out of scope unless explicitly approved.

**QA gates remaining:** real camera video with audible microphone track, physical front/back switch; app background/kill and low storage; iPad split view and large text; launch/stop and denied camera/microphone; iPhone's short/long press distinction and accessibility alternative; videos after restart/upgrade; Watch offline/ACK regression. The next release remains blocked on those physical checks and a separate signed candidate.

- [x] **M1 · Unified local note model:** one inbox for `text`, `audio`, and `video`, with stable UUID, creation/edit timestamps, explicit media kind, optional body/transcription, local original-media URL and source device. Keep Watch audio IDs, migration, ACK/dedupe and existing archives backward-compatible; never replace original media with generated text.
- [x] **M2 · Native text note (iPhone/iPad):** `+` → Text, instant empty editor with keyboard focus, manual typing and editing, reliable local draft/autosave, cancel/delete safeguards and optional title. Text must work offline without Speech permission, microphone or camera.
- [x] **M3 · Preserve fast audio (iPhone/iPad):** a **short tap on the existing large round record button** starts the existing audio recording immediately (no mode chooser); support playback, transcription (with explicit permission), edit transcription separately from original audio and reuse stable note identity. On Watch retain **audio-only** complication → immediate recording, with no new selection screen.
- [ ] **M4 · Native video note (iPhone/iPad) — code implemented; physical validation pending:** a **long press on the same large round record button** starts video capture with the device camera **inside Ухват**, without an intermediate mode chooser; provide clear recording/Stop state, elapsed timer and preview. Resolve short-vs-long press before starting audio so a video gesture never leaves a stray audio note; show haptic/visual confirmation. Ask Camera/Microphone permissions only when needed, handle refusal and interruption, and never record without an explicit user action. Save original video locally atomically; support preview/playback, poster frame, size/duration indication and safe delete/export. If video speech-to-text is added, it must be optional and must not overwrite the video. Importing existing library videos is a separate enhancement, not a prerequisite for recording.
- [x] **M4b · Switch back/front camera during video capture — implemented, physical QA open (2026-10-16):** add an accessible camera-rotate button in the video recorder. A tap switches main → front or front → main while recording, showing explicit switching feedback; Stop/Discard take priority. Because AVFoundation movie-file output cannot safely hot-swap an input in-place, close the current segment, reconfigure the camera input and start another local segment. On Stop, merge all segments into one playable MOV file with audio and per-segment orientation, saving to the existing local repository; never discard the originals before a confirmed successful save. Five new simulator tests pass, including decoding different colored frames before/after a camera switch and checking the combined audio track. **Still open:** physical front/back camera capture, video/audio continuity, interruptions, rapid switch/Stop, device rotation and low-storage recovery. Not installed on the iPhone or shipped.
- [x] **M5a · Adaptive iPad simulator layouts (2026-10-16):** home scrolls in short/narrow panes while keeping the large round record button and + text action; long headlines wrap with Dynamic Type; library and text editor use readable maximum widths, and camera-preview controls scroll when iPad Split View leaves limited height. On an iPad simulator in landscape, the UI test reaches audio capture, text editor and the Inbox/back navigation. The iPad build passes. **Still open:** actual Split View resizing, very large accessibility fonts and physical iPad camera/microphone acceptance. M5 is not fully done.
- [ ] **M5 · iPad-first-class UI — iPad simulator build passes; physical/layout validation pending:** expand iOS device family to include iPad, make text editor/recorders/camera preview and Inbox usable in portrait, landscape, split view and large text; ensure iPhone-specific layouts, Share sheet, permission copy, icons and Store device assets remain correct. Do not claim an iPad release until actual build and device/simulator QA passes.
- [ ] **M6 · One Inbox, sensible presentation — code implemented; UI acceptance pending:** preserve the **large round recording button** (short tap = audio; long press = video) and add a separate unobtrusive **`+` for typed text notes only** on iPhone/iPad; no three-way capture menu. Provide a discoverable long-press hint without cluttering the capture screen, plus type indicators, inline text, thumbnails/previews and type filters; preserve search, archive/delete, timestamps, per-note links and notification-reminder eligibility. Video assets remain local-first; sharing/synchronization across iPhone and iPad is **not automatically implied** by supporting both devices and needs a separate opt-in architecture decision.
- [x] **M7a · Crash-safe video journal and recovery — simulator verified, physical QA pending (2026-10-16):** video segments now live under a stable session UUID with an atomic manifest. A subsequent app launch scans unfinished captures, recovers valid single/multi-camera segments to the unified Inbox and identifies notes by the original capture UUID to avoid duplicates after an interrupted repository commit. Corrupt/unreadable segments are retained for recovery rather than erased; explicit Discard records a tombstone first. The UI shows a non-blocking recovery notice. Test scenarios: crash before import, crash after import, camera-switch segments, truncated clip, explicit discard, legacy audio untouched and missing-media repair. **Still open:** physical interruption and forced-kill tests, low-storage failure, unusually large videos and upgrades from a real-device build. Do not treat M7 as completed until acceptance.
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
- [x] **P6a · Manual on-device follow-up reminders — simulator verified, physical notification QA pending (2026-10-16):** every audio/text/video note can schedule or reschedule a local alert in 1, 2 or 3 hours. Per-note UUID avoids duplicates; cancel, mark reviewed and note deletion cancel the pending alert. Intents are saved atomically and missing notifications are reconciled after restart without showing an unexpected permission prompt. Notification content is generic and privacy safe, carrying only a note UUID for tap-through to a focused Inbox panel. Includes denied-permission, crash/relaunch, reschedule, cancellation, deletion and privacy tests. **Not auto-enabled:** no reminders are created without a deliberate per-note action. Physical notification arrival and tap-through still require acceptance testing.
- [ ] **P1 · Optional auto-follow-up:** opt-in rule "new note → remind after 1/2/3 hours", with quiet-hour/notification-permission handling, duplicate protection by stable recording UUID and no reminders for deleted notes. Add a low-noise daily review/digest only as a subsequent option if individual alerts prove noisy.
- [ ] **P1 · ChickMark handoff:** optional local-only integration to create a distinct "Review this note" follow-up in ChickMark, **not** a recurring habit or an automatic habit completion. Carry the saved/edited transcription as the follow-up's full text, recording UUID, creation time and a deep link back to the original audio in Ухват. The notification itself defaults to privacy-safe generic text; showing transcription on the lock screen is a separate explicit choice.
- [ ] **P1 · Integration feasibility spike:** validate app-to-app transfer for the two signed iOS apps (App Group/shared container versus App Intents/Shortcuts/openURL), actual background/notification limits, permissions and behavior when ChickMark is not installed. Never require cloud, network or an always-running companion app. If unavailable, use Ухват's own local notification fallback.
- [ ] **Acceptance:** test Watch offline/delayed arrival, transcription still pending, edited transcription after handoff, app reinstall/upgrade, duplicate Watch deliveries, deleted/archived notes, ChickMark unavailable, denied notification permission, timezone/quiet hours, and tap-through to the correct audio. Do not silently copy private transcripts to shared or external destinations without opt-in.

## Later
- [ ] Optional clustering and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
