# Photo & PDF Size 1.0.0 — Verified pre-release QA

**Date:** 2026-10-10
**Branch:** `release/photo-pdf-1.0.0` (local)
**App:** `ru.arvectum.tools.tosize` / Apple ID `6816346084`
**Status:** TESTED LOCALLY, **NOT UPLOADED / NOT SUBMITTED / NOT PUBLISHED**.

## Build facts

- Xcode: **27.0**; XcodeGen project regeneration succeeded.
- Test-build: `xcodebuild ... build-for-testing` succeeded with code signing disabled.
- Device simulation: **iPhone 17 Pro, iOS 26.5** (`5018BC1D-42F5-4A96-9B27-A0825DD12879`).
- Full simulator run: `xcodebuild ... test-without-building` — **TEST EXECUTE SUCCEEDED**.
- **27 unit tests passed** (`AppModelTests`, `ImageEngineTests`, `PDFEngineTests`).
- **5 independent UI tests passed** (`WorkflowUITests` ×4 + `LayoutRegressionUITests` ×1). Layout covered RU/EN light/dark and native ad slot.
- **5 device-only Files integration UI tests skipped on simulator** by explicit design; no assertion or functional failures in final full simulator run.
- PDF orientation regression: passed. PDF compression target and read-back page count: passed.
- Local JPEG/PDF file import on simulator test host: passed.
- Asynchronous completion-token cancellation and reset defaults: passed.
- Native ad cached-content SwiftUI binding deferred to next UI cycle. No state-update warning in final test log.
- iOS **Release / iphoneos** unsigned build **SUCCEEDED**; inspected Info.plist: `CFBundleShortVersionString = 1.0.0`, `CFBundleVersion = 11`, bundle ID unchanged; QA debug-only fixture flag absent from Release executable.
- Build product staged locally at `/tmp/arvectum-photo-10-release/Build/Products/Release-iphoneos/PhotoPodRazmer.app`, **not an uploadable signed archive**.

## Store presentation verification

- 20 App Store locale drafts: name/subtitle (≤30), promotional (≤170), keywords (≤100 UTF-8 bytes), description (≤4,000), localized release notes checked.
- **80 screenshots** validated (4 per locale, all 1320 × 2868).
- 4th PDF image sourced from a real running simulator session using a deterministic 3-page PDF. Screenshot source cropped to exclude advertising creative.
- RU/EN source UI available. Other marketing locales have translated overlay copy **over English app UI**; not a claim that the app itself is fully translated.
- Multilingual website SEO is staged in a separate unmerged local branch, no deployment.

## Remaining release blockers / operator handoff

1. **Physical iPhone test** with the real Photos and Files providers: select, compress, export/save, share, exact pixel dimensions, document crops/print sheets, PDF pages/text, orientation, error handling, dark/light mode.
2. **Advertising and privacy review** on physical iPhone: both consent paths, ATT if triggered, native/banner fit, updated privacy manifest, store privacy answers.
3. **Localization sign-off**: current app UI is Russian and English. Decide whether to launch additional language-specific store listings with English UI or ship localized UI first; obtain human proofreading for priority markets.
4. **Signed build/archive:** recheck highest App Store Connect build number before signing/uploading; 11 is reserved **only in this local release candidate**.
5. **Explicit approval required** before uploading 1.0.0, editing live metadata, submitting App Review, or publishing staged SEO pages.

No App Store Connect writes, TestFlight upload, GitHub push, merge to `main`, production deployment or release occurred during this work.
