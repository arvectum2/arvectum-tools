# Arvectum Tools — release handoff

Date: 2026-09-25

## Current canonical product

**App name:** Фото под размер

**Android package:** `ru.arvectum.tools.tosize`

**Current Android version:** `0.4.2`

**versionCode:** `7`

**Current commit:** `5bc41b6` — `ui: install final approved launcher icon`

## Product scope — frozen

The first release contains exactly three user modes:

1. **По весу**
   - compress an image to a maximum file-size limit;
   - presets plus custom target;
   - result must not exceed the selected limit.

2. **По размеру**
   - resize by the long side in pixels;
   - short side is calculated automatically;
   - aspect ratio is preserved;
   - smaller images are not enlarged.

3. **На паспорт**
   - manual crop to 35×45;
   - technical output parameters for passport application workflow;
   - 620×797 px, 450 DPI, JPEG;
   - the app does not alter or validate face, background, pose or appearance.

**Feature freeze remains active.**
Do not add editor, batch, AI, PDF, cloud, account, backend or other jobs before the first market experiment.

## Final visual decisions

- Product name: **Фото под размер**.
- Header: Arvectum wordmark on the left, product name on the right, one row.
- Modes are shown in one row.
- Footer: **Arvectum.com**.
- Arvectum palette:
  - Mint Primary `#43E5C5`
  - Mint Light `#7AF1DD`
  - Deep Navy `#041A33`
  - Graphite `#243446`
  - Soft Gray `#F3F5F7`
  - White `#FFFFFF`
- Visual language follows Arvectum Proxy Launcher.
- No screen should require vertical scrolling in the primary task flow.
- Canonical launcher icon: the approved portrait-in-frame + four inward arrows artwork, edge-to-edge Deep Navy background with no white border.

## Final Android QA state

Validated on 0.4.2:
- app label: **Фото под размер**;
- `versionCode 7`;
- `versionName 0.4.2`;
- `assembleDebug` — success;
- unit tests — success;
- lint — success;
- INTERNET permission — absent;
- no ads;
- no analytics;
- image processing remains local.

APK SHA-256:
`4bb4886349e8bb94ed0b8087379a4bb61b9275789100a5bff89993767ff7cd30`

GitHub prerelease:
`v0.4.2-debug-7`

## RuStore preparation already in repository

See:
- `docs/rustore/STORE_LISTING.md`
- `docs/rustore/DATA_SAFETY.md`
- `docs/rustore/RELEASE_CHECKLIST.md`
- `PRIVACY.md`

The first public RuStore release is intentionally **without advertising** and **without analytics**.
Yandex Advertising Network / РСЯ is a later experiment after the first clean public release.

## Next chat — first tasks

### RuStore
1. Re-check current RuStore publication requirements from official sources.
2. Build and verify a production-signed release APK/AAB.
3. Confirm the permanent signing key and backup procedure.
4. Produce final store screenshots from the real app.
5. Finalize public privacy-policy URL and store metadata.
6. Upload to RuStore Console and run moderation checklist.

### App Store / iOS
1. Treat iOS as a separate port of the same frozen Product Contract.
2. Confirm current Apple Developer / App Store requirements from official Apple sources.
3. Define minimal native iOS architecture preserving the same three modes and visual language.
4. Prepare App Store metadata/assets/privacy declarations.
5. Build, sign, archive and submit through the existing Arvectum Apple Developer setup.

## Important product rule

**Do not expand functionality before release.**
The next work is distribution, signing, store compliance and publication — not product scope.
