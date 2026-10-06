# What?

What? is a local-first voice memory app for Apple Watch + iPhone.

Core capture contract:

> Tap on the watch face → speak → stop → the recording is durably saved on Apple Watch → transferred to iPhone → deleted from the Watch transfer queue only after an ACK from the iPhone.

## Current status

P0 Reliable Capture is implemented in code and compiles on Xcode 27. Physical Apple Watch reliability testing is still required before P0 is considered done.

Implemented:
- native iPhone + watchOS targets;
- WidgetKit watch-face complication entry point;
- microphone capture with timer, stop control and haptics;
- durable on-Watch outbound queue;
- WatchConnectivity file transfer;
- iPhone durable storage before ACK;
- UUID-based idempotent receive path;
- ACK-driven deletion from Watch;
- minimal iPhone recording list + audio playback;
- unit test for duplicate-delivery deduplication.

## Build

Requirements: Xcode 27 and XcodeGen 2.46+.

```bash
cd apps/what/ios
xcodegen generate

xcodebuild -project What.xcodeproj -scheme WhatWatch \
  -destination 'generic/platform=watchOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project What.xcodeproj -scheme WhatIOS \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

See [ROADMAP.md](ROADMAP.md) for the product roadmap and acceptance-test gate.
