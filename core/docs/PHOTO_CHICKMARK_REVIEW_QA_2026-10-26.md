# 26 October 2026 — Photo/PDF + ChickMark UX review QA

Source branch: `feature/review-ux-photo-chickmark-20261026` (stacked after prior i18n PR). Execution **only through Arvectum Remote Cloud**, Mac mini Xcode 27.1, isolated iOS 27.0 iPhone 18 Pro Simulator, no RDC.

## Verified locally
- [x] Core locale/regression tests: **63/63 PASS**, iOS key/format parity **PASS** across all active source bundles, `git diff --check` PASS.
- [x] Photo/PDF Debug iOS Simulator build: **PASS**.
- [x] ChickMark Debug iOS Simulator build: **PASS**.
- [x] Photo/PDF targeted native XCTest: **3/3 PASS** — 2 unit tests covering Schengen/China/Canada size-presets plus 1 UI test opening advertising privacy disclosure.
- [x] ChickMark targeted native XCUITest: **5/5 PASS** — 2 tests covering first-run 3-page carousel, skip, one-time persistence; 3 in-feed ad/no-fill/AXXXL tests.
- [x] Real screen-only screenshot capture for Photo/PDF: no fake ad, no update overlay. China visa preset 354×472 pixels, PDF real **249 KB → 95 KB** on three pages.
- [x] 12 marketing screen drafts (4 × RU/en-US/en-GB) at **1320×2868 pixels**, deterministic screenshots + strong size/dimension messages. [Image hashes](../../photo-pdf-to-size/docs/aso/screenshot-review-manifest-2026-10-26.json).
- [x] 20 draft App Store metadata locales validated (title/subtitle/keywords byte limits and 4 screenshot headlines). **Not uploaded**.
- [x] Prior portfolio full 11-locale GitHub manual UI matrix **4/4 workflow jobs success**: https://github.com/arvectum2/arvectum-tools/actions/runs/40278441525 (parent branch, not this feature).
- [x] Real bundled SDK privacy manifest audit: own tracking=false, YandexMobileAds tracking=false, **AppMetrica AdSupport tracking=true** (device ID linked/tracking). Confirmed actual Swift no ATT prompt and location disabled; App Store privacy category cannot be called tracking-free from runtime switch alone.

## Accessibility regression: recorded failure and fix
- [x] Photo result VoiceOver speech smoke 2/2 PASS on iOS 27.0 Simulator (photo and PDF results).
- [x] System accessibility audit discovered a **too-small hit region** for the footer «Реклама и конфиденциальность»; the app was changed to a 44pt button. A follow-up audit exposed **text clipped** when the caption was forced onto one line. We removed one-line truncation, enabled text wrapping and retained the 44pt tap area.
- [ ] **Photo full system accessibility audit remains FAIL**: even after 44pt tappable footer and multiline copy, Xcode reports potential `Text clipped` under simulated larger Dynamic Type (both photo and PDF, including first-party-only isolation). Do not mark full accessibility acceptance as passed; requires a separate layout fix and full regression.
- [x] **VoiceOver FINAL 5/5 PASS** on a fresh isolated iPhone 18 Pro iOS 27.0 simulator: Photo/PDF 2/2 (photo/PDF result speech); ChickMark 3/3 (today speech, full core navigation, three-step onboarding speech). No failures, both .xcresult saved in `/Volumes/ArvectumSSD/Arvectum/qa/voiceover-final-20261026/`.

- [x] **Mac mini VoiceOver is OFF after testing**: verified via `NSWorkspace.shared.isVoiceOverEnabled == false`, the actual System Settings → Accessibility → VoiceOver switch is value 0, `com.apple.universalaccess voiceOverOnOffKey = 0`, no VoiceOver process; temporary simulator shut down/deleted. No voice/screen accessibility settings left toggled on.

## Implementation summary
**Photo/PDF**: no startup personalised-ad consent/ATT; `YandexAds.setUserConsent(false)` and `setLocationTracking(false)`; read-only honest disclosure in footer. New document size presets: Schengen 35×45 mm, China digital 354×472 px 40–120 KB, Canada 50×70 mm; government approval is NOT guaranteed. Marketing assets use real app screen captures and local file operations only.

**ChickMark**: removed the native ad from fixed footer; it is now **at the bottom of the scrolling task list**, preserving complete sponsored disclosure/SDK assets without wasting the main viewport. Native ad unit preserved, not misused as banner. First launch has 3-page swipe carousel, skip/next/start, no permission/login requests, persisted completion; existing users with habits do not get interrupted.

## Release gate — outstanding
- [ ] Updated commit PR CI after this targeted layout fix (older runs failed prior to fix).
- [x] Photo/PDF **native ad visibility regression re-run PASS**: tightened root/home inter-section spacing to preserve the 44pt tappable privacy footer; real iPhone 18 Pro iOS 27.0 XCUITest `testWorstCaseNativeNoScrollRUAndENLightDark` passed across **RU + EN / light + dark / three photo modes**. Evidence: `/Volumes/ArvectumSSD/Arvectum/qa/photo-layout-vo-followup-20261026/photo.xcresult`. Two older GitHub A5 runs were red before this fix; NEW PR CI must pass after push.
- [ ] **Physical iPhone + Watch acceptance**: `xcrun xctrace list devices` shows owner iPhone and Watch **offline** at the Mac mini, so their live privacy/permissions, real Yandex ad fill, VoiceOver and upgrade behavior could not be inspected. Never disturb personal HealthKit/Shortcuts records for QA.
- [ ] Native-language legal/UX review for consent and country-specific document requirement caveats.
- [ ] SDK/vendor privacy assessment and public policy alignment; if AppMetrica tracking remains, **do not** claim no tracking in App Store Nutrition Label.
- [ ] Real App Store screenshot/photo metadata preview sign-off; the first two screenshots reuse **previous-build** genuine result UI (outdated top-bar text) until re-captured with a fresh final version. Screenshot art is draft only.
- [ ] New version/build numbers, Release/archive/export/sign, fresh SHA-256, specific per-artifact approval for any ASC/TestFlight upload and separate live listing approval. No Apple upload/publication/metadata mutations in this work.

Raw evidence: `/Volumes/ArvectumSSD/Arvectum/qa/review-ux-native-20261026/{photo,chickmark}.{log,xcresult}`; builds `/Volumes/ArvectumSSD/Arvectum/qa/review-ux-20261026`; clean real captures `/Volumes/ArvectumSSD/Arvectum/qa/photo-store-review-20261026/`.
