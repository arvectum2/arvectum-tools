# What? iOS + watchOS

Native local-first implementation of the What? voice-memory capture path.

## Build

Requirements: Xcode 27 and XcodeGen 2.46+.

```bash
cd apps/what/ios
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
