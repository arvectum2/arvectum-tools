# Ухват — физическая приёмка P1/P2 на iPhone, 17.10.2026

**State: AUTOTESTS PASS; REAL iPHONE auto-transcription, corrected text, search, audio, archive/restore PASS on QA9; remaining edge cases still open. No production installation or App Store upload.**

## Setup

- Paired iPhone 13, separate app **Ухват QA** version **1.0.2 (9)**, bundle ru.arvectum.tools.what.qa. Physical Watch QA (9) remains installed.
- Production Ухват and existing user content **must not be uninstalled, reset, modified or deleted**.
- Only the owner should speak the test phrase and interact with the actual iPhone UI; the test phrase is non-sensitive and does not require access to private saved notes.
- Test synthetic note text: **«Проверка Ухвата. Бирюзовый маяк стоит на полке номер семь. Напомнить про зелёный чай в субботу.»**
- Do not archive or delete existing notes. Later archive only this test UUID/note.

## Stage 0 — automated coverage on isolated iPhone Duo simulator

- [x] 2026-10-17 selected **14/14 XCTest tests PASS, 0 failures**, test execution succeeded.
- Scope: transcript persistence, manual edits across relaunch, preservation of original audio, edit validation, archive persistence, archive deletion consistency, unknown UUID guards, inbox text case-insensitive search and archive separation, Today/Yesterday grouping, original audio+text export, export failure cleanup, other-note isolation, cache reindexing after edited transcript.
- Log on ArvectumSSD: builds/what-p1p2-acceptance-20261017/focused-regressions.log.
- Unit tests use isolated repositories and synthetic recordings, not the user's private notes. Simulator tests **do not demonstrate actual Apple Speech transcription quality** on hardware.

## Accepted primary input: Apple Watch (2026-10-17)

- Owner identified the iPhone mic/camera behavior as an **iPhone Mirroring capture resource conflict**, not an UhWhat application defect. Do not require repeated disconnection/reconnection merely to exercise Speech, correction, library, search and archive.
- **Primary physical acceptance input is Watch QA (9)**, already independently verified for one-tap recording and transfer. Dictate the fixed Russian test phrase on Apple Watch, tap Stop, wait for it to arrive on iPhone QA (9), then run Apple Speech and P1/P2 iPhone flows on that incoming note.
- This validates real Watch microphone -> durable transfer -> iPhone stored audio -> actual **iPhone-side** SFSpeechRecognizer -> text persistence/correction -> search/archive. Differences in acoustic microphone quality can change recognition accuracy, but do not invalidate processing/UX acceptance.
- **Closed as non-app bug (owner resolution 2026-10-17):** iPhone Mirroring takes exclusive camera/microphone access in the owner environment; do not track this as a microphone failure or release blocker in UhWhat. If direct iPhone recording needs to be physically exercised later, test with Mirroring inactive. Watch-sourced audio does not itself verify iPhone mic capture, but this is a separate normal coverage gap, not a defect.
- All destructive tests remain isolated to a new synthetic QA note. Production storage never touched.

## Stage 1 — real iPhone transcription / original audio (OWNER)

- [x] **Physical QA9 Watch-sourced note delivered and transcribed on iPhone (2026-10-17):** owner recorded test phrase on Watch and reported automatic iPhone Speech transcription. Playback of this particular note was not explicitly confirmed; direct iPhone microphone not tested.
- [x] **Russian-language recognition confirmed by real output:** intelligible Russian transcript received. Manual locale-switch UI has not been explicitly exercised.
- [x] **Auto-transcription PASS:** user confirmed «Расшифровка у нас автоматическая (это хорошо, так и оставим)». Preserve automatic recognition as default. Manual transcription/retry is a fallback, not mandatory.
- [x] **Real Russian transcript exists, semantic content preserved.** Exact user result: «Проверка охвата бирюзовой маяк стоит на полке номер семь напомнить про зелёный чай в субботу». Two errors against target: «Ухвата» -> «охвата» and «Бирюзовый» -> «бирюзовой»; punctuation omitted. Keywords «маяк», «номер семь», «зелёный чай» and «в субботу» survived. This is a quality observation, not a guarantee.
- [x] **Owner physical PASS 2026-10-17:** audible playback of the same corrected note confirmed.

## Stage 2 — correction and search (OWNER, after Stage 1)

- [x] **Owner physical PASS 2026-10-17:** edited the transcript on the Watch-sourced QA9 test note and saved. Owner said «правка сохранилась». Exact presence/spelling of the optional unique marker was not separately quoted.
- [x] **Owner physical PASS 2026-10-17:** text correction persisted after the instructed leave/reopen check, reported «правка сохранилась». This is an ordinary app reopen, not an OS-level hard reset.
- [x] **Owner physical PASS 2026-10-17:** library search finds the edited QA test note («в поиске ищется»). Specific matching of the optional unique marker and empty/no-results search were not explicitly reported; leave those as optional extended UX tests.
- [x] **Owner physical PASS 2026-10-17:** original recording still plays after correction («аудио воспроизводится»).

## Stage 3 — archive and non-destructive navigation (OWNER)

- [x] **Physical owner PASS 2026-10-17:** test recording moved into «Архив», disappeared from «Входящие», and appeared in «Архив». Owner reported «да, все прошло правильно» in answer to full Stage 3 instructions.
- [x] **Physical owner PASS 2026-10-17:** corrected text and original audio retained in archive, then correctly playable after return to Inbox. Separate unique-marker-only search while in archive was not explicitly reported; do not infer that isolated subtest.
- [x] **Physical owner PASS 2026-10-17:** test recording returned to Inbox; corrected transcript and playable audio intact. This check does not demonstrate destructive delete behavior or other notes' state.
- [x] **Owner screenshot physical QA9 PASS, 2026-10-17:** Sync diagnostics opened and displays 15 recordings, 15 audio files, 10 transcribed notes, iPhone captured starts 0, Watch pending count **0**, last report **17 Oct 2026 09:43:42**. This is the Watch's latest reported snapshot, not a real-time polling result. Do not infer all files are complete/playable merely from a count.
- [ ] Confirm cancellation of transcript retry retains corrected text; cancellation / permissions QA optional and non-destructive.

## Safety and acceptance rules

- No device uninstall/reinstall, no deletion of production/QA existing notes, no edits outside newly created synthetic note.
- Automated tests provide source/regression evidence only. Every physical step remains unchecked until owner reports actual result.
- Export / Apple Notes / Shortcuts integration remains separate P3; text/video, iPad/Duo, reminders/ChickMark and semantic search remain separate roadmap milestones.
- If audio does not play or recognizer returns silence/empty/error, record observed text and app screen; do not mark P1 complete.
- Release remains on hold until owner agrees scope; pre-branding production IPA is obsolete.

## Physical Speech observation and product decision (2026-10-17)

- **PASS:** after Apple Watch capture, iPhone automatically generated Russian transcription without a manual Transcribe step. User explicitly wants this to remain the default behavior.
- This particular recognizer result preserves meaning with deviations in the product name and adjective; record as an ASR quality note, not a functional blocker.
- **2026-10-17 FOLLOW-UP PASS:** user reported edited text retained, found in search and audio plays. Archive/restore subsequently confirmed by owner. Remaining optional cases: denied Speech permission, retry/cancel and English locale. The Mirroring-related microphone conflict is closed as external to UhWhat.
- Next user checkpoint: select only this new QA note, tap «Править текст», correct «охвата» -> «Ухвата» and «бирюзовой» -> «Бирюзовый», append «контрольный маяк девятнадцать», save. Leave and reopen app to verify persistence, then search for the marker, and replay the same audio. Do not alter older notes.

## Stage 2 physical result — text / search / audio PASS (2026-10-17)

Owner reported «правка сохранилась, в поиске ищется, аудио воспроизводится» after being asked to correct the ASR text, reopen QA, search and play the original Watch-sourced recording. All core Step 2 behaviors are confirmed on physical iPhone QA9. Optional specific-marker and no-results-query checks are not separately evidenced. Next acceptance: **archive/restore only the same test recording** and verify edited text and original audio survive.

## Stage 3 physical result — archive and restore PASS (2026-10-17)

Owner reported «да, все прошло правильно» directly after the four-step instruction to archive **only** the new synthetic QA9 note, verify it moved from Inbox to Archive, check the edited transcript and original sound, and restore it back to Inbox. Mark all three core Stage 3 checks PASS, including retained text and sound after restore. No deletion was requested or conducted. Watch diagnostics physical screen subsequently passed. Remaining optional edge-case checks: Speech locale/permission/retry/cancel; direct iPhone mic can be tested later with Mirroring off, not a release defect.

## Stage 4 — screenshot acceptance: Watch sync diagnostics (2026-10-17)

- [x] User supplied a physical QA9 screenshot of the Sync diagnostics screen. The screenshot was inspected in the current conversation; it was **not** committed or uploaded to the public repo.
- Displayed state: **15 iPhone recordings, 15 audio files, 10 notes with transcriptions**, **0 iPhone captured starts**, **0 Pending on Watch**, Watch report timestamp **2026-10-17 09:43:42** (displayed local device time). Counts are per the screenshot, not a fresh server/Watch polling query.
- **PASS:** diagnostics screen opens, reports a recent Watch state, and renders the pending count. The count 0 at that timestamp indicates no queued items in the last Watch report, **not continuous real-time monitoring**. The equal recordings/audio-file counts do not independently prove every AAC file's integrity.
- **Product/root-cause clarification from owner:** the unavailable iPhone mic/camera during tethered QA was attributable to **iPhone Mirroring taking control of camera and microphone**, not a bug in UhWhat. **Close that issue as external**; stop carrying it as a blocker. A future ordinary direct iPhone capture QA, if needed, should be tested with Mirroring disabled.
- **Usability observation (not tested nor changed):** this diagnostics screen currently displays English labels even with Russian app context. Treat RU localization as a separate polish backlog, not as a failed Watch queue/recording test.

## Stage 5 — RU diagnostics localization and separate English/retry QA (2026-10-17)

- [x] Fixed previously hard-coded English-only Sync diagnostics strings with CaptureBrand.text(ru,en) in existing production-source view; this respects the established app language without changing data, queue code, Speech or Watch capture.
- [x] New independent UI tests for **Russian and English** navigation to Diagnostics and label rendering: **2 passed, 0 failures** on iPhone Duo Simulator, Xcode 27.1. Log builds/what-p1p2-l10n-ui-20261017/diagnostics-ui.log on ArvectumSSD.
- [x] Built **signed QA 1.0.2 (10)** with unchanged isolated .qa bundle identifiers and locally verified strict signatures of all four components. Physical iPhone 13 and Apple Watch SE updated in place; no uninstall.
- [x] Before upgrade backed up 21 files from iPhone QA Application Support and Watch outbound queue (0 pending), to builds/what-p1p2-localized-qa10-20261017/device-backup/. After upgrade rechecked **21/21 same paths/sizes** and Watch outbound pending still 0. Existing recordings and production app untouched. File sizes alone are not cryptographic proof of all content.
- [x] **Owner physical RU localization acceptance PASS, QA10:** on existing iPhone QA10 go to «Мои записи» → «…» → «Диагностика синхронизации»; heading and labels should now be Russian, including «В очереди на часах». Do NOT claim passed until observed.
- [x] **Owner physical EN auto-transcription PASS, QA10:** first set «Язык распознавания» → «English» in iPhone QA10 before recording, then record a NEW short non-sensitive English note on **Watch QA10** (example: The blue lighthouse is next to seven green apples.). On iPhone QA10 check text appears automatically and is intelligible. This validates real English on-device Speech using a Watch microphone without invoking iPhone Mirroring.
- [x] **Owner physical retry PASS, QA10:** on **only that new English test note**, use «…» → «Повторить расшифровку», read confirmation that existing text will be replaced and original audio preserved; confirm, wait for result, play original audio. Capture any failure/no-result exactly; original audio must survive even if Speech fails.
- [x] **Restore speech locale to «Русский» (ru-RU) after EN test DONE** so later incoming Watch notes are recognized in Russian automatically. Automatic recognition remains the default. Do not touch previously manually corrected Russian «бирюзовый маяк» QA note.
- [ ] Optional permission-denied/cancel path can be inspected separately later; do not revoke user permissions just to force a test unless coordinated.

Release remains blocked pending owner scope agreement, remaining planned work and a fresh production archive (existing IPA predates branded widget/localization).

## Stage 6 — English Speech physical PASS, diagnostics navigation & app language bugs (2026-10-17)

**Owner report on physical iPhone QA10 and Watch QA10:**
- **PASS** Russian diagnostics labels appeared correctly.
- **BUG** Sync diagnostics modal lacked a Back/Done button, leaving the owner unable to return normally to the library.
- **BUG** Changing Speech locale to English left iPhone UI in Russian; owner explicitly requested linked UI and recognition language.
- **PASS** English locale chosen manually, Watch voice note automatically transcribed into English without error: The blue lighthouse is next to seven green apples.
- **PASS** Owner used existing retry/replace transcription for this *separate* English test note, resulting in the same correct text, and then restored Speech locale to Russian. The previous corrected Russian QA note was untouched.
- Audio integrity after this retry was not separately verbally confirmed.

**Implemented in production-source branch and confirmed by simulator:**
- SyncDiagnosticsView: modal dismissal via localized Done/Готово button. No storage changes.
- CaptureBrand + PhoneStore: persisted Speech locale becomes a single source of RU/EN interface + recognition language on iPhone. Both languages update in the active screen without killing the app; persisted locale survives relaunch and existing locale values survive upgrades.
- ContentView is re-created as a view after locale switch, but PhoneStore remains alive and recordings are unchanged. SwiftUI locale environment value applied for formatting.
- Español Speech option remains supported, but full Spanish interface is not localized. Menu explicitly labels Spanish Speech as using the English UI. Full es-ES interface is separate backlog.
- **3/3 simulator UI tests PASS, 0 failures:** RU/EN diagnostics close-to-library, interface switches RU -> EN -> RU with the Speech picker, persists through normal relaunch. Log under builds/what-locale-nav-regression-20261017/ui-test-v2.log on ArvectumSSD. Earlier simulator test failure was an incorrect test locator for a native SwiftUI Picker flattened inside Menu; test fixed after reading accessibility hierarchy.
- **Signed isolated iPhone QA11** installed in-place on 2026-10-17; phone QA 1.0.2 (11). 22/22 private QA Application Support files read back with matching SHA-256 byte-for-byte before and after. No existing notes touched. Watch QA10 not explicitly updated due intermittent CoreDevice connection.
- **Physical QA11 acceptance PASS (owner, 2026-10-17):** owner replied «1 - ок, 2 - ок, 3 - ок» to exactly the prescribed steps: Done returns to list; setting English changes interface immediately; returning Русский restores Russian UI and existing recordings.
- Automatic RU/EN transcription remains the default.
- **No production IPA rebuilt, no App Store upload/review.**

## Final complete local Xcode regression after persistent-language test correction (2026-10-17)

- **PASS:** Xcode 27.1 iPhone Duo Simulator full WhatIOS scheme: **63 unit/integration tests, 0 failures, 3 skipped; 5 UI tests, 0 failures; TEST SUCCEEDED**.
- Complete log on Mac mini ArvectumSSD: builds/what-ui-language-full-regression-20261017/all-tests-v2.log.
- The first full test run exposed a precondition problem in a UI test: it assumed simulator AppleLanguages overrides a user-persisted Speech/UI language. After the product correctly persisted a chosen language, English diagnostics test could start in Russian. The test now explicitly selects the desired locale through the UI before assertions. No product change was needed to address that test state dependence.
- **Physical QA11 PASS:** owner confirmed Done/back, English/Russian live UI switching and original notes intact («1 - ок, 2 - ок, 3 - ок»). 22/22 QA storage files were separately verified byte-identical after installation.

## Stage 7 — completed hardware acceptance QA11 (2026-10-17)

Owner explicitly confirmed all three steps with «1 - ок, 2 - ок, 3 - ок»:
1. [x] Diagnostics opens and «Готово» dismisses it back to «Мои записи».
2. [x] Selecting English immediately switches the iPhone UI into English (the same preference controls Speech locale).
3. [x] Selecting Русский switches the UI back; existing recordings remain.

**Closed:** diagnostics navigation and mismatched RU/EN iPhone interface/recognition setting. **Not implied:** Spanish UI completeness, denied Speech permission, cancellation race tests, force-quit audio reliability, absolute queue safety under any failure. Release remains on hold until owner authorizes scope.
