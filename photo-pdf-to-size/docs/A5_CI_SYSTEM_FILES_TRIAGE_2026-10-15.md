# Фото/PDF A5 — triage CI сбоя системных Files UI, 2026-10-15

## Evidence: GitHub Actions failure was real, not a passing gate

- Failing [A5 release branch run 38786493214](https://github.com/arvectum2/arvectum-tools/actions/runs/38786493214), job `build-for-testing`, test step timed out at **22 minutes**. Xcode's simulator test build itself succeeded.
- Within the runner, `LayoutRegressionUITests.testWorstCaseNativeNoScrollRUAndENLightDark` **PASS**, `testPhotoCompressionAndBackNavigation` **PASS**, `testPixelAndDocumentModesWithPhotoFixture` **PASS**.
- `testFilesPickerOpensWithoutPriorFileInRecents` **FAIL** on an assertion that `app.collectionViews["File View"]` is found; a system Files-provider view's accessibility identifier is not guaranteed in a fresh CI simulator/locale.
- `testPDFCompressionAndSave` **FAIL** after PDF compression succeeded because `app.buttons["Сохранить"]` was not found inside the app accessibility tree after opening the system export sheet.
- Runner also logged network timeouts for SDK/StoreKit and iOS process lifecycle noise; those logs are **not evidence of a product failure**. Assertions are to platform-controlled UI and need physical validation rather than a hardcoded system-screen name.
- Independent Mac mini local A4 run **31/31 unit and 5/5 previous UI PASS**; these runs alone do not override the GitHub runner failure or prove real Files-provider save.

## Targeted CI correction

1. **One concrete iPhone 18 Pro/iOS 27 Xcode test build, not two:** previous workflow first ran `build-for-testing` on generic iOS Simulator (dual arch) and then repeated a simulator compilation for `test`. This added cold build time.
2. Keep all `PhotoPodRazmerTests`: engine compression, full page-orientation regression, >70 MB source PDF to <=5MB target, metadata, source-file immutability for JPEG/PNG/HEIC/PDF.
3. Keep deterministic app-owned UI coverage: 4 RU/EN × light/dark layouts, photo compression/back, pixel/document modes, a new synthetic PDF compression result with enabled Save/Share, and Files import button accessibility. **This does not assert actual Files save/import.**
4. Keep the *original* system Files-picker/save-sheet E2E tests in the source code, not removed. They are explicitly excluded from the GitHub gating run pending a reliable Files-provider QA environment; physical import/export on disposable fixtures remains an **OPEN release blocker** in [issue #73](https://github.com/arvectum2/arvectum-tools/issues/73).
5. Must see successful GitHub release-branch run before calling the A5 automated gate completed. A green run on different tests cannot retroactively convert failed 38786493214 to PASS.

## Provenance and effects

Only test target source and GitHub CI configuration change. **The signed 1.0.2 (14) application IPA and RC1 source tag remain unchanged.** No app production code, permissions, local photo collections, or user iPhone state modified. Re-run the available deterministic and original local UI tests independently, record exact outcomes. No new App Store upload or submission.

**Remaining A4/A5 physical checks:** Files and Photos import, actual Save to Files and Share sheet, rotated PDF readability and big-file memory; ATT Yes/No and YAN Native/Banner real fill/impressions.

## Verified follow-up (same date)

- On a completely new **iPhone 18 Pro, iOS 27.0 simulator on Mac mini**, the two original platform E2E tests were rerun without touching user data: Files collection label test **FAIL (28.975s)**, PDF system save-button test **FAIL (181.848s)**; XCTest also reported an app-idle wait after tapping Save. This confirms **fresh-simulator-state sensitivity**, not that the first-use feature is healthy on a physical iPhone.
- Screenshot while PDF test was active showed the app's result page and its **Сохранить файл** button. That snapshot alone cannot establish whether Apple's document picker appeared momentarily, presented inaccessible UI, or failed to present; physical verification is required.
- A pre-warmed iPhone 17 simulator had **5/5 UI PASS**, but this does not override the two failures above. The disposable fresh simulator was shut down and deleted after the test.
- Stable Mac mini suite after the CI change: **31/31 unit + 5/5 app-owned UI PASS**. Changed only the test bundle and GitHub workflow; production source tree in the A5 release branch was verified identical to signed RC tag.
- [PR #74](https://github.com/arvectum2/arvectum-tools/pull/74) **MERGED** into main at `134e3fed7ed6718a593b94406f5ea678cba54c15` after two independent GitHub CI **SUCCESS** runs [push 38793584633](https://github.com/arvectum2/arvectum-tools/actions/runs/38793584633), [PR 38793592199](https://github.com/arvectum2/arvectum-tools/actions/runs/38793592199).
- Test-only cherry-pick into `release/photo-size-1.0.2-build14-a5-20261015` at `7b4318a`; `PhotoPodRazmer` production source Git object SHA is unchanged from signed `photo-size-ios-v1.0.2-build14-rc1`. [Release-branch CI 38795581835](https://github.com/arvectum2/arvectum-tools/actions/runs/38795581835) still requires final disposition.
- **Physical App Store patch distribution remains blocked** by [#73](https://github.com/arvectum2/arvectum-tools/issues/73). Signed IPA SHA remains unchanged.
