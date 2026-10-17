# Ухват — физическая приёмка P1/P2 на iPhone, 17.10.2026

**State: AUTOTESTS PASS; PHYSICAL QA PENDING. No production installation or App Store upload.**

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

- [ ] **From Apple Watch QA** complication record the fixed test phrase clearly for 8–15 seconds; tap Stop. On paired iPhone «Ухват QA» verify the note arrives under «Мои записи» and plays. This is a Watch-sourced acceptance note, not proof that the iPhone microphone capture works.
- [ ] On iPhone open «Мои записи» -> «…» -> **Язык распознавания** -> «Русский» if needed (ru-RU).
- [ ] On that Watch-delivered note in iPhone QA tap **«Расшифровать»** (or inspect the automatically generated transcript if Speech permission had previously been granted). Grant Speech permission on first request if comfortable; do not force permission if user declines.
- [ ] Confirm transcript is present and includes at least recognisable «бирюзовый», «маяк» or «зелёный чай». Record exact spelling errors as a product finding, not as fabricated PASS; microphone/Voice text recognition can't be automated by local Swift unit tests.
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
