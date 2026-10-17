# Ухват — физическая приёмка P1/P2 на iPhone, 17.10.2026

**State: AUTOTESTS PASS; REAL iPHONE AUTO-TRANSCRIPTION PASS; correction/search/archive physical QA pending. No production installation or App Store upload.**

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

- Owner reports that the iPhone microphone does not work while iPhone is connected to Mac mini for QA. Do not require repeated physical disconnect/reconnect merely to exercise Speech, correction, library, search and archive.
- **Primary physical acceptance input is Watch QA (9)**, already independently verified for one-tap recording and transfer. Dictate the fixed Russian test phrase on Apple Watch, tap Stop, wait for it to arrive on iPhone QA (9), then run Apple Speech and P1/P2 iPhone flows on that incoming note.
- This validates real Watch microphone -> durable transfer -> iPhone stored audio -> actual **iPhone-side** SFSpeechRecognizer -> text persistence/correction -> search/archive. Differences in acoustic microphone quality can change recognition accuracy, but do not invalidate processing/UX acceptance.
- **Separate unresolved iPhone direct microphone QA**: the on-iPhone microphone/audio capture path is NOT verified by Watch-sourced notes; diagnose the Mac mini connection/input-route issue separately and run one dedicated, minimally disruptive round of iPhone-native capture QA. Do not claim a software bug or audio-route root cause until reproduced without the tether/connection.
- All destructive tests remain isolated to a new synthetic QA note. Production storage never touched.

## Stage 1 — real iPhone transcription / original audio (OWNER)

- [x] **Physical QA9 Watch-sourced note delivered and transcribed on iPhone (2026-10-17):** owner recorded test phrase on Watch and reported automatic iPhone Speech transcription. Playback of this particular note was not explicitly confirmed; direct iPhone microphone not tested.
- [x] **Russian-language recognition confirmed by real output:** intelligible Russian transcript received. Manual locale-switch UI has not been explicitly exercised.
- [x] **Auto-transcription PASS:** user confirmed «Расшифровка у нас автоматическая (это хорошо, так и оставим)». Preserve automatic recognition as default. Manual transcription/retry is a fallback, not mandatory.
- [x] **Real Russian transcript exists, semantic content preserved.** Exact user result: «Проверка охвата бирюзовой маяк стоит на полке номер семь напомнить про зелёный чай в субботу». Two errors against target: «Ухвата» -> «охвата» and «Бирюзовый» -> «бирюзовой»; punctuation omitted. Keywords «маяк», «номер семь», «зелёный чай» and «в субботу» survived. This is a quality observation, not a guarantee.
- [ ] Re-play the original note; Speech/transcript is an accessory and must not alter recorded audio.

## Stage 2 — correction and search (OWNER, after Stage 1)

- [ ] Tap «Править текст» (or «…» -> «Добавить текст»), append a harmless unique marker «контрольный маяк девятнадцать», tap «Сохранить».
- [ ] Leave «Ухват QA» (ordinary app switch), return and verify text is still edited.
- [ ] In Inbox search field enter «маяк» and confirm this note appears; enter unique marker and verify it appears. Test no-results search.
- [ ] Check recording playback unchanged after editing.

## Stage 3 — archive and non-destructive navigation (OWNER)

- [ ] On **only this test recording** tap «…» -> «В архив». Verify absent from «Входящие» and present in «Архив».
- [ ] Return to Inbox, switch back to Archive, verify text/audio still present and search with marker works.
- [ ] Tap «…» -> «Вернуть во входящие» for **only this test recording**. Verify it is again in Inbox and still playable.
- [ ] Open «…» -> «Диагностика синхронизации» and inspect pending count. Do not infer «zero» from lack of visible spinner.
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
- **UNCONFIRMED:** playback of this specific new note, manually corrected text persistence/search, archive/restore, permission denial, direct iPhone microphone. Do not check these based solely on the transcript.
- Next user checkpoint: select only this new QA note, tap «Править текст», correct «охвата» -> «Ухвата» and «бирюзовой» -> «Бирюзовый», append «контрольный маяк девятнадцать», save. Leave and reopen app to verify persistence, then search for the marker, and replay the same audio. Do not alter older notes.
