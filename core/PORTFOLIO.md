# Arvectum Tools — Roadmap Registry

## 24.10.2026 · ZH-Hans: девятый исходный язык iOS

- [x] Полные RU/EN/ES/FR/DE/PT-BR/IT/JA/ZH-Hans в 4 iOS-приложениях и десяти iPhone/Watch/widgets bundles.
- [x] 899 китайских строк, локализованные разрешения и региональный fallback. [QA](docs/IOS_ZH_HANS_PORTFOLIO_QA_2026-10-24.md).
- [x] Китайские сборки 6/6, UI 6/6, Swift unit 35/35 PASS.
- [ ] Физическая/редакторская QA, отдельное согласование Apple релиза.


## 24.10.2026 · iOS-first Japanese

- [x] Восемь исходных языков RU/EN/ES/FR/DE/PT-BR/IT/JA для 4 продуктов/10 targets; JA 899 строк.
- [x] Исправлен японский интерфейс Pushkin/Ухвата/ChickMark. [QA](docs/IOS_JA_PORTFOLIO_QA_2026-10-24.md).
- [x] Japanese builds 6/6, UI 6/6 и Swift language XCTest 32/32 PASS.
- [ ] Физическая/редакторская QA и отдельное согласование Apple релизов.


## 24.10.2026 · iOS-first: итальянский (IT) в исходниках

- [x] Семь исходных языков EN/RU/ES/FR/DE/PT-BR/IT у всех 4 iOS-продуктов, включая Watch/widgets; 899 IT-строк.
- [x] Android не расширялся; исходный перевод ещё не равен опубликованному релизу. [QA](docs/IOS_IT_PORTFOLIO_QA_2026-10-24.md).
- [x] Итальянские 6/6 iOS/watchOS builds, iOS UI 6/6 и Swift native unit 29/29 PASS.
- [ ] Редакторская и физическая приёмка, отдельное разрешение Apple.


## 24.10.2026 · iOS-first: pt-BR в исходниках

- [x] Шесть языков исходников RU/EN/ES/FR/DE/PT-BR во всех 10 компонентах iOS/watchOS/widgets, 899 строк pt-BR. [QA](docs/IOS_PTBR_PORTFOLIO_QA_2026-10-24.md).
- [x] Android не расширен; перевод исходников не равен опубликованному App Store языку.
- [x] Шесть iOS/watchOS сборок и pt-BR iPhone Simulator UI 6/6 PASS.
- [ ] Физическая/редакторская приёмка и отдельный Apple approval ещё нужны.


## 24.10.2026 · Локализация: DE для 4 iOS-продуктов в исходниках

- [x] Пять источников RU/EN/ES/FR/DE во всех 10 iOS/Watch/Widget bundles. [Акт](docs/IOS_DE_PORTFOLIO_QA_2026-10-24.md).
- [x] Pushkin и Ухват исправлены для реально действующего немецкого переключения. Android без изменений.
- [x] Немецкий iOS Simulator smoke всех трёх новых продуктов 3/3 PASS; Swift unit Pushkin 10/10 и Ухват 8/8 PASS.
- [ ] Это не новые публичные App Store версии: редакторская и физическая приёмка, отдельное согласование загрузок — открыты.


## 24.10.2026 · Актуальный портфель после уточнения релизов

**Этот блок имеет приоритет над более ранним Lookup-срезом от 24.10 и историческими секциями ниже.** По состоянию на сегодняшнюю сверку:

| Продукт | Опубликовано (RU) | Новая сборка / статус | Подтверждение |
| --- | --- | --- | --- |
| [Pushkin](../pushkin/ROADMAP.md) | 1.0.1 — последний датированный публичный Lookup | **1.0.2 (6) отправлена в App Review, WAITING_FOR_REVIEW, AFTER_APPROVAL** | [Авторизованная отправка](../pushkin/docs/PUSHKIN_1_0_2_APP_REVIEW_SUBMISSION_2026-10-24.md) |
| [Ухват / What?](../what/ROADMAP.md) | 1.1.0 — последний датированный публичный Lookup | **1.1.1 (9) отправлена в App Review, WAITING_FOR_REVIEW, AFTER_APPROVAL** | [Акт](docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md) |
| [ChickMark](../chickmark/ROADMAP.md) | 1.5.0 — последний датированный публичный Lookup | **1.5.1 (19) отправлена в App Review, WAITING_FOR_REVIEW, AFTER_APPROVAL** | [Акт](docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md) |
| [Фото и PDF под размер](../photo-pdf-to-size/ROADMAP.md) | **1.0.2 опубликована, подтверждено владельцем 24.10** | Отправка и проверка **завершены**; считать 1.0.2 публичной, не ожидающей App Review | [Предыдущий акт отправки](../photo-pdf-to-size/docs/appstore/RELEASE_1_0_2_SUBMITTED_2026-10-24.md) + подтверждение владельца |
| [Where?](../where/ROADMAP.md) | Нет опубликованного приложения | **PAUSED**, W0–W3 / E0–E5 не начинать без решения | Продуктовая дорожная карта |

Публикация Фото/PDF 1.0.2 зафиксирована **со слов владельца**, а не на основании нового внешнего Lookup; независимая сверка RU-витрины и регионов остаётся задачей Growth. Датированный публичный baseline 24.10 (1.0.1) ниже — историческое наблюдение **до этого подтверждения**. Входящие Apple-релизы не означают, что все физические release/UX gates закрыты. Каждой задаче принадлежит одна продуктовая дорожная карта; [Growth](../growth/ROADMAP.md) владеет верификацией публичных витрин и метриками, [Core](ROADMAP.md) — общими технологиями и release policy.


## 24.10.2026 · актуальный публичный RU App Store baseline

- [x] Apple Lookup подтверждает Pushkin **1.0.1**, Ухват **1.1.0**, ChickMark **1.5.0**, Фото/PDF **1.0.1**; дата/рейтинг и ограничения — [Growth baseline](../growth/docs/APP_STORE_BASELINE_2026-10-24.md).
- [x] Подготовлен deploy/rollback checklist для site PR #15; код сайта не развёрнут.
- [ ] Следующие выпускаемые бинарники требуют отдельных физических QA и авторизации. Нельзя путать опубликованную версию с последними изменениями main.

## 19.10.2026 · Core: необязательное обновление App Store интегрировано

- [x] [PR #133](https://github.com/arvectum2/arvectum-tools/pull/133) **MERGED в main** (`08107c3`): общий Apple Lookup / «Обновить» / «Позже» подключён к iOS ChickMark, Pushkin, Фото/PDF и Ухват. Core 19/19, iOS 4/4, watchOS 2/2 локально PASS. [Акт](docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md).
- [x] На изолированном iPhone 17 Pro симуляторе iOS 27.0 **4/4 E2E «Позже» + 1/1 «Обновить» PASS**, Core Release build PASS; см. [акт](docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md).
- [ ] Отдельная физическая проверка диалога и публикация будущих бинарников после app-specific QA/согласования. Публичные версии не изменены этой интеграцией; Where? на паузе, Android вне данного механизма.

## 19.10.2026 · Growth measurement access

Apple RU публичные оценки: Pushkin 0, Ухват 0, ChickMark 2 (5.0), Фото/PDF 2 (5.0). Для Analytics Reports текущий ASC API key получил **403** на всех четырёх приложениях. Не считать downloads/views/conversion равными нулю. [Документ](../growth/docs/APP_STORE_BASELINE_2026-10-19.md). РСЯ/SEO метрики ещё не сняты.


## 19.10.2026 · P0 progress после единой сверки

- [x] Pushkin App Review подтверждён WAITING_FOR_REVIEW, AFTER_APPROVAL; public 1.0 остаётся.
- [x] ChickMark simulator Water consent UI **2/2 PASS**, но physical iOS automation 2× timeout; реальный HealthKit journal clean из предыдущего независимого теста PASS.
- [x] Фото/PDF synthetic 4-page 0/90/180/270 на реальном iPhone: 2 999 791→464 545 байт; визуальная корреляция >0.99 по каждой странице. Прежние QA файлы восстановлены, production ничего не меняли.
- [x] Growth site PR #15 CI **verify и Mirror SUCCESS**, npm verify PASS; PR по-прежнему OPEN, деплоя нет.
- [ ] Ухват реальный звонок/30+ мин/Watch airplane/reboot и иные физические release gates не выполнены. Не путать готовность тестового кода с публикацией.


## 19.10.2026, вечер — единый реестр (актуально)

[Каноническая матрица публичных версий, PR и release gates](docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md). Apple RU Lookup: **Pushkin 1.0**, **Ухват 1.1.0**, **ChickMark 1.5.0**, **Фото/PDF 1.0.1**. Отдельно Pushkin **1.0.1(5) WAITING_FOR_REVIEW** (Apple build5 VALID, submitted 19.10.2026, автоматическая публикация **AFTER_APPROVAL**). Source features и физический QA других продуктов ещё не означают их новые Store-бинарники.

- [x] Pushkin PR #131 и восемь GitHub checks PASS; обязательные Shortcuts Notification E2E и безопасное обновление QA 8/8 PASS, временные команды удалены. Новый Apple Review submitted и подтверждён.
- [x] Ухват: физический 420s+завершённый MOV и background QA; ChickMark: PR #94 MERGED, HealthKit water в main, real QA выполнен, в public 1.5.0 функции нет.
- [ ] Ухват/ChickMark/Фото-PDF: отдельные device QA и согласование новых выпусков, отчёты в продуктовых Roadmap.
- [ ] Growth site PR #15 **OPEN/verify FAILURE**, не deployed; категория ChickMark по-прежнему Health & Fitness; метрики неизвестны.
- [ ] Where? и Growth Agent **PAUSED**, Core продолжает обслуживать только четыре активных приложения.

**Все блоки ниже — датированные исторические срезы.** Например, прошлые 1.0.1(4) review/ручной выпуск, draft #94 и незакрытая 8-минутная запись Ухвата больше не являются текущим статусом.


## 19.10.2026 — Pushkin App Review

Production Pushkin 1.0.1 build 5 uploaded to Apple and validated. New review submission confirmed WAITING_FOR_REVIEW, automatic release AFTER_APPROVAL. Eight GitHub checks passed. Public storefront remains 1.0 until Apple approves. Details: pushkin/docs/APPLE_REVIEW_SUBMISSION_1_0_1_BUILD5_2026-10-19.md.


## Pushkin: Physical notification-trigger QA completed, 19.10.2026

Physical iPhone incoming notification → new iOS 27 Shortcuts trigger → QA-only AppIntent → production capture/persistence code: PASS (one record, no duplicates). Both temporary commands deleted, zero on both Macs, five previous automations intact. Physical acceptance: ../pushkin/docs/PHYSICAL_NOTIFICATION_SHORTCUTS_E2E_ACCEPTED_2026-10-19.md. Public Pushkin remains 1.0, 1.0.1(4) is withdrawn. Production live-history upgrade remains untested; no Apple submission before owner approval, with AFTER_APPROVAL for future authorized release.


## Pushkin · сверено 19.10.2026 после PR #130

Публично **1.0**. Submitted 1.0.1(4) **отозвана**, `DEVELOPER_REJECTED`; будущая версия настроена на **AFTER_APPROVAL**, но новой подачи без разрешения владельца не будет. [PR #130 merged](https://github.com/arvectum2/arvectum-tools/pull/130), CI зелёный, физическая изолированная QA история и прямой App Intent прошли. Native trigger E2E всё ещё открыт из-за `shortcuts sign` 500/504. Пустой тестовый Shortcut точно удалён, прочие команды остались.


## Коррекция статуса Пушкина · 19.10.2026

Неавторизованная App Review отправка **1.0.1(4)** полностью отозвана: `reviewSubmission COMPLETE`, `version DEVELOPER_REJECTED`. Предпочтение владельца: после отдельного согласия на отправку — **automatic release** `AFTER_APPROVAL`, не ручной. Публично **1.0**. Новые QA-результаты: физический in-place upgrade **6/6 сохранены**, QA AppIntent 2 вызова → 1 SwiftData запись. Реальное Shortcuts Notification Automation ещё блокировано Apple `shortcuts sign` 500. Ни доработка кода, ни готовый IPA не разрешают отправку в Apple без отдельной команды; `AGENTS.md`.


## Актуальный статус публикаций · 19.10.2026

- **Пушкин:** публично App Store **1.0**; **1.0.1(4) VALID + WAITING_FOR_REVIEW**, ручная публикация после одобрения, PR #126 merged. Содержимое уведомлений пользователя не копировалось.
- **Ухват:** публично **1.1.0**; QA-исправления в `main`, физический 420s+background PASS, новая бинарная версия не подана Apple.
- **ChickMark:** публично **1.5.0**; native HealthKit water экспорт реализован и интегрирован в `main` (PR #94), личные/production данные не изменены, новая версия не отправлена.
- **Фото/PDF:** публично **1.0.1**, без изменений; **Where?** остаётся на паузе.


## Physical gate checkpoint · 19.10.2026

Подключённый iPhone 13: **Pushkin 20/20 physical unit/UI + 1/1 native signed Shortcut preview**; Ухват **420 s continuous capture + playable MOV with audio**, 18 QA notes preserved on update; ChickMark **15/15 physical QA** (13 fake HealthKit sync + 2 UI), реальный HealthKit одноразовый QA журнал неизменён и clean. Все доказательства в локальных app roadmaps. **Ни одна App Store версия не обновлялась.**


## Контроль исполнения · 19.10.2026

Пушкин [подписанный 1.0.1(4) / PR #126](https://github.com/arvectum2/arvectum-tools/pull/126), CI PASS, **не App Store**. Ухват [QA диагностика PR #127 MERGED](https://github.com/arvectum2/arvectum-tools/pull/127), непрерывный physical long-video gate открыт. ChickMark [draft вода PR #94](https://github.com/arvectum2/arvectum-tools/pull/94) только локальная интеграция. Growth [site PR #15](https://github.com/arvectum2/arvectum-site/pull/15), не развернут; ASC категория пока Health & Fitness. Источник конкретного выполнения — дорожные карты владельцев.


## Исполнение после публикаций · 19.10.2026

[Рабочая очередь](EXECUTION_PLAN.md): Pushkin 1.0.1(4) signed candidate, [draft PR #126](https://github.com/arvectum2/arvectum-tools/pull/126), **не App Store**; HealthKit water live QA отдельно доказана на одном тестовом образце, PR #94 draft; Ухват — остаётся физический long-video gate. Публичные версии не изменились.


## Актуальный публичный срез · 19.10.2026

[Сверка Apple RU storefront и следующая исполняемая очередь](docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md): **Pushkin 1.0, Ухват 1.1.0 и ChickMark 1.5.0 опубликованы**, прямой публичный Apple Lookup API. **Фото/PDF 1.0.1** без новой версии; **Where? на паузе**.

- [x] Снят прежний Apple-review gate для трёх опубликованных версий; **не считать физические тесты или новые изменения в `main` выпущенными**.
- [ ] Pushkin: безопасное удаление и Shortcuts/onboarding из `main` отсутствуют в публичной 1.0; безопасный patch — ближайший P0.
- [ ] Ухват: public 1.1.0(8) ≠ новые main-фиксы видеозаписи/Watch; физическая длительная запись и signed upgrade открыты.
- [ ] ChickMark: public 1.5.0, но CloudKit/HealthKit/native РСЯ физические gate открыты, экспорт воды в Health остаётся draft PR #94.
- [ ] Core iPad/Duo и Growth/ASO выполняются отдельно от статуса публичных iPhone-релизов; не выдавать код в `main` за одобрение устройств Apple.



## PR #90 объединён в main · 18.10.2026

- [x] Общий адаптивный Core, Ухват 1.1.0, ChickMark 1.5.0, Pushkin и Фото/PDF включены в стабильную main: c86bc54, 38/38 CI PASS. [Технический акт](docs/ADAPTIVE_MAIN_INTEGRATION_2026-10-18.md).
- [ ] Выпуск каждой iOS-версии остаётся независимым; код в main не означает опубликованную iPad-версию или одобрение Apple, не доказывает физический fold/unfold Duo.
- [ ] Экспорт воды в Apple Health живёт только в [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94) от main, не выпускался и не проверялся на реальном Apple Health.
- [ ] Growth и Where? на паузе по решению владельца.


**Ownership rule:** This file is an index, not a duplicate execution plan.
Every task has exactly one owning roadmap. Cross-project dependencies use links,
not copied checkboxes. Apps release independently.

**Исполняемая очередь 2026-10-15:** [Единый план работ без Where?](EXECUTION_PLAN.md). [A5: четыре подписанных кандидата, локальный audit и блокеры отправки](A5_SIGNED_RELEASE_CANDIDATES_20261015.md). Where? поставлен на паузу; остальные продукты, Core и Growth остаются в scope.

## Новый авторизованный срез Apple · 18.10.2026

[Read-only ASC API audit](RELEASE_STATUS_ASC_2026-10-18.md): у Ухвата **1.0.1 READY_FOR_SALE** (обновление относительно исторического среза ниже); **1.1.0 WAITING_FOR_REVIEW**; ChickMark **1.4.1 READY_FOR_SALE / 1.5.0 WAITING_FOR_REVIEW**; Pushkin **1.0 WAITING_FOR_REVIEW**; Фото/PDF **1.0.1 READY_FOR_SALE**. Более ранние таблицы ниже сохранены как датированная история и **не являются свежим состоянием Apple**. Состояние storefront, физического апгрейда и бизнес-метрик отдельно не проверялось.

## Срез портфеля · 18.10.2026 (по имеющимся релизным доказательствам)
**Источник:** [аудит отправок от 18 октября](https://github.com/arvectum2/arvectum-tools/blob/release/what-chickmark-20261018-rc1/what/docs/RELEASE_AUDIT_WHAT_CHICKMARK_2026-10-18.md). Это датированный документальный срез, **не новый live-опрос ASC**; WAITING_FOR_REVIEW не означает публикацию.

| Продукт | Последняя подтверждённая публичная iOS версия | Более новая ветка / кандидат | Открытый gate |
| --- | --- | --- | --- |
| ChickMark | 1.4.1(15), ASC READY_FOR_SALE 16.10 | 1.5.0(18) submitted 18.10 09:01 МСК, WAITING_FOR_REVIEW | Apple, storefront, безопасный upgrade |
| Ухват / UhWhat? | 1.0.0(5), ASC READY_FOR_SALE 15.10 | 1.1.0(8) submitted 18.10 09:01 МСК, WAITING_FOR_REVIEW | Apple, Watch/data/iPad acceptance |
| Фото и PDF под размер | 1.0.1(13), ASC READY_FOR_SALE 15.10 | 1.0.2(14) signed, upload не подтверждён | Files/PDF/РСЯ device QA |
| Pushkin | публикация не подтверждена | 1.0.0(1) WAITING_FOR_REVIEW при проверке 15.10 | повторная ASC проверка, Shortcuts/delete QA |
| Where? | нет | PAUSED, W0–W3/E0–E5 — план | команда на возобновление |

**Инфраструктура:** Xcode 27.1 и Duo runtime готовы, но Core adaptive уже в main (PR #90), однако app-specific iPad/Duo release acceptance ещё не завершён. **Growth:** измерение реальных установок и монетизации до любых закупок трафика или автоматизации.

## Product roadmaps
- [Фото и PDF под размер](../photo-pdf-to-size/ROADMAP.md) — photo/PDF resizing, document presets, exports, app-specific UX, implementation and QA.
- [Pushkin](../pushkin/ROADMAP.md) — notifications capture, history, onboarding, search, reliability and app-specific UX.
- [ChickMark / Habit Tracker](../chickmark/ROADMAP.md) — habits, tracking, recurrence, reminders and its app-specific UX.
- [Where?](../where/ROADMAP.md) — local-only object/photo storage, OCR and semantic retrieval.
- [What?](../what/ROADMAP.md) — Apple Watch capture, transfer, transcripts, voice inbox and semantic memory.

## iPad / iPhone Duo (портфельная адаптация, 2026-10-16)

Единая [матрица устройств, приоритетов и критериев QA](DEVICE_ADAPTATION_ROADMAP.md). Конкретные задачи принадлежат пяти продуктовым ROADMAP; статус устройства **не равен** статусу публикации, а iPad-код Ухвата пока находится в отдельной feature-ветке. Where? остаётся на паузе.

**Состояние инфраструктуры (16.10.2026):** Xcode 27.1 активна, CoreSimulator 1174.9.2 работает. **iOS 27.1 Runtime установлена, iPhone Duo создан и успешно загружен.** Тесты fold/unfold и интерфейсов приложений ещё не проводились. Общий адаптивный Core пока в отдельной feature-ветке, релизы не изменены. [Чекпоинты T0–T5](DEVICE_ADAPTATION_ROADMAP.md).

## Release status snapshot — 2026-10-15

This is a dated distribution status overview, not a second feature checklist. [App Store and Git provenance evidence](RELEASE_PROVENANCE_20261015.md).
Owner reports, actual App Store Connect checks and source/build verification
are different types of evidence. Unverified new approvals must not be assumed.

| Product | Last confirmed public iOS release | Pending Apple review | Evidence and remaining work |
| --- | --- | --- | --- |
| Фото и PDF под размер | **1.0.1 (13)** READY_FOR_SALE, authenticated ASC **2026-10-15** | None | Post-release PDF rotation fix [PR #72](https://github.com/arvectum2/arvectum-tools/pull/72) merged in main **but not in public 1.0.1**; 31/31 unit + 5/5 UI, CI success; physical Files/Photos/ATT and YAN real impressions OPEN [#73](https://github.com/arvectum2/arvectum-tools/issues/73); first-use Files/Save clean-simulator failures documented, deterministic CI [#74](https://github.com/arvectum2/arvectum-tools/pull/74) merged |
| ChickMark | **1.4.1 (15)** READY_FOR_SALE, authenticated ASC **2026-10-16** (Apple одобрила последнюю отправленную) | None | Post-build15 Cloud KVS/native ads changes staged as **signed A5 1.4.2 (16) RC** (NOT uploaded); A1/A4/A6/A7 physical/external gates remain open, [A5 evidence](A5_SIGNED_RELEASE_CANDIDATES_20261015.md) |
| Pushkin | Not published | **1.0.0 (1)** Waiting for Review, ASC **2026-10-15** | Build 1 VALID; deletion source fix #68 and local Shortcuts lookup fix #69 merged into main **but not in reviewed binary**; real-device QA pending |
| Ухват / UhWhat? | **1.0.0 (5)** READY_FOR_SALE, ASC 2026-10-15 | **1.0.1 (6)** Waiting for Review, independently reconfirmed 2026-10-15 | A2 source fix #70 merged into main (not submitted build), CI PASS; physical one-tap Watch/interruption/ACK QA open |
| Where? | Not released | None | MVP W0–W3 not independently implemented |

Android publication remains independent: no confirmed public Android release
for Фото/PDF. App-specific acceptance criteria stay with their own roadmaps.

## Cross-product roadmaps
- [Arvectum Tools Core](ROADMAP.md) — shared architecture, reusable packages, release tooling, CI, brand/design primitives.
- [Growth](../growth/ROADMAP.md) — acquisition, ASO, SEO, campaigns, retention, monetization strategy and portfolio analytics.

## Ownership decision guide
- Function or bug in one app → that app's roadmap.
- Reusable infrastructure serving at least two apps → Core; do not extract early.
- Discoverability, promotion, funnel, monetization experiments and metrics → Growth.
- Installing an ad SDK or rendering an ad in a specific app → that app; Growth owns business hypotheses and results.
- Store listing campaign and SEO page → Growth; assets and technical release validation → app when applicable.
- No task/status duplication across roadmaps; link to the owner.
- Git branches represent changes, not permanent app roadmaps.

## Status integrity
Checkboxes in legacy specs are historical evidence, not proof of the current App Store release.
When updating release status, record what is independently verified versus confirmed by the owner; source/build/tag provenance remains a separate release audit gate.
