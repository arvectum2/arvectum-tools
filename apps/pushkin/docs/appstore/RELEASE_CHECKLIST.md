# PUSHKIN 1.0 — Release checklist

## Product

- [x] Core notification capture proven on physical iPhone.
- [x] Fully local runtime; no backend/account/runtime network lookup.
- [x] Bundled TOP-1000 catalog and local one-app micro-packages.
- [x] Offline manual fallback for missing apps.
- [x] Automatic coverage verification.
- [x] Chronological history.
- [x] Full-text search across app/title/subtitle/body.
- [x] Copy / share / delete actions.
- [x] Consumer Settings screen and local-history deletion.
- [x] Phase-0 diagnostics removed from release navigation.
- [x] Arvectum visual shell applied.
- [x] Light and Dark Mode visually checked on iOS 27 simulator.
- [x] App icon present.
- [x] Advertising excluded from 1.0.
- [ ] Final physical-device UX review after design changes.
- [ ] Final airplane-mode/offline smoke test.

## Privacy

- [x] Privacy manifest added.
- [x] No analytics SDK.
- [x] No ad SDK.
- [x] No tracking.
- [x] Privacy policy URL prepared.
- [x] Archive PrivacyInfo inspected: no tracking/collection; UserDefaults reason `CA92.1` only.
- [ ] Publish App Store privacy answer: no data collected, once the App Store Connect record exists.

## Store assets

- [x] English listing draft.
- [x] Russian listing draft.
- [x] App Review notes draft.
- [ ] App Store Connect app record.
- [x] Final 6.9-inch iPhone screenshots (1320×2868): History, Apps & Setup, Privacy/Settings.
- [ ] Optional smaller-device screenshot set if App Store Connect requests it.
- [ ] Physical-device App Review demo recording.
- [x] Support URL and live privacy-policy URL verified.

## Build and submission

- [x] Marketing version set to 1.0.0 (build 1).
- [x] Clean Release build from final source.
- [x] Archive for generic iOS device (`/tmp/PUSHKIN-1.0.0.xcarchive`).
- [x] Archive inspected: bundle ID/version/build correct, PrivacyInfo present, no runtime endpoint strings.
- [ ] Export App Store IPA / upload build — blocked until the App Store bundle ID/profile exists.
- [ ] Wait for processing.
- [ ] Complete age rating and content-rights answers.
- [ ] Attach final build to version 1.0.0.
- [ ] Add review notes and demo video.
- [ ] Submit to App Review.

### Current submission blocker

The local Release archive is ready, and an Apple Distribution identity for LLC ARVECTUM is installed. Export currently fails because `ru.arvectum.tools.notify` has no App Store Connect Bundle ID / App Store provisioning profile yet. API-key export also reports that the key lacks cloud-managed distribution-certificate permission, so the intended path is to create the explicit Bundle ID + App Store app record/profile, then export using the existing local Apple Distribution certificate.

## Post-launch 1.1

- Advertising integration.
- Reassess privacy labels after ad SDK is added.
- Russian in-app localization if 1.0 ships English-first.
- User-requested catalog additions + bug fixes.
