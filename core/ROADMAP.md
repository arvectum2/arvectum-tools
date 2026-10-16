# Arvectum Tools Core — Roadmap

**Очередность работ 2026-10-15:** [общий execution plan](EXECUTION_PLAN.md). [Срез A0 — Apple, исходники и GitVerse](RELEASE_PROVENANCE_20261015.md). Приоритет — CI/release provenance и помощь живым релизам, без активной разработки Where?.

## Адаптация всех iOS-продуктов: iPad + iPhone Duo — 2026-10-16

- [ ] **Core / device adaptation:** единые условия layout, dynamic resize, iPad Split View/Stage Manager, iPhone Duo 5,4″ closed/7,6″ open, accessibility, сценарии QA и честное определение готовности в [портфельной матрице](DEVICE_ADAPTATION_ROADMAP.md). Изменения UI и release QA выполняются в дорожных картах самих приложений; проверенных релизов ещё нет.

## Xcode 27.1, Adaptive Core и Duo Runtime — 2026-10-16

- [x] **C-D0 · Toolchain:** Xcode 27.1 (27A9275) активна, first-launch завершён, CoreSimulator 1174.9.2 работает; тип iPhone Duo появился. Xcode 27.0 сохранена для отката.
- [x] **C-D1 · Общий UI-прототип:** [ArvectumAdaptiveLayout](https://github.com/arvectum2/arvectum-tools/tree/feature/core-adaptive-layout-spike-20261016) в отдельной feature-ветке; 11 первоначальных Core unit-тестов и iOS Simulator build на Xcode 27.1 пройдены. macOS test bundle на новой Xcode требует повторной проверки доступа; в main и приложениях прототипа нет.
- [ ] **C-D2 · Runtime:** дождаться установки iOS 27.1 (24A94232), создать и загрузить Duo Simulator. iOS 27.0 несовместима с Duo.
- [ ] **C-D3 · Пилоты:** Ухват → Фото/PDF на общей SwiftUI-основе; QA iPhone/iPad/Duo перед слиянием Core. [Сводный чеклист T0–T5](DEVICE_ADAPTATION_ROADMAP.md).

## 2026-10-15 implementation checkpoint
- [x] Shared Swift packages exist: ArvectumDesignTokens, ArvectumPersistence and ArvectumDiagnostics, with privacy-safe local diagnostics.
- [x] Core CI tests consumers ChickMark, Pushkin, Photo/PDF and What?, watchOS and Android, with reviewed dependency catalogs.
- [x] Photo/PDF adopted shared ArvectumCore SwiftPM in main on 2026-10-13 and aligned Yandex Mobile Ads 8.6.0 with the Core catalog.
- [x] Dated status registry reconciled for all five products, including owner-confirmed Фото/PDF 1.0.1 publication (see PORTFOLIO.md); status synchronization is not source/build provenance or App Store QA.
- [x] A0 source/release audit completed 2026-10-15: [PR #67](https://github.com/arvectum2/arvectum-tools/pull/67) merged at `e129efc`, [Core CI](https://github.com/arvectum2/arvectum-tools/actions/runs/38756915944) 10/10 PASS, GitVerse main and four release tag targets match; [provenance report](RELEASE_PROVENANCE_20261015.md).
- [ ] Audit each **future** release tag, source/build provenance and GitVerse mirror SHA; current audit does not certify future builds.
- [ ] Wire Where? into relevant CI only when buildable iOS source exists, without placeholder jobs.
- [ ] Keep Core CI dependency-impact testing up to date as consumer entrypoints change.
- [ ] Extract shared UI, telemetry and ad interfaces only when two stable apps demonstrate genuine need.

This checkpoint supersedes outdated statuses in the older engineering-follow-up section below; Core still owns only cross-product infrastructure.


**Updated:** 2026-10-15. **Owner:** common rules, brand, code reuse, CI and release infrastructure.

## Current baseline
- [x] Monorepo with independent apps and release cycles.
- [x] Shared brand rules and a canonical common-principles document.
- [x] Path-scoped CI and release checklist recorded in repository.
- [x] Separate portfolio roadmap registry with single ownership.

## Engineering follow-ups
- [ ] Audit CI path filters for newly added apps Where? and What?.
- [ ] Verify shared dependency impact testing and standard release tagging.
- [ ] Define common cross-app crash and privacy-safe telemetry interfaces only when used by multiple apps.
- [ ] Extract UI, ads, analytics, store or privacy packages **only** after at least two real consumers require them.
- [ ] Keep brand/design tokens in [core/BRAND.md](BRAND.md), not repeated in app roadmaps.

## Hard boundaries
No app feature prioritization, app-specific ad activation policy, acquisition metrics, ASO/SEO or marketing experiments.
Canonical policies: [CORE_PRINCIPLES.md](CORE_PRINCIPLES.md) and [REPO_ARCHITECTURE.md](REPO_ARCHITECTURE.md).
