# What? — P4b iPhone capture and home widget (2026-10-13)

## Shipped code (build 12)
- Add plus toolbar action on iPhone. Opens native capture with visible microphone recording state, elapsed time, Stop and save, and Discard.
- Only request microphone permission when capture is initiated. A dismissal during permission flow cancels the pending start.
- Source audio is AAC M4A at 16 kHz mono, persisted into the same recording repository as Watch audio, with original UUID, creation time and duration.
- Staging is in local Application Support/What/PhoneCaptures. Failed repository writes retain original audio and manifest for recovery; completed playable recordings are recovered on next launch. Discard explicitly removes current staging note.
- If Apple Speech permission was already granted, new iPhone and Watch recordings are transcribed on-device automatically, without overwriting existing manual transcripts. Otherwise the user may start batch recognition from Smart Search.
- Separate WidgetKit iPhone extension offers Home Screen small/medium and rectangular Lock Screen variants. Static what://record link opens the app in foreground and starts capture there. It cannot use the microphone from the widget extension or start recording while the app remains closed.
- Watch app unchanged in build 12. No cloud storage or unconsented model downloads.

## Automated acceptance
- [x] Signed iPhone+WidgetKit package compiles; widget .appex embedded and app registers what URL scheme.
- [x] Simulator unit tests for rare-word retrieval, same local repo intake, semantic search regression.
- [x] All original 14 recordings, 14 audio files, 6 transcripts byte-identical after iPhone upgrade.
- [ ] Physical iPhone: tap plus, approve microphone, record, Stop and save, then play note and check transcript.
- [ ] Add What? widget on iPhone Home Screen; tap and confirm capture opens. First deep-link open may require iOS confirmation.
- [ ] Test capture and indexing offline, multiple recordings, and interruptions.
- [ ] Batch transcribe older unindexed audio; confirm index updates without changing existing manual text.


## iPhone microphone regression and fix (build 13)

- First physical iPhone capture at 14:56 on 2026-10-13: stored metadata duration 6.261625 s but real AAC duration 0.060000 s, 12 audio bytes (three packets). Missing audio cannot be recovered.
- Retained all records and backed up data under ArvectumSSD/backups/what-phone-transcription-failure-20261013.
- Confirmed bug category: recorder clock was trusted as decoded audio duration. Why audio capture stopped (routing/interruptions/hardware) is not demonstrable from original data.
- Change AVAudioSession to microphone-only mode and use active hardware sample rate; verify input availability. Handle session interruption and unexpected recorder stop. Stop playback and recognition before capturing to avoid shared audio session conflicts.
- On Stop, finalize M4A and validate decoded duration using AVAudioPlayer: at least 0.5 s and 65% of elapsed wall time. Persist measured decoded duration instead of recorder clock. On failure, keep recovery copy and warn user.
- Recover staged files only when they also pass persisted elapsed-time validation. Older broken notes show Audio incomplete; no automatic deletion.
- [x] Simulator unit tests reject real-world failure input 0.06 s / 6.261625 s and accept normal 6.18 s / 6.26 s.
- [x] Installed iPhone build 13; all pre-existing 15 recordings, 15 .m4a files and 7 transcripts byte-identical after installation (2026-10-13).
- [ ] Record 5-10 seconds on iPhone, save, listen, and verify successful transcription.
