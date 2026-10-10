# ChickMark 1.3 — pre-release checklist (UNRELEASED)

**Release decision:** HOLD. No TestFlight, App Store Connect submission or external deployment without explicit approval.

## Functionality
- [x] N/N multi-check, count and duration goals, historical progress editor
- [x] 7/30-day fixed, 4/12-week flexible, 30/90-day completion-interval insights
- [x] Groups with local-first iCloud Key-Value Store transport (needs final cross-device proof)
- [x] JSON export/import with merge/replace and original reminders
- [x] Watch desired-count protocol, optimistic/offline reconciliation and interactive step controls
- [ ] Complete physical Watch/iPhone device smoke and CloudKit + KVS convergence at the **very end**
- [ ] Verify partial state and conflict merge across real iPhone + a simulator signed to the same iCloud account

## Localization/ASO
- [x] RU/EN/ES app, Watch, widgets and Shortcuts with key parity checks
- [x] Draft regional Store text: ru-RU, en-US, es-ES and es-MX
- [ ] Editorial/native review of Spanish and regional marketing copy
- [x] Captured 9 raw iPhone simulator screenshots in EN/RU/ES (1206×2622) from 1.3 synthetic app data
- [x] Captured raw Apple Watch SE 3 40mm screenshots, EN/RU/ES, 324×394
- [x] Offline App Store-oriented screenshots exported for three languages at iPhone 1320×2868 and Watch 416×496, with pixel/dimension audit; not uploaded
- [ ] Final physical-device typography check and App Store Connect screenshot acceptance at actual release submission
- [ ] Additional locales only when justified by organic-demand data

## Architecture and quality
- [x] Typed HabitGoalMode adapter; UI component extraction; group sync ledger isolated from SwiftData schema
- [x] Published SwiftData schema and Apple entitlement identifiers remain unchanged
- [x] Local full simulator regression: 140 unit/integration and 19 UI scenarios (18 executed, 1 iOS27-only skip), no failures
- [ ] Physical signed-device smoke (no actual TestFlight submission), final device step
- [x] Local distribution-signed IPA verified: iPhone + iOS widget + Watch + Watch widget, all four first-party privacy manifests
- [x] Reviewed 28 privacy manifests from exported signed IPA and actual ad SDK config; disclosures documented in privacy-notes-1.3.md
- [ ] Final physical/runtime network and disclosure confirmation immediately before release approval
- [x] Ad count frozen at one Today banner; unit boundary tests and lazy SDK initialization in 1.3. No new placement without retention data.
- [ ] Validate existing ad fill/eligibility with a physically authorized install at last acceptance
- [x] Public App Store page (id6818711298) links Arvectum Developer Website and Privacy Policy; official site and app-ads.txt respond HTTP 200

## Last step: one physical iPhone + iOS simulator
- [ ] iPhone existing 1.2 data backed up through user-managed encrypted iPhone backup (Xcode cannot read the App Store container)
- [ ] No destructive production-app replacement before backup, approval and rollback plan
- [ ] Verify incremental upgrades, cloud-owned habit convergence and conflict retries
- [ ] Verify group changes propagate through iCloud KVS; simulator must share same Apple Account and have iCloud capability available
- [ ] Verify backup export/import, paused and skipped day reconciliation, reconnect, duplicate commands
- [ ] Log device OS, build number and test evidence; revisit if simulator CloudKit services differ from a real second device
- [ ] Owner explicitly approves release. Until then, HOLD.

## Local signed artifact evidence (not uploaded)

- [x] Xcode 27 generated distribution-signed, no-upload IPA at `/tmp/chickmark-13-final-export/HabitsByArvectum.ipa`.
- [x] Apple Distribution: LLC ARVECTUM / team `VML75VY94V`, `codesign --verify --deep --strict` passed.
- [x] SHA-256 `5513fb3db900f9c7eaa11558621caaadb313e79f40c0249cd9f29c6ddbbf1fa5`.
- [x] All four target bundles 1.3.0 (5); first-party and vendor privacy manifests inventoried (28 total).
- [x] Full local UI suite 19 tests including one iOS27-only skip; 18 passed, zero failures. 140 unit/integration tests passed.
- [x] Code/module refactor, ads lazy-start and screenshot-dimensional CI audit completed.
- [ ] Final physically authorized QA: real iPhone + iOS simulator, paired Watch; network/ads/CloudKit/KVS/disclosure review.
- [ ] Separate explicit owner approval to release.
