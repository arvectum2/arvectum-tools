# App Store release checklist — iOS 0.5.0 (build 4)

## Simplicity gate

- [x] No new top-level mode beyond the existing three jobs.
- [x] Result screen hides the mode selector; switching jobs remains available only before processing, keeping the result screen compact.
- [x] Rare controls stay behind collapsed “Advanced / Дополнительно”; the common flow remains choose photo → choose target → process.
- [x] No registration, backend, cloud image processing, or mandatory onboarding.
- [x] Ads are result-only and never interrupt the task.
- [x] Batch/Shortcuts remain deferred until usage data justifies them.

## Product / QA

- [x] System Light/Dark theme; no in-app theme switch and no forced Info.plist appearance — follows iOS automatically.
- [x] Russian + English UI.
- [x] Exact W×H resize with aspect lock enabled by default.
- [x] JPEG / PNG / HEIC export in resize workflows.
- [x] Optional EXIF/GPS stripping, privacy-first default ON.
- [x] International document presets: RU, US passport print, US visa digital, India e-Visa, UK passport print.
- [x] Print sheets only for print-oriented presets.
- [x] Before/After result preview.
- [x] Result-only Yandex adaptive banner; native disabled for 0.5.0 after physical QA showed an oversized creative that could not be viewed comfortably in one result viewport.
- [x] XCTest: 16/16 passing on simulator after final consent/ATT changes.
- [x] Physical iPhone QA completed on iPhone 13: Photos/Files import, file-size compression, exact resize, document crop, save/share, print sheet, metadata stripping and banner layout verified.
- [x] Compact production banner verified on physical iPhone after the native-to-banner simplicity fix; full creative is visible on the result screen after the final spacing adjustment.
- [x] Save/share, Files import, exact resize, metadata stripping and print sheet verified on physical iPhone.

- [x] First-launch ad-consent choice verified on physical iPhone; both allow and decline keep result-screen ads enabled.
- [x] ATT prompt verified on physical iPhone; choosing “Ask App Not to Track” still leaves result-screen ads enabled.

## App Store Connect

- [x] Existing 0.4.2 is READY_FOR_SALE.
- [x] Build 4 verified unused in App Store Connect; build 3 is already VALID and is superseded by this consent/layout fix.
- [x] Archive 0.5.0 (4) created; IPA exported and Apple validation passed with no errors.
- [ ] Publish updated privacy policy at https://arvectum.com/photo-pod-razmer-privacy.html before submission.
- [ ] Upload build 4; keep build 3 unselected.
- [x] App Store version 0.5.0 exists and is PREPARE_FOR_SUBMISSION.
- [x] Updated ru-RU metadata is present in App Store Connect.
- [x] en-US and en-GB metadata are present in App Store Connect.
- [ ] Add en-IN localization.
- [x] ru-RU APP_IPHONE_65 screenshot set: 3/3 uploaded, asset state COMPLETE.
- [ ] Upload/assign remaining localized screenshot sets as needed (6.9-inch and English assets are prepared locally).
- [ ] Update App Privacy for 0.5.0: declare Device ID / advertising+analytics / tracking; do not reuse 0.4.2 “None”.
- [ ] Select build 4 and complete export compliance.
- [ ] Submit to App Review.

## Current production state

Version 0.4.2 is READY_FOR_SALE. Its live Russian description still reflects the original no-ads / Russian-passport-only build, so 0.5.0 metadata must be applied together with the new build rather than changing product scope silently.
