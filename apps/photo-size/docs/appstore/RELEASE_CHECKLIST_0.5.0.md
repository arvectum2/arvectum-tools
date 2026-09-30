# App Store release checklist — iOS 0.5.0 (build 3)

## Simplicity gate

- [x] No new top-level mode beyond the existing three jobs.
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
- [x] Result-only Yandex Ads A/B (native/banner), production unit IDs embedded in Release.
- [x] XCTest: 15/15 passing on simulator after latest changes and simplicity refactor.
- [ ] Physical iPhone QA of the 0.5.0 build. Release build installs and launches successfully on iPhone Nikita; interactive flow checks still pending.
- [ ] Verify native and banner result-only ad variants on physical iPhone.
- [ ] Verify save/share, Files import, exact resize, metadata toggle and print sheet on physical iPhone.

## App Store Connect

- [x] Existing 0.4.2 is READY_FOR_SALE.
- [x] Build number 3 is unused.
- [x] Archive 0.5.0 (3); signed archive created and validated.
- [x] Upload build 3; App Store Connect upload accepted with no errors.
- [ ] Create App Store version 0.5.0.
- [ ] Apply updated ru-RU metadata.
- [ ] Add en-US / en-GB / en-IN localizations.
- [ ] Upload current 6.9-inch and 6.5-inch screenshots.
- [ ] Update App Privacy for advertising SDK usage if required by App Store Connect questionnaire.
- [ ] Select build 3 and complete export compliance.
- [ ] Submit to App Review.

## Current production state

Version 0.4.2 is READY_FOR_SALE. Its live Russian description still reflects the original no-ads / Russian-passport-only build, so 0.5.0 metadata must be applied together with the new build rather than changing product scope silently.
