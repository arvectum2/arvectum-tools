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
