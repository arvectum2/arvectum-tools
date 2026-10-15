# PUSHKIN — Product Roadmap

## Active checkpoint — 2026-10-16 (A6 onboarding source)

- [x] **A6 guided setup:** показаны три шага (импорт базового подписанного shortcut, ручное включение в Shortcuts, подтверждение минимум одного реального захвата); при поздней установке приложения указан refresh подписанного micro-package.
- [x] **A6 optional groups:** локальный планировщик групп по 25 приложений из offline-каталога, без дубликатов, с копированием списка. Это удобный размер списка, **не лимит iOS**: [на физическом iPhone 1000 SelectedApps успешно сохранились в одном триггере](docs/PHASE0_SPIKE.md#1000-app-trigger); подтверждение 1000 активных источников не проводилось.
- [x] **A6 local QA:** Xcode 27 сборка PASS, 17/17 XCTest unit PASS, 2/2 focused UI PASS после исправления тестового поиска offscreen-ссылок. [Протокол](docs/A6_ONBOARDING_QA_2026-10-16.md). Исходные SwiftData/capture/App Intents и подписанные shortcuts не изменены.
- [x] **A6 PR #75 MERGED** в main (`d1a0518`); два независимых [GitHub push CI 38813911302](https://github.com/arvectum2/arvectum-tools/actions/runs/38813911302) и [PR CI 38813914613](https://github.com/arvectum2/arvectum-tools/actions/runs/38813914613) — SUCCESS, включая отдельные delete-regression jobs.
- [ ] **A6 physical Shortcuts/notification QA OPEN** [issue #76](https://github.com/arvectum2/arvectum-tools/issues/76): подтвердить enable, late-install micro, 2 ручные группы и реальные уведомления без изменения личной истории. Signed A5 Pushkin 1.0.1(3) не включает A6 и не обновлён.

## Active checkpoint — 2026-10-15 (independently verified ASC API)

**A5 RC:** [подписанная 1.0.1 (3)](../core/A5_SIGNED_RELEASE_CANDIDATES_20261015.md) подготовлена из исправлений удаления и Shortcuts; IPA и подпись проверены, release-branch CI PASS. **Не загружена в ASC**, первоначальная 1.0.0 всё ещё WAITING_FOR_REVIEW. Физический недеструктивный QA остаётся OPEN.
**Latest review state:** iOS 1.0 remains under Apple review, independently verified **WAITING_FOR_REVIEW** via ASC API 2026-10-15; no publication confirmed. Physical iPhone carries developer build 1.0.0 (2), which must not be confused with the submitted build 1.0.0 (1). [Physical QA evidence](docs/PHYSICAL_QA_2026-10-14.md).
- [x] Submitted local-only notification history with Shortcuts/App Intents capture, searchable offline storage and fallback onboarding.
- [x] Rechecked App Review via authenticated ASC API 2026-10-15: still Waiting for Review, build 1 VALID.
- [ ] Recheck Apple's decision before preparing a patch; no public distribution confirmed.
- [x] A1 source correction for unsafe SwiftData deletion and 6/6 local regression tests (3 unit, 3 UI on isolated simulator), 2026-10-15. [QA evidence](docs/DELETE_SAFETY_QA_2026-10-15.md). Original physical stacktrace not yet confirmed.
- [x] A1 merged source fix [PR #68](https://github.com/arvectum2/arvectum-tools/pull/68) (`6a6c206`): 6/6 unit/UI tests locally plus GitHub CI delete-regression passed on push and PR.
- [x] Shortcuts micro-package resource lookup fix [PR #69](https://github.com/arvectum2/arvectum-tools/pull/69) (`afed583`), original full unit suite 9/9 pass; after merging PR #68 and #69, **combined main 12/12 units PASS**. [QA](docs/SHORTCUT_RESOURCES_QA_2026-10-15.md).
- [ ] A1 physical iPhone regression: use only an explicitly created disposable notification after permission, without resetting existing history; compare with original crash if reproducible.
- [ ] Physically validate offline capture and automation enablement/refresh, including Shortcuts' 25-app grouping constraint.
- [ ] Prioritize simpler guided setup and Russian in-app language after stability; snooze, Save/Done, digests and rules are later.
- [ ] Revisit monetization only with strict exclusion of notification data from advertising and analytics.


**ASC API verified 2026-10-15:** first release iOS 1.0 remains **WAITING_FOR_REVIEW** (App ID 6817847111; build 1 VALID), no public distribution confirmed; crash/Shortcuts QA still open. Previous checkpoint:

**A1 2026-10-15:** The developer/source fixes and CI are complete; the initial iOS 1.0 App Store build still awaits Apple review and does not contain these patches. Physical reproduction of the October 4 crash and 25-app/Shortcuts real-device QA remain open.
[Portfolio registry](../core/PORTFOLIO.md).

**Updated:** 2026-10-15 (A1 fixes merged into main and CI green; physical and next App Store patch are unverified)
**Ownership:** capture/onboarding, notification store, privacy, search and product UX.
**Status:** iOS 1.0 **Waiting for Review**, reverified via authenticated App Store Connect API 2026-10-15. Submission history is preserved in the release documentation; no publication confirmed.
**Full historic phases and decision evidence:** [docs/history/ROADMAP-legacy-2026-10-11.md](docs/history/ROADMAP-legacy-2026-10-11.md). Do not treat old unchecked phases as 1.0 blockers.
**Common rules:** [Core](../core/CORE_PRINCIPLES.md). **Growth:** [Growth](../growth/ROADMAP.md).

## 1.0 baseline (recorded in code planning)
- [x] Physical iPhone capture via Shortcuts/App Intents, bundled TOP-1000 catalog and local one-app micro-packages.
- [x] Manual fallback and automatic capture verification.
- [x] Local-only storage and chronological notification history.
- [x] Full-text search, copy/share/delete, clear history.
- [x] English app UI and RU/EN store metadata prepared.
- [x] Signed 1.0.0 (1) archive and App Store submission recorded.
- [x] Check App Store Connect on 2026-10-11: iOS 1.0 is **Waiting for Review**.
- [ ] Confirm future review outcome and publication; do not treat submission as publication.
- [ ] Complete/manual-record physical offline smoke testing and final visual QA.

## Immediate post-submission
- [ ] Productize app-refresh onboarding with system Add + automation-enable guidance and verified coverage.
- [x] Implement and simulator-test immutable history rows/details, stable UUID deletion, delete-all and save error alerts; 6/6 tests passed. [QA details](docs/DELETE_SAFETY_QA_2026-10-15.md).
- [ ] Verify deletion on physical iPhone and investigate any remaining crash from the original report before publishing a patch.
- [ ] Russian in-app localization (deferred from 1.0).
- [ ] Decide ad SDK integration for first post-launch update after verifying policy and UX.

## Later, subject to feedback
- [ ] Save/Done, useful filters and configurable retention.
- [ ] Snooze/remind-later and important inbox.
- [ ] Digests, app grouping and simple rules.
- [ ] Face ID protection and accessibility improvements.

## Product-specific constraints
- Notification data never becomes analytics/advertising content.
- No account, backend, cloud or live catalog lookup required for core capture.
- Prioritize reducing Shortcuts setup and coverage-refresh steps.
