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
