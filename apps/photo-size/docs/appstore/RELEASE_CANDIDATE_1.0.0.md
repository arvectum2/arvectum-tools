# iOS Photo & PDF Size 1.0.0 — Release Candidate Checklist

**Owner approval gate: HOLD.** The user explicitly asked to refactor and verify first. Do not submit for App Review, publish, make App Store metadata live, or deploy the associated web pages.

## Baseline

- Live App Store version on 2026-10-10: **0.6.2 READY_FOR_SALE**.
- App Store ID: `6816346084`, bundle ID `ru.arvectum.tools.tosize`.
- Latest observed App Store Connect build number: **10** (2026-10-07).
- Planned release: **1.0.0**, candidate build **11** (recheck App Store Connect before upload).
- Branch from `origin/main` includes the latest PDF orientation/saving hotfixes (cherry-picked commits).
- International ASO package prepared for 20 locales in `docs/aso`; localized web pages staged separately in the site repo branch.
- Primary storefront markets: RU, US, GB, MX/ES, BR, DE, FR. More markets based on measured demand.

## QA gate

- [x] Functional architecture decomposed, photo/PDF engine APIs preserved.
- [x] Cancelled/stale async completions isolated with operation identifiers.
- [x] Pure KB/MB/pixel validation added.
- [x] DEBUG-only deterministic UI fixtures added.
- [x] Unit tests cover JPEG, PNG, HEIC, PDF orientation, target bytes, cropping, print sheets, metadata stripping, reset and import.
- [ ] Full simulator tests final green (record command, test count, skip count and device).
- [ ] Actual app PDF result screenshot added to international ASO screenshot set.
- [ ] Generate/review final 1.0.0 iPhone screenshots after freeze; compare to compiled UI.
- [ ] Physical iPhone: from Photos import, from Files import, PDF, exact pixel size, passport crop, save and share, dark/light mode, return/home, manual EXIF check.
- [ ] Physical iPhone: verify advertising consent (yes/no), native ad and result banner on first and later launches; ATT if applicable.
- [ ] Confirm UI only advertises actual implemented locale support. Draft localized App Store metadata does **not** mean in-app UI is localized.
- [ ] Test on iOS 17 compatibility or keep deployment target explicitly documented.
- [ ] Review privacy manifest, App Store privacy answers and product URLs.
- [ ] Verify legal claims: no government acceptance guarantee; strong PDF compression may rasterize text.

## Submission gate — forbidden in this task

- [ ] Reconfirm version 1.0.0 and highest existing ASC build before packaging.
- [ ] Code-sign/archive production 1.0.0 build.
- [ ] Upload .ipa to ASC, add locale metadata, screenshots, release notes.
- [ ] Conduct TestFlight or device beta review if requested.
- [ ] Owner explicitly approves App Review submission and public web deploy.
- [ ] Submit and monitor App Store review and crashes.

## Localization/marketing gate

- [x] 20 locale metadata draft records, UTF-8/length validation.
- [x] 60 initial localized real-UI screenshot compositions.
- [ ] Confirm actual PDF workflow 4th screenshot per locale.
- [ ] Native UI localizations beyond Russian and English (or disclose English UI explicitly).
- [ ] Human proofreading of priority locale copy and screenshot crops.
- [ ] Merge staged multilingual SEO website branch only after explicit approval.
- [ ] After release: monitor impressions, product page conversion, downloads per storefront, crashes and app review ratings at 2 and 4 weeks.

The release candidate should be **built and tested locally only** until every required gate is green.
