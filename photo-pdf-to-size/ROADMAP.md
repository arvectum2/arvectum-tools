# Фото и PDF под размер — Product Roadmap

## 19.10.2026, вечер — Фото и PDF под размер: публичная 1.0.1, RC 1.0.2 ждёт QA

**Текущее:** Apple RU **1.0.1 (13)**; исправление страниц PDF 90°/270° и подписанный кандидат **1.0.2 (14)** локальны, не подтверждены как опубликованные. UI адаптация Core в main не равна релизу iPad.

- [x] Regression исправления ориентации PDF и адаптивных состояний source/симулятора в main; ранее подписанный RC 1.0.2(14) задокументирован отдельно.
- [ ] **P0:** на физическом iPhone импорт из Files и Photos, HEIC/JPEG/PNG, сохранение оригинала, экспорт в Photos/Files/Share, большие и повернутые PDF (90°/270°) с проверкой размера и ориентации результата.
- [ ] **P0:** реальные native/banner РСЯ, согласие/отказ, no-fill, CTA без перекрытия; отделять test SDK impressions от реальных показов и выручки.
- [ ] **P1:** iPad Split View/Stage Manager, accessibility/large text, безопасный fold/unfold на Duo только при наличии настоящего устройства; production device-family не объявлять доступным до acceptance.
- [ ] **P1:** отдельно доказать Android publication/build; сейчас статус неизвестен, не считать «не опубликовано» без проверки.
- [ ] До отдельной пользовательской авторизации не загружать 1.0.2 или новые версии в Apple.

[Единая сверка](../core/docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md).


## PR #90 объединён в main · 18.10.2026

- [x] Адаптивные параметры и предпросмотр iPad/Duo в main: PR #90, 38/38 CI, исходные 31/31 unit и UI на симуляторах PASS.
- [ ] Публичная 1.0.1(13) и подписанная 1.0.2(14) не менялись; настоящие Files/Photos picker, большие PDF, экспорт, согласие/РСЯ и новый App Store релиз требуют индивидуальной приёмки.


## Пилот iPad/Duo · 18.10.2026

В feature/core-ipad-duo-pilots-20261018: адаптивные параметры + предпросмотр, узкий режим без лишней панели и iPad иконки/target (только QA). Debug build PASS, 31 unit и 2 UI PASS. Реальный Files/PDF/экспорт/реклама/hinge остаются на приёмке, PP-D0…D3 не закрыты. [QA](../core/docs/ADAPTIVE_T4_T5_PILOT_2026-10-18.md).

## Актуализация · 18.10.2026
**Последняя подтверждённая публичная iOS-версия:** 1.0.1(13), ASC READY_FOR_SALE 15.10. Подписанная **1.0.2(14)** — кандидат, её загрузка или публикация не доказаны. Android release не подтверждён отдельно.

- [x] **PP18-0 · Исправление в исходниках:** PDF поворот страниц 90°/270°, regression-тесты и воспроизводимый детерминированный CI; эти изменения отсутствуют в опубликованном 1.0.1.
- [ ] **PP18-1 · Device release gate:** Files/Photos import, Files picker/Save, PDF ориентации и большие файлы, HEIC/JPEG/PNG, корректный размер/сохранение оригинала, экспорт на физическом iPhone; затем решение о 1.0.2.
- [ ] **PP18-2 · РСЯ и согласие:** проверить реальные native/banner форматы, ATT, отказ и согласие, no-fill и перекрытие CTA; доход, fill и установки собирать в [Growth](../growth/ROADMAP.md), SDK demo не равен доходу.
- [ ] **PP18-3 · Экраны:** iPad/Duo, split-layout, fold/unfold посреди экспорта после основной стабильности и по [матрице Core](../core/DEVICE_ADAPTATION_ROADMAP.md).
- [ ] **PP18-4 · Android:** отдельно доказать состояние публикации и обновить запись в портфеле.


## Адаптация iPad / iPhone Duo — 2026-10-16

**Статус:** бэклог P1 после физической приёмки Files/Photos/PDF/РСЯ; текущий iOS target iPhone-only. [Общая матрица Core](../core/DEVICE_ADAPTATION_ROADMAP.md).

**Инфраструктура (16.10.2026):** Xcode 27.1 активна. Общий адаптивный Core подготовлен как отдельный прототип; второй пилот — предпросмотр + параметры. PP-D0…D3 остаются открытыми; Duo QA ждёт runtime iOS 27.1 (T3/T4). Релизные сборки не меняем.

- [ ] **PP-D0 · Аудит:** импорт Files/Photos, размеры/пресеты, crop/предпросмотр, PDF страницы/повороты, progress, Save/Share/Export, ATT/РСЯ-контейнеры в широких и узких окнах.
- [ ] **PP-D1 · iPad:** split-layout исходник ↔ результат/параметры, поддержка Stage Manager и Split View, popovers и document picker, portrait/landscape, большой текст, export в Files/Photos.
- [ ] **PP-D2 · iPhone Duo:** внешний экран с компактным редактором, внутренний — сравнительный предпросмотр; fold/unfold во время ресайза/PDF-экспорта не перезапускает обработку, не теряет параметры и исходный файл; ad-блоки не перекрывают CTA и не блокируют экспорт.
- [ ] **PP-D3 · QA:** оригиналы не изменяются, корректный размер/ориентация результата, большие PDF/HEIC и память, sandbox/Files picker, consent/ads, iPad+Duo layout, actual device QA, новые App Store скриншоты. iPad target family включать только после проверок. Android в этой задаче не меняется.

## Active release checkpoint — 2026-10-15

**A5 RC:** [Фото/PDF 1.0.2 (14)](../core/A5_SIGNED_RELEASE_CANDIDATES_20261015.md) подписан с исправлением поворота PDF, IPA проверена, **не загружен в ASC**. Первый релизный GitHub CI упал на системных Files/Save (и тайм-ауте); [PR #74](https://github.com/arvectum2/arvectum-tools/pull/74) слит в main (`134e3fe`) после 2/2 CI SUCCESS с **31 unit + 5 детерминированных UI**. Исправленные тесты перенесены в release-ветку (коммит `7b4318a`), производственный исходный код побайтово совпадает с подписанным тегом; [release CI 38795581835](https://github.com/arvectum2/arvectum-tools/actions/runs/38795581835) ещё выполняется. **На чистом iOS 27-симуляторе Files и Save UI остаются непрошедшими и требуют физической приёмки**, [triage](docs/A5_CI_SYSTEM_FILES_TRIAGE_2026-10-15.md), [issue #73](https://github.com/arvectum2/arvectum-tools/issues/73). Публичная 1.0.1 (13) не изменена; физические Files/Photos/ATT/РСЯ открыты в [issue #73](https://github.com/arvectum2/arvectum-tools/issues/73).

**Published iOS baseline:** **1.0.1 (13)**, owner-confirmed and independently verified **READY_FOR_SALE** via authenticated App Store Connect API on **2026-10-15**. Previous version 1.0.0 (12)
was published 2026-10-11. The signed 1.0.1 build was submitted for review
2026-10-13 from the release/photo-size-ios-1.0.1 branch.
Owner confirmation and an authenticated ASC API lookup both supersede the
old under-review state; per-region storefront propagation was not checked.
Apple App ID 6816346084; bundle ID ru.arvectum.tools.tosize.
[Public App Store listing](https://apps.apple.com/ru/app/id6816346084).

- [x] 1.0.1 (13) published — owner-confirmed 2026-10-15.
- [x] 1.0.1 signed upload, 20 localised release notes, consent text-size fix,
  28 iOS unit and 5 simulator UI tests recorded in release branch.
- [x] Verified exact App Store version 1.0.1 READY_FOR_SALE and build 13 VALID
  via authenticated ASC API 2026-10-15.
- [ ] Verify regional public storefront indexing if required by a target market.
- [x] **A4 post-release source QA 2026-10-15:** identified a real page-orientation regression for 90°/270° rotated PDF pages (pre-fix RED page 2/4), fixed in source with rotation-aware render and display page box. New mixed-page orientation + source preservation tests; **31/31 iOS unit + 5/5 simulated UI PASS**, including 16-page >70 MB PDF test and JPEG/PNG/HEIC output. [A4 QA evidence](docs/A4_POST_RELEASE_QA_2026-10-15.md). [PR #72](https://github.com/arvectum2/arvectum-tools/pull/72) merged into main (`f78c750`), both GitHub CI runs SUCCESS. **Not in the published 1.0.1 binary**.
- [ ] Post-release physical Files/Photos import, output export, rotated/large PDF, ATT/consent and live per-unit RСЯ fill QA. Fresh CoreDevice app list did **not** show the shipping app installed on the connected iPhone (only a test runner); this listing alone cannot establish installation state; do not install without approval. [Physical/partner acceptance issue #73](https://github.com/arvectum2/arvectum-tools/issues/73).
  A demo ad or UI test alone cannot establish real advertising impressions.
- [x] Original signed source tagged (`photo-size-ios-v1.0.1-build13`),
  archived IPA checksum verified, release automation/metadata and signing
  integrated with Core-based main via PR #67; older direct-palette project
  deliberately not merged.
- [ ] Independently verify Android publication; none confirmed so far.

**Updated:** 2026-10-15.
**Ownership:** image/PDF sizing, presets, export, UX, app-specific SDK, QA and releases.
**Evidence:** [1.0.0 release](docs/appstore/RELEASE_1.0.0_2026-10-11.md),
[1.0.1 release branch](https://github.com/arvectum2/arvectum-tools/blob/release/photo-size-ios-1.0.1/photo-pdf-to-size/ROADMAP.md),
[physical QA](docs/PHYSICAL_QA_2026-10-14.md).
**Historical roadmap:** [archive](docs/history/ROADMAP-legacy-2026-10-11.md).
**Core:** [common infrastructure](../core/ROADMAP.md).
**Growth:** [distribution and ASO](../growth/ROADMAP.md).

## Current implemented capability (repository-recorded; validate against shipping build)
- [x] Local image file-size and dimension modes; document-photo presets.
- [x] PDF target-size mode added in 0.6.0 with local processing and rasterization warning.
- [x] Photo import from Files/iCloud, exact W×H, JPEG/PNG/HEIC export options, EXIF controls, print sheets.
- [x] International document presets RU/US/India/UK (country-specific constraints documented).
- [x] RU/EN localization, system Light/Dark UI and lower primary CTA placement.
- [x] Home native ad and result banner recorded as production integration in 0.5.1.
- [x] Store screenshots prepared showing before/after; this is a completed asset task, not a pending product feature.
- [x] iOS release v1.0.0 publicly launched, 2026-10-11.

## Distribution history and current 1.0.1 follow-ups

- [x] 1.0.0 (12) published 2026-10-11, signed source and archive recorded.
- [x] 1.0.1 (13) signed, uploaded and sent to App Review on 2026-10-13.
- [x] 1.0.1 (13) publicly released by 2026-10-15 (owner confirmation).
- [x] Accessibility consent fixes and automated QA recorded on release branch.
- [ ] Associate exact public 1.0.1 build with source SHA, release tag,
  public storefront evidence and reproducible signed archive.
- [ ] Complete physical post-release validation of Files/PDF/ads/ATT.

## Maintenance: Core and dependency alignment (2026-10-13)

- [x] Replace direct Core palette source inclusion with the local `ArvectumCore` SwiftPM dependency; keep product-specific adaptive colors here.
- [x] Confirm iOS Yandex Mobile Ads 8.6.0 matches the Core catalog and checked-in SwiftPM lock; keep stable native/banners implementation while adopting Core.
- [x] Extend scoped CI to verify Core dependency contracts and to respond to Core manifest/catalog edits; ensure Android version-catalog changes run Android CI.
- [x] Xcode 27 validation: 4 Core tests, 28 iOS unit tests, 5 simulator UI tests passed (5 physical-Files UI tests skipped by design); Android test/lint/assemble passed.
- [ ] Run real-iPhone advertising checks (native + banner, consent yes/no,
  ATT status) and export regression as **post-release 1.0.1 QA**.
- [ ] Use physical QA findings to gate any **future** corrective patch;
  do not retroactively describe the published 1.0.1 as a candidate.

## Next: post-release QA and maintenance
- [ ] Run device regression on image modes, document presets, PDF orientation, large-file memory and export.
- [ ] Confirm which ads/presets/locales are present in the published build (not just development history).
- [ ] Close or document known crashes/regressions and classify fixes for the next patch.

## Deferred / evidence-gated
- [ ] Batch processing: decide after usage data.
- [ ] Shortcuts/power-user extensions: only with demonstrated demand.
- [ ] More locales or document-market presets: only with actual market/search evidence.

## Guardrails specific to this app
- Never alter source originals; on successful target-size operation check output bytes against limit.
- PDF may rasterize: explicitly disclose loss of selectable/searchable text.
- Not a general PDF editor, scanner, OCR toolkit or AI retouching product.
- Ad rendering must not block export; concrete SDK/ad UX requirements stay here.
