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
- [x] Final physical-device UX review after design changes (History / Apps / Settings / Add App / Manual Add all rendered on iPhone 13, iOS 27.0.1).
- [ ] Final airplane-mode/offline smoke test.

## Privacy

- [x] Privacy manifest added.
- [x] No analytics SDK.
- [x] No ad SDK.
- [x] No tracking.
- [x] Privacy policy URL prepared.
- [x] Archive PrivacyInfo inspected: no tracking/collection; UserDefaults reason `CA92.1` only.
- [x] App Store privacy answer published: **Data Not Collected**.

## Store assets

- [x] English listing draft.
- [x] Russian listing draft.
- [x] App Review notes draft.
- [x] App Store Connect app record (`PUSHKIN by Arvectum`, Apple ID `6817847111`).
- [x] Final 6.9-inch iPhone screenshots (1320×2868): History, Apps & Setup, Privacy/Settings.
- [ ] Optional smaller-device screenshot set if App Store Connect requests it.
- [ ] Physical-device App Review demo recording — **required by Apple on 1 Oct 2026 under Guideline 2.1 Information Needed**. Shot list prepared in `APP_REVIEW_VIDEO_SHOTLIST.md`.
- [x] Support URL and live privacy-policy URL verified.

## Build and submission

- [x] Marketing version set to 1.0.0 (build 1).
- [x] Clean Release build from final source.
- [x] Archive for generic iOS device (`/tmp/PUSHKIN-1.0.0.xcarchive`).
- [x] Archive inspected: bundle ID/version/build correct, PrivacyInfo present, no runtime endpoint strings.
- [x] Build `1.0.0 (1)` present in App Store Connect.
- [x] App Store processing completed.
- [x] Age rating and content-rights answers completed (4+; necessary rights declared).
- [x] Final build attached to iOS version 1.0.
- [x] Review notes present in the version metadata.
- [x] Submit to App Review.
- [x] Submission accepted by App Store Connect on 30 Sep 2026 at 19:58 local time.
- [ ] 1 Oct 2026: status **Rejected — Guideline 2.1 Information Needed**. Apple requests a physical-device screen recording and six factual disclosures because the developer account has limited review history. Draft response is ready in `APP_REVIEW_RESPONSE_2026-10-01.md`; do not reply/resubmit until the recording is attached and the product owner approves.

## Post-launch 1.1

- Advertising integration.
- Reassess privacy labels after ad SDK is added.
- Russian in-app localization if 1.0 ships English-first.
- User-requested catalog additions + bug fixes.
