# chickmark — A5 isolated release candidate 1.4.2 (16)

**State as of 2026-10-15: SOURCE-CANDIDATE ONLY. Not uploaded, not submitted, not public.**
**ASC external source:** authenticated read-only lookup on 2026-10-15: public 1.4.1 (15) READY_FOR_SALE confirmed through ASC 2026-10-15.
**Bundle:** `ru.arvectum.tools.habits`. **Proposed** version/build: `1.4.2 (16)`.
**Source base:** `origin/main@657ce0d6bcce78cf35e07135ef5871da8e07c0ff`, plus ONLY the `chickmark/ios/project.yml` version/build changes in this isolated release branch and this release document. No old release source is blindly merged.
**Release branch:** `release/chickmark-1.4.2-build16-a5-20261015`.

## Included changes — source-only since last submitted build

PR #71: duplicate-ID Cloud KVS ledger safe deterministic merge. Native YAN view fix in main is post-build15 source, tested only in development. No new HealthKit write/export; no CloudKit migrations.

## App Store What’s New — draft, not posted

**ru-RU:** Повысили устойчивость синхронизации групп привычек и исправили отображение нативной рекламы. Ваши отметки и история сохраняются.

**en-US:** Improved habit-group sync reliability and native ad presentation. Your check-ins and history are preserved.

**es-ES / es-MX:** Mejoramos la estabilidad de la sincronización de grupos de hábitos y la presentación de anuncios nativos. Tu historial permanece intacto.

## Pre-submission gates

- [x] Isolated branch from frozen `657ce0d6bcce` base; no automatic merge to `main`.
- [x] Reserved unique marketing/build number; cross-target version consistency is enforced by `project.yml`. Managed signing export settings: [ExportOptions-A5-AppStore.plist](ExportOptions-A5-AppStore.plist).
- [ ] Clean generated Xcode project builds on generic iOS Simulator (and watchOS if applicable).
- [ ] Full app unit/UI regression and clean GitHub Actions release-branch checks.
- [x] **App Store-exported IPA** `HabitsByArvectum.ipa` with SHA-256 `02dea1db1f58b9eb519ecf42f7bc4ac8989ef5ff4d789a01fa2a5031cc6d107b`; Xcode archive SUCCEEDED, export SUCCEEDED, team VML75VY94V. Exported IPA has production Store profiles, disabled `get-task-allow`, and matching version/build in **4/4 bundles**. Xcode may use an Apple Development profile in the intermediate `.xcarchive` for Watch/widget apps; **the exported IPA is independently re-signed**. [Machine-readable receipt](A5_SIGNED_IPA_RECEIPT_1_4_2_2026-10-15.json).
- [x] Extracted IPA validated: bundle version/build, App Store profile entitlements, `codesign --verify --strict` for all bundles; no RuWordNet-named assets bundled. Physical application behavior and exact signed archive reproducibility remain independent gates.
- [ ] **Physical/external:** Physical non-destructive history across upgrade with CloudKit independent second device (A1); explicit owner-controlled HealthKit revoke/regrant (A4), native YAN actual fill/impressions (A6), physical VoiceOver/A7. Do not mutate user habits or permissions for automated smoke tests.
- [ ] **Apple:** actual new App Store version + build association, review notes and required locales only after preceding gates pass. No upload or submission in A5 draft phase.

## Existing QA evidence
- chickmark/docs/A3_STABILITY_RECONCILIATION_2026-10-15.md
- Verified external version state is separate from the submitted build, local code tests and simulated user flows.
- Never use another app's signed IPA or release profile. No user data deleted, reinstalled, replaced, uploaded or reset in preparing this candidate.
