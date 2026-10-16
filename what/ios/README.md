# What? iOS + watchOS

Native local-first implementation of the What? voice-memory capture path.

## Build

Requirements: Xcode 27 and XcodeGen 2.46+.

```bash
cd what/ios
xcodegen generate
xcodebuild -project What.xcodeproj -scheme WhatWatch \
  -destination 'generic/platform=watchOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project What.xcodeproj -scheme WhatIOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## P0 reliability contract

1. Watch records into its own Documents/WhatOutbound directory.
2. Queue metadata is persisted before transfer is scheduled.
3. WatchConnectivity transfers the audio opportunistically.
4. iPhone copies the temporary incoming file into Application Support/What/Audio and atomically persists its index.
5. Only after that succeeds does iPhone send a durable ACK.
6. Watch deletes its local copy only after receiving that ACK.
7. Duplicate transfers are deduplicated by the stable recording UUID.


## Multimodal capture (feature/what-multimodal-20261016)

- Apple Watch: unchanged one-tap **audio-only** complication.
- iPhone/iPad: existing large round button, **tap for immediate audio**, **hold >=0.5s for video**; separate small **+** for a typed note. There is no three-way mode chooser.
- Typed drafts autosave atomically while editing; camera videos begin capture when permission is granted, retain an original .mov locally, display preview/poster, and can be shared/deleted.
- LocalNoteRepository stores new text/video in What/local-notes.json with UUID-based videos under What/Videos; the Watch recordings.json, ACK and deletion tombstones remain untouched. UnifiedInbox merges both ledgers for display, dates, filters, search and archive.
- iPad is in the supported target family (iOS 17+). No iPhone/iPad cloud sync is included.
- Development-only simulator validation: iPhone/iPad build, 64 iOS unit tests (0 failures, 3 skips), iPhone and iPad UI text autosave/inbox tests, iPad home/library navigation and long-press-to-video routing (including a no-camera simulator alert) passed. **Do not ship** without testing camera audio, interruptions, actual hold gesture, offline Watch ACK, iPad layout and video recovery on real devices. Do not install a development build over the user's existing app without a verified data backup.


### Back / front camera switch (feature branch; not yet installed)

The active video recording screen now includes a camera-rotate button. During recording, a camera switch stops the current MOV segment, reconfigures the AVFoundation video input without replacing the microphone input, and resumes with the other camera. Stop/Discard override a pending switch. On Save, segments are exported into one playable local video with their source orientations and audio. Original segments remain untouched until the repository successfully imports the merged video. A single camera segment is imported without transcoding. No data is transmitted to a server. The simulator unit tests use tiny synthetic AV movies (red/back and blue/front) to verify the actual output's frames, combined duration and audio track; actual camera behavior still requires physical iPhone/iPad QA.


### Crash-safe video recovery (M7a, simulator-verified)

Each new recording gets a durable UUID and an atomic session manifest in Application Support/What/VideoCaptures/UUID/session.json. Camera input changes write ordered segment files. Stop/Save imports the final original/merged media under this same UUID, then deletes the staging folder only after a confirmed repository commit. A failed import preserves the original files. Explicit Discard is durably marked before deleting; discarded clips will not reappear as notes after a crash.

On application launch, VideoCaptureRecovery inspects interrupted sessions. Fully decodable clips become a single restored video note; the original files remain untouched if some segments are damaged. Repeated launch cannot create duplicate notes, and missing indexed media is repairable. A non-blocking banner reports recovered notes and warns when any damaged segments remain. Eight additional recovery tests use synthetic AVFoundation movie fixtures. iPhone camera/microphone real hardware, forced termination and out-of-space still require physical QA before App Store submission. Existing Watch audio/ACK files are not modified.


### Adaptive iPad layout (M5a)

The quick-capture home now adapts to shorter/narrower scenes with vertical scrolling without changing its main tap-to-audio/hold-to-video gesture. Library, text-editor and video-preview content use readable maximum widths on a large iPad. The video capture view scrolls to keep Stop/Save and camera rotation accessible when available height is low. Landscape iPad simulator UI tests cover home capture control, + text editor and library/back navigation. Physical Split View resize, very large accessibility type and camera acceptance remain pending.


### Per-note reminders (P6a, local only, opt-in)

From an audio, typed-text or video entry in the Inbox, choose Remind → In 1/2/3 hours. This requests local-notification permission only following an explicit user action. The same stable UUID reschedules rather than duplicating notifications; users can cancel or mark reviewed. Deleting the original note cancels its alert. Notification text is always generic, never the private note body or transcript. Notification taps carry the local UUID and show the matching entry in the Inbox, including archived notes, with quick Open/Reviewed actions. Review reminders are stored atomically in Application Support/What/review-reminders.json and pending system notifications are reconciled after relaunch without asking permission automatically. No network, no ChickMark dependency, no automatic reminders. Tests use an injected local scheduler rather than sending real notifications; physical tap-through testing is still pending.
