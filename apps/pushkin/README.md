# PUSHKIN

iOS utility for capturing and organizing notification history with the smallest practical onboarding burden.

Runtime architecture: fully local. PUSHKIN has no account system, backend, cloud sync, runtime App Store lookup, or server-side notification processing. The supported-app catalog and signed Shortcuts packages ship inside the app; missing apps use a guided manual Shortcuts path.

## Status

Active feasibility/product development.

## Build

Requirements: Xcode 26.x and XcodeGen.

```bash
cd ios
xcodegen generate
xcodebuild -project ArvectumNotifyIOS.xcodeproj -scheme ArvectumNotify \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

See [ROADMAP.md](ROADMAP.md) for the canonical product roadmap and [docs/](docs/) for feasibility notes and architecture alternatives.
