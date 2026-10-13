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


## Live microphone buffer capture (build 14)

- Build 13 physical retest still failed. Diagnostic AAC file in PhoneCaptures had 0.020000 seconds/12 bytes/three packets after 9.1557599 seconds elapsed; the active microphone session was not actually delivering encoded audio.
- All existing notes and failed capture staging were backed up to ArvectumSSD/backups/what-mic-failure-after-build13-20261013; do not remove until user explicitly authorizes cleanup.
- Capture path switched from AVAudioRecorder to AVAudioEngine inputNode.installTap at device-native sample rate; tap buffers are written with AVAudioFile directly to AAC M4A. A frame counter separately tracks real captured audio time; filename header is finalized on file close.
- iPhone capture UI now says Connecting to microphone, Microphone connected, Microphone is capturing sound, or No microphone data yet (after 2 seconds). This status uses actual input buffers, not elapsed time.
- Saving requires enough real input frames and independently measured playable AAC duration. Failed captures retain staging/manifest; never silently appear in Inbox.
- Regression tests for synthetic microphone frame -> playable M4A and zero-frame rejection added and compile. Native Mac AAC codec test produced playable M4A of 1.066 seconds from 51200 source frames.
- iOS simulator xcodebuild test run hung without test logs after compilation; only build-for-testing completed successfully. Repeat full tests with healthy simulator.
- [x] Physical build 14 installed with byte-for-byte data integrity check: all 15 recordings, 15 audio files, 7 transcripts, and staged captures preserved (2026-10-13).
- [ ] Physical iPhone mic shows live signal, saves 5-10 seconds fully, original audio plays and transcribes.
- [ ] If still missing buffers, check iOS Voice Memos microphone and whether iPhone Mirroring / Continuity Camera holds audio input. Do not guess from current evidence.


## iPhone AVAudioEngine zero-input regression (build 15)

- Physical build 14 accepted a 6.600000-second AAC recording but Apple-decoded samples were all exactly zero: peak = 0, RMS = 0, nonzero count = 0. Thus frame counters/duration alone did not imply microphone input was carrying actual sound.
- Apple-decoded older voice recordings have peak ≈0.41 and RMS ≈0.03–0.05; recognition quality was not at fault.
- Route setup now prefers built-in iPhone microphone from AVAudioSession.availableInputs and shows AVAudioSession.currentRoute.inputs[].portName on screen. This may avoid an unintended Bluetooth/USB/Continuity input; success must be verified physically, not assumed.
- MicrophoneCapturePipeline tracks peak amplitude and count of samples above 0.001. Saving rejects zero/no-signal samples with a specific capture error, instead of sending silence to speech recognition.
- PhoneCaptureValidation.validateFileHasSound reads the decoded M4A as Float32 PCM and checks for audible samples; it is also used by crash recovery. No silent capture will be auto-imported into Inbox.
- [x] Build and unit-test targets compiled.
- [x] Standalone Mac regression using source code + actual backed-up iPhone AAC: physical silent note rejected, original voice accepted, synthetic 1+ seconds of PCM captured and decoded AAC accepted.
- [x] Build 15 installed on physical iPhone 13; 16 recordings, 16 audio files, 7 transcripts and all old app-support files byte-identical to pre-upgrade backup (2026-10-13).
- [ ] Physical iPhone test: show selected input, speak, confirm Microphone is capturing sound, save and play; check transcription.
- [ ] If even built-in input is all zeros, verify Apple Voice Memos can record on the same iPhone without an active iPhone Mirroring/Continuity Camera session. This isolates OS-level routing from What? audio code.

## Root cause recovery observation (physical, 2026-10-13)

- On the same physical iPhone, even the stock Voice Memos app recorded silence while iPhone Mirroring had been active on the Mac mini. This points to an iOS microphone route/system-state issue rather than an app-only speech model failure.
- User closed iPhone Mirroring: the microphone did **not** recover immediately.
- User rebooted iPhone afterward: Voice Memos and What? both recorded audible speech again.
- Causality remains a strong hypothesis, not proven exclusively by the close/reboot sequence. Avoid claiming a particular private Apple subsystem caused this.
- Build 15 retains two safety checks (nonzero signal in live buffers and nonzero decoded AAC before import) and a visible input route.
- Old recordings containing digital zeroes can no longer be sent to Speech recognition; batch conversion skips them with an explanatory error, without deleting them.
- Follow-up: confirm audio quality and auto-transcription of the first post-reboot recording from a new on-device backup, and widget capture through the home/lock-screen shortcut.


## Build 16: recognize only audio with a signal
- Speech recognition validates decoded audio content, not merely playback duration, before submitting a stored M4A file. Empty digital-zero legacy recordings are skipped in batch mode without deletion or mutation.
- iPhone microphone returned to normal after user quit iPhone Mirroring and rebooted iPhone; both standard Voice Memos and What? captured audible speech. Do not label restart as a proven exclusive root cause.
- [x] Full iOS simulator test suite passed using non-parallel test-without-building after rebuilding the test bundle.
- [ ] Physically install build 16 when iPhone is connected again.
- [ ] Inspect latest post-restart M4A and actual transcription before marking recognition P4b acceptance complete.


## Physical microphone recovery confirmed; build 16 installed (2026-10-13)

- After stopping iPhone Mirroring and restarting the iPhone, Voice Memos and What? both successfully recorded audible audio.
- Physical What? capture verified from backup, UUID 56CC692E-743B-4308-AB95-87BA91168058: 4.500 seconds, 48 kHz mono AAC, peak amplitude ≈0.502, RMS ≈0.071, and nonzero PCM samples. User transcript persisted (44 characters). Original spoken content is not copied into this technical record.
- Competing source 6.6-second silent file had peak/RMS/nonzero count all zero. Regression protection in build 16 refuses to submit that file to Speech.
- Signed physical iPhone build 16 installed in place, and all pre-upgrade 17 recording records, 17 M4A files, 8 transcripts, and other existing app-support files were byte-for-byte identical post install.
- [x] Record direct from physical iPhone, persist playable real-signal audio, and automatically generate saved on-device transcript.
- [x] Backward compatibility and data integrity verified.
- [ ] Install/use What? home-screen widget physically, tap to open capture.
- [ ] Test offline bulk transcription and semantic search (including old rare-word sample with text available); avoid assuming physical success from simulator tests.


## Widget deep-link acceptance (physical iPhone, 2026-10-13)

- [x] What? home-screen widget is discoverable and can be installed by the user.
- [x] A tap on the widget opens the correct in-app New recording capture screen directly; URL routing works.
- [ ] The particular test's audio was not saved successfully while iPhone was connected to Mac mini. User attributes it to a previously observed system audio issue. Earlier confirmed recovery required **both** quitting iPhone Mirroring and rebooting iPhone, so a wired USB connection alone is **not proven** to cause microphone failure. Do not dismiss failed captures merely because a cable was connected.
- [ ] Retest capture from the widget when the built-in microphone is verified by Voice Memos, with iPhone Mirroring fully quit and any audio route conflict resolved. Confirm audible AAC and saved transcript.
- [ ] Check microphone route shown by What? and capture a fresh diagnostic copy if widget-launched recording still fails.
