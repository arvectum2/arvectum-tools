# Arvectum Tools Core — дорожная карта

## 19.10.2026 — Единый дизайн-код Arvectum Tools (D0)

**Статус: оформлено и реализовано в отдельной ветке, не интегрировано в main.** Документ: [UX-аудит, микрокопирайтинг и дизайн-код](docs/UNIFIED_DESIGN_CODE_2026-10-19.md).

- [x] D0: исследование Apple HIG и релевантных приложений; проверка реальных экранов/исходников четырёх продуктов, фиксация ограничений бенчмарка.
- [x] D0: общие semantic tokens и метрики в SwiftPM Core, unit-тесты; без изменения существующего UI. **SwiftPM Core: 21/21 PASS на macOS 19.10.2026; продуктовые UI/build тесты остаются отдельной задачей.**
- [x] D3/P1 Итоговая сборка 20.10: Core swift test **21/21 PASS**; iOS Simulator Debug сборки Пушкин, Фото/PDF, ChickMark и Ухват **4/4 BUILD SUCCEEDED**. Подробная QA-матрица, выполненные и открытые ворота: [внутренняя приёмка](docs/UNIFIED_DESIGN_ACCEPTANCE_2026-10-20.md). Это не разрешение на релиз.
- [x] D1/P0 Pushkin: корректное описание охвата, RU/EN главных экранов; Debug iOS Simulator BUILD, 5 unit + 5 UI PASS. Не опубликовано.
- [x] D1/P0 Фото/PDF: CTA вне ScrollView, iPhone 17 Pro normal 2/2 PASS, iPhone SE normal 2/2 PASS и AXXXL 2/2 PASS; скриншоты проверены.
- [x] D1/P1 Фото/PDF: Files exporter фото/PDF 2/2 E2E PASS, сообщение после успешной записи, unit распознавания Cancel PASS; рекламная геометрия loaded/no-fill 2/2 UI PASS, доступность consent при AXXXL PASS. Live РСЯ и физические QA gates открыты.
- [x] D1/P1 Pushkin: контраст, компактный хедер, onboarding UX, unit/UI PASS и отдельный VoiceOver истории 1/1 PASS; secondary views и полная навигация/VoiceOver открыты.
- [x] D2/P1 Ухват: видимые Видео/Текст, один hint, склонение счётчика, library identifier, обновлённые UI-тесты; build, два UI и AXXXL UI PASS. Физический VoiceOver/iPad открыты.
- [x] D2/P1 ChickMark: семантически точный «Отмечено: N из M» для RU/EN/ES, Simulator BUILD и 2/2 localization unit PASS.
- [x] D2/P1 ChickMark: AXXXL core navigation и короткий VoiceOver Today PASS; полные сценарии создания, rotor/gestures, физический QA остаются открыты.
- [x] D3/P1 Pushkin: AXXXL onboarding/coverage и settings/privacy — 2 UI PASS, исправлена маленькая область нажатия в верхнем toolbar переносом явной кнопки 48pt вне скролла. Остальные VoiceOver и физические QA открыты.
- [x] D3/P1 VoiceOver: короткие тесты реальной речи в 4/4 iOS-продуктах PASS, включая отдельно результат фото и PDF (PDF PASS через SSH 20.10). Исправлены лишние Search Image Пушкина и декоративные изображения Фото/PDF. Полный rotor/physical QA остаётся.
- [x] D3/P1 Pushkin: системный accessibility audit **3/3 PASS** на основных История/Источники/Настройки, категории labels/hit regions/traits/text clipping. Исправлены обрезания pending-card, ссылки автоматизаций, поиска и quick-add. AXXXL Setup → каталог повторный UI PASS.
- [x] D3/P1 Фото/PDF: системный accessibility audit двух экранов результата **2/2 PASS** (sufficientElementDescription, hitRegion, trait, textClipped) на AXXXL simulator; отдельный PDF VoiceOver PASS. Исправлений по результатам этих двух аудитов не потребовалось.
- [x] D3/P1 ChickMark: системный audit Сегодня и Управление привычками **2/2 PASS**. При AXXXL панель настроек прокручивается вместо закрепления на весь экран; Language/System выводятся по строкам. Обычная About/Privacy/Support навигация PASS.
- [x] D3/P1 Ухват: системный audit Capture и Library **2/2 PASS**. При AXXXL статус хранения и счётчик заметок выводятся по строкам. Обычная Capture UI smoke PASS.
- [x] D3/P1 Ухват: 13-дюймовый iPad Simulator AXXXL: Capture → пустой текстовый редактор → Library → обратно PASS, поворот Library/Capture Portrait ↔ Landscape PASS (2/2).
- [x] D3/P1 ChickMark: действительно форсированный AXXXL, заполненные группы+привычки — системный audit 4/4 категорий PASS, меню группы 48pt, настройки доступны после прокрутки. 2/2 localization unit и 2/2 обычные UI регрессии PASS.
- [x] D3/P1 Ухват: синтетически заполненная библиотека, принудительный AXXXL — подписи/traits/обрезание PASS. Пустая библиотека и Home actions — обычная UI регрессия 2/2 PASS, прокручиваемый empty state.
- [x] D3/P1 Ухват: **закрыт hit region blocker** на заполненной библиотеке AXXXL. 64pt панель действий заменяет UIKit toolbar только при Accessibility Dynamic Type; полный 4-категорийный XCUIAccessibilityAudit iPhone/iPad PASS, функциональные действия и обычная навигация 4/4 UI PASS. Физические/Watch/VoiceOver-ротор проверки открыты.
- [ ] D3/P1 Реальные медиа, много групп, полноценный VoiceOver редакторов, iPad multitasking и физические устройства требуют отдельной регрессии.
- [ ] D3/P1 Полный VoiceOver (gestures/rotor), detail/modal screens, реальные Shortcuts, physical/iPad матрица открыты. PDF VoiceOver для результата выполнен в коротком проверенном сценарии.
- [ ] D3/P1: product UX QA (VoiceOver, Dynamic Type, тёмная тема, reduce motion) и отдельные UI PR для каждого приложения.
- [ ] D4: интеграция Core после review и независимые продуктовые релизы только по явному разрешению владельца.
- [ ] D5: Where? остается на паузе: только принципы в документе, не реализация.

## 19.10.2026 — необязательное обновление App Store (Core, единая задача)

**Статус: интегрировано в `main`.** [PR #133](https://github.com/arvectum2/arvectum-tools/pull/133) MERGED, squash `08107c3`; [техническая приёмка](docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md). Это не новая публикация в App Store.

- [x] Проверка опубликованной версии по Apple Lookup API при запуске, сравнение с установленной; диалог «Обновить» / «Позже», без принуждения и без блокировки офлайн. SwiftPM Core: 19/19 PASS.
- [x] Подключено к iOS ChickMark, Pushkin, Фото/PDF и Ухват; Xcode 27.1 iOS Simulator build всех четырёх: 4/4 PASS и watchOS 2/2 PASS (19.10.2026).
- [x] Изолированный iPhone 17 Pro Simulator: четыре app-specific UI-теста «Позже»/следующий запуск **4/4 PASS**, плюс positive «Обновить» на Pushkin **1/1 PASS**; Debug fixture исключён из Release, Core Release SwiftPM build PASS.
- [ ] Проверка перехода на реальную новую опубликованную версию с физического iPhone и отдельные авторизованные релизы; Where? после возобновления, Android — отдельный Google Play flow.


## 19.10.2026, вечер — Core: release provenance и адаптация

**Текущее:** [общий светофор](docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md). Публичная версия ≠ исходники в main ≠ App Review. Pushkin 1.0.1(5) уже WAITING_FOR_REVIEW и **AFTER_APPROVAL**; другие приложения выпускаются независимо.

- [x] **C0:** единый ArvectumCore (DesignTokens/Persistence/Diagnostics/AdaptiveLayout), PR #90 и **38/38 интеграционных CI PASS**, четыре активных продукта используют адаптивный слой в main.
- [x] **C1 этап Pushkin:** PR #131 **8/8 GitHub checks SUCCESS**, IPA release provenance и QA-переход с сохранностью 8/8, ASC build5 VALID, submitted WAITING_FOR_REVIEW.
- [ ] **C1 следующий:** после одобрения Apple сверить build5 READY_FOR_SALE, source SHA, signed archive, GitHub/GitVerse tag, RU/другие storefronts; не путать upload с publication.
- [ ] **C2:** сохранять зелёные архитектурные контракты, зависимости, iOS/watchOS и Android CI при изменениях Core, но не присваивать продуктовым тестам общий статус.
- [ ] **C3:** матрица iPad Split View, Dynamic Type/VoiceOver, scene lifecycle по каждому приложению. Отсутствие реального Duo не блокирует код/симулятор, но **не позволяет утверждать доказанную физическую смену экранов**.
- [ ] **C4:** общий review prompt использовать только с доказанным app-specific триггером успешного действия, без агрессивных запросов.
- [x] **C5:** не вводить общий Ads/HealthKit/Telemetrics API без минимум двух реальных потребителей с одинаковой семантикой.
- [ ] Where? остаётся на паузе, не начинать её через задачи Core.

Архивные разделы ниже оставлены для provenance, даже если ранние фразы о старых review-статусах теперь неактуальны.


## Публичный checkpoint · 19.10.2026

- [x] [Apple RU подтверждение](docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md): Pushkin 1.0, Ухват 1.1.0, ChickMark 1.5.0 опубликованы.
- [ ] Общий Core и iPad/Duo код в `main` не является доказательством включения этих устройств в публичные версии. Подписанный patch/source mapping и app-specific gate выполнять по [плану](EXECUTION_PLAN.md).



## PR #90 объединён в main · 18.10.2026

- [x] Исходники адаптивного ArvectumCore и четырёх активных приложений объединены в стабильную main через [PR #90](https://github.com/arvectum2/arvectum-tools/pull/90), squash c86bc54, **38/38 CI PASS**.
- [x] Ухват 1.1.0 multimodal, ChickMark 1.5.0, Pushkin и Фото/PDF используют общий адаптивный дизайн. Core 13/13, финальный независимый Ухват на обычном iPhone — 104 теста, 0 ошибок, 3 skip; Pushkin удаление — 3/3 unit и 3/3 UI.
- [ ] Отдельно остаются релизная приёмка приложений, реальные системные разрешения, физический Files/Photos/Camera/HealthKit/Shortcuts и App Store дистрибуция. Отсутствие реального Duo **не блокирует разработку**; симуляторный QA уже выполнен, реальное hinge/fold-unfold не подтверждено.
- [ ] C1: закончить пост-merge CI main и пересверить реальный ASC статус каждой сборки. Слияние исходников не меняет ранее отправленные Apple бинарники.

[Акт общей интеграции](docs/ADAPTIVE_MAIN_INTEGRATION_2026-10-18.md). Формулировки исторических разделов ниже, где описан пилот вне main, относятся к состоянию ДО PR #90.


**Актуально на 18.10.2026.** **Владелец:** общая архитектура, SwiftPM, CI, контракты данных, зависимости, инженерные стандарты и release provenance. **Опорное состояние:** [Baseline 2026-10-18](BASELINE_2026-10-18.md).

## Стратегия Duo · 18.10.2026

По решению владельца отсутствие реального Duo больше **не блокер**. Доступный критерий — симуляторный QA и дальнейшие исправления по обращениям. [Мультимодальный Ухват 1.1.0](docs/ADAPTIVE_T4_T5_MULTIMODAL_2026-10-18.md) проверен на iPad/Duo; не утверждать, будто проверено реальное складывание.

## Рабочий пилот iPad/Duo · 18.10.2026

[QA T4/T5](docs/ADAPTIVE_T4_T5_PILOT_2026-10-18.md) и отдельная feature/core-ipad-duo-pilots-20261018: два пробных приложения используют ArvectumAdaptiveLayout, 13 Core unit + 4 UI теста на Duo/iPad PASS. C3 остаётся открытой до state continuity/real fold/полного продукта и physical QA. Growth не затрагивали.

## Проверенная основа

- [x] Единый монорепозиторий и независимые релизы продуктов; каноническая интеграция в main.
- [x] Рабочий SwiftPM-модуль ArvectumCore: DesignTokens, Persistence, Diagnostics. Продуктовые данные/UX остаются внутри продуктов.
- [x] Архитектурный контракт, централизованный каталог версий, проверки SwiftPM lock-файлов.
- [x] Core CI с потребителями ChickMark, Pushkin, Ухват, Фото/PDF; отдельные проверки iOS/watchOS/Android. Зелёный кодовый CI не заменяет физическую проверку.
- [x] Xcode 27.1, iPhone Duo runtime и независимый прототип AdaptiveLayout; интегрированный адаптивный Core после PR #90 уже **в main**.
- [x] Связанный релизный реестр с разделением «публично», «отправлено Apple» и «исходники/QA».

## Приоритеты для следующих шагов

- [x] **C0 · Core baseline upkeep (P0, текущий checkpoint):** при существенном изменении общей инфраструктуры выполнить [проверку baseline](README.md#быстрая-проверка), обновить датированный протокол и подтвердить CI; не менять приложение без его релизных ворот.
- [ ] **C1 · Release provenance (P0, по событию):** после решения Apple сверить ASC/READY_FOR_SALE, source SHA, подписанные бинарники, теги, GitHub/GitVerse и физическую установку. Сейчас новые Ухват 1.1.0(8) и ChickMark 1.5.0(18) имеют статус **submitted**, не опубликованы по последним доступным доказательствам. [Портфель](PORTFOLIO.md).
- [x] **C2 · Поддержка CI (P1, проверка маршрутизации):** поддерживать dependency-impact coverage четырёх собираемых iOS продуктов, watchOS, Android, manifests и lockfiles; подключать Where? только после создания реального собираемого приложения. Регрессии отслеживать в owning roadmap.
- [ ] **C3 · AdaptiveLayout (P1, gated):** два реальных потребителя, совместимость iPad Split View/Stage Manager и iPhone Duo fold/unfold, Dynamic Type/VoiceOver, scene lifecycle; только после acceptance перенести компонент из feature/core-adaptive-layout-spike-20261016 в общий пакет. [Матрица](DEVICE_ADAPTATION_ROADMAP.md).
- [ ] **C4 · StoreKit review policy (P2):** локальная оценка квалифицированных сессий (3, затем 8, 13 и т. д.), вызов RequestReviewAction **после успешного действия**, без вмешательства в запись/обработку и без обещания показа/знания, оценил ли пользователь приложение. Общий API выделять после двух реальных потребителей, испытания — в продуктах.
- [x] **C5 · Аудит общих библиотек (gated, решение принято):** выделять новый API для ads/telemetry/privacy только когда минимум два стабильных приложения используют одинаковую семантику; без скрытых сетевых/пользовательских логов и новой зависимости ради абстракции.

## Закрытие контрольной точки · 18.10.2026

- **C0:** базовая команда `bash core/tools/verify_baseline.sh` подтверждает SwiftPM, архитектуру и каталоги; реальный PR CI подтверждает интеграцию. Следующие изменения требуют повторного запуска.
- **C1:** [авторизованный read-only срез Apple](RELEASE_STATUS_ASC_2026-10-18.md) выполнен; 1.1.0 Ухвата / 1.5.0 ChickMark / 1.0 Pushkin всё ещё **WAITING_FOR_REVIEW**. Полная provenance-проверка и физический rollout **зависит от будущего решения Apple**.
- **C2:** добавлена проверка обязательных GitHub Actions `on.paths` + unit-регрессии, синхронизированы триггеры Core package/catalog и потребителей; [контракт CI](CI_IMPACT_CONTRACT.md). Тесты продуктового поведения остаются за отдельными app workflow.
- **C3:** адаптивный Core и четыре потребителя прошли симуляторные тесты и были включены в main через PR #90. Отдельные публичные релизы, физические системные разрешения и реальная работа складного дисплея пока не доказаны.
- **C4:** [политика StoreKit и матрица QA](STOREKIT_REVIEW_POLICY.md) оформлена, **общий код не выделен** без двух потребителей; после пилотов — отдельный выпуск каждой программы.
- **C5:** сверены DesignTokens, Persistence, Diagnostics; дополнительных двух стабильных потребителей для Ads/Analytics/Privacy пока не показано. Завершён аудит и принято решение **не добавлять преждевременные библиотеки**. Новый общий модуль — только по отдельной подтверждённой необходимости.

## Что не включено в Core

- Сценарии отдельных приложений (запись, HealthKit write, Shortcuts, реклама, хранение пользовательских данных) принадлежат их [дорожным картам](PORTFOLIO.md).
- SEO/ASO, сообщества, активность Growth Agent, измерение дохода и закупка трафика — [Growth](../growth/ROADMAP.md).
- Where? — на паузе; запрещено начинать реализацию через «общие» задачи.

## Документы и история

[Baseline](BASELINE_2026-10-18.md) · [Принципы](CORE_PRINCIPLES.md) · [Контракт](ARCHITECTURE_CONTRACT.md) · [Список релизных ворот](RELEASE_CHECKLIST.md) · [Execution plan, историческая очередь среза 15.10](EXECUTION_PLAN.md) · [Архив прежней версии этого roadmap](history/ROADMAP_SNAPSHOT_2026-10-18.md).

**Правило:** один активный чеклист на уровень Core. Старые чекпоинты остаются как датированные доказательства, но не дублируют незавершённые задачи.
