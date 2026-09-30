# PUSHKIN

iOS utility for capturing and organizing notification history with the smallest practical onboarding burden.

## Status

Active feasibility/product development.

## Build

Requirements: Xcode 26.x and XcodeGen.

```bash
cd ios
xcodegen generate
xcodebuild -project ArvectumNotifyIOS.xcodeproj -scheme ArvectumNotify   -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'   CODE_SIGNING_ALLOWED=NO build
```

See [ROADMAP.md](ROADMAP.md) for the canonical product roadmap and [docs/](docs/) for feasibility notes and architecture alternatives.
