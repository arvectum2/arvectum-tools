# Фото и PDF под размер — A4 post-release quality gate (2026-10-15)

**Release baseline:** iOS **1.0.1 (13)**, independently confirmed READY_FOR_SALE in App Store Connect earlier on 2026-10-15 (App ID 6816346084, `ru.arvectum.tools.tosize`). This patch does **not** change the published binary. Scope is post-release regression, not a claim that the existing App Store release already contains the fixes.

## Provenance

- Compared `origin/main` and `origin/release/photo-size-ios-1.0.1` for iOS code. Remaining differences in that comparison are limited to Xcode project configuration, `project.yml` and a release script; the product source is already integrated via PR #67. The original signed 1.0.1 source remains tagged and immutable.
- No release branch, signed archive, customer Photos/Files or real iPhone app was altered.

## Found issue A4-PDF-ROTATION

- **RED reproduced** from current post-release source: four-page synthetic PDF with alternating portrait/landscape MediaBoxes and rotation flags `0, 90, 180, 270`. Compressed result held the size threshold and all four pages, but the **2nd and 4th visual page orientations differed** from the originals (90/270); XCTest failures explicitly recorded before correction.
- **Root cause:** `PDFEngine.renderPage` created the output PDF MediaBox from the unrotated page bounds and therefore lost the visual dimensions when `PDFPage.rotation` was 90/270.
- **Fix:** compute displayed page box for quarter turns; render with PDFKit's rotation-aware thumbnail only for 90/270, retaining the established 0/180 draw path. Output MediaBox matches the correctly displayed page orientation; existing page-count/size contract is unchanged. PDF rasterization remains disclosed (searchable/selectable text may be lost).
- **GREEN locally:** new mixed-orientation test and pre-existing one-page orientation test both PASS. Complete unit suite subsequently **31/31 PASS**, including the 16-page >70MB source PDF compression to ≤5 MB.

## Additional A4 source-preservation tests

- Synthetic local JPEG imported then exported to JPEG, PNG, HEIC at 600×800: bytes of original file unchanged, output separate, output size metadata matches actual bytes.
- Synthetic three-page PDF imported by URL and exported through the already-fits path: original PDF bytes unchanged, output separate with three pages and matching reported size.
- Existing unit tests cover custom byte limits, GPS metadata stripping/opt-in retention, EXIF rotation, document presets and output sizes.

## Advertising, ATT and consent

- Static production unit IDs: **R-M-20141949-1** Native and **R-M-20141949-2** Banner. They are present in release-source mode; DEBUG IDs are demo units. SDK disables location tracking and passes explicit consent; system ATT request is attempted only after positive advertising-data consent.
- Existing deterministic UI layout test covers an intentionally oversized native creative under RU/EN and light/dark appearances; an SDK demo or view layout is **not** proof of paid partner inventory.
- **OPEN external:** first-party RСЯ actual per-placement fill/no-fill, impressions and revenue on the exact published binary; native/banner consent Yes/No and ATT prompted/not-determined on a physical device. No ad clicks/traffic generated.

## Physical device and Files/Photos QA

- Historical 2026-10-14 CoreDevice physical observation reported app 1.0.1(13) installed. **Fresh** CoreDevice `device info apps` on 2026-10-15 currently shows only `ru.arvectum.tools.tosize.uitests.xctrunner` and **does not list `ru.arvectum.tools.tosize`**. Do not infer why the app is absent. Do not install, reinstall or delete anything on owner's iPhone without explicit consent.
- **OPEN physical:** sample import from Files and Photos, real iOS fileExporter save, share sheet, HEIC, PDF page rotations and large file memory on published app, genuine ad/ATT flows. Simulator fixtures cannot replace device or Files-provider validation.

## Automated evidence

- [x] Isolated iPhone 17 / iOS 27 simulator, pre-fix mixed-rotation XCTest RED with failures on page 2 and 4.
- [x] Post-fix two orientation tests GREEN.
- [x] Full photo/PDF XCTest suite **31/31 PASS**, zero failures, including 2 added source-file integrity tests and large PDF.
- [x] Five simulator UI tests **5/5 PASS**, four Workflow scenarios plus RU/EN light/dark worst-case native ad layout, no failures. The UI opened the system Files picker but did not actually import a genuine Files-provider document.
- [ ] New GitHub CI unit/UI regression step; record PR, CI runs and exact merged SHA after execution.
- [ ] Physical/partner acceptance remains OPEN.

**Next release:** candidate next patch may contain the rotation fix after independent CI. Do not amend 1.0.1 or label a future source-only fix public. Keep `Where?` out of scope.
