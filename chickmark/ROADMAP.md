# ChickMark — актуальная дорожная карта

C17 IndieAppCircle: в форме новой привычки теперь можно создать собственную группу и назначить её без перехода в настройки. XCUITest PASS, без SwiftData migration. Candidate 1.5.3(21), подписанные QA/preflight и per-release approval.

C15 (27.10): 48 локализованных маркетинговых iPad JPEG вместо больших пустот, все заголовки 12 UI языков соответствуют реальным кадрам. [C15](../core/docs/ASO_C15_EDITORIAL_ACCEPTANCE_2026-10-27.md).

C14 (27.10): keywords оптимизированы в 15 региональных ASO-карточках; первый iPad-скриншот с пустым пространством требует улучшения перед публикацией. [C14](../core/docs/ASO_C14_KEYWORDS_VISUAL_GATE_2026-10-27.md).

C13: 11 переводных ASO-карточек с правильными терминами серий, отметок, Apple Watch и Health. [Редактура](../core/docs/ASO_C13_LINGUISTIC_EDITORIAL_2026-10-27.md).

C12: реальные раскрытые настройки напоминаний iPhone/iPad во всех 12 языках; отдельная корейская редактура и регрессионная защита терминов. [Акт C12](../core/docs/ASO_C12_EDITORIAL_2026-10-27.md). Нужны native-speaker и физическая HealthKit/Watch/CloudKit QA.

**C11 27.10:** 4 реальных сценария для каждого из 12 UI языков (список, создание привычки, прогресс, напоминания), настоящие iPhone/iPad кадры отслеживаются в [C11](../core/docs/ASO_NATIVE_CAPTURE_C11_2026-10-27.md); HealthKit/CloudKit/нативная вычитка ещё требуют QA.


## C10 — локализованные карточки (26.10.2026)

- [x] 16 draft metadata locales, включая HealthKit и рекламу без лишних обещаний; Apple field validation PASS.
- [x] Исправлены критичные смысловые ошибки KO в напоминаниях и recovery; editorial mechanical audit PASS.
- [ ] Финальная native-speaker редактура, iPhone/iPad/Watch screenshots, HealthKit/CloudKit/РСЯ физическая QA и signed RC; 16×4 headline specs готовы, реальные кадры ещё нет. [C10](../core/docs/EDITORIAL_ASO_C10_2026-10-26.md).

## C9 — KO iPhone/Watch/widgets (26.10.2026)

- [x] KO draft: iPhone 311 + Watch 22 + PhoneWidget 16 + WatchWidget 5, HealthKit InfoPlist и AppShortcuts.
- [x] 10 Swift unit + 1 Korean XCUITest PASS (синтетическое хранилище, CloudKit off).
- [ ] Вычитка HealthKit/permissions, реальные Watch, РСЯ и безопасный upgrade, новый подписанный RC.

[ASO-аудит](../core/docs/ASO_PUBLIC_AUDIT_2026-10-26.md).


## 26.10.2026 · C8 — актуальный статус ChickMark

- [x] 11 полных source-пакетов iPhone/Watch/widgets; новый onboarding переведён на 11 языков; native/VoiceOver QA PASS.
- [x] Публичная RU 1.5.1, категория Productivity; в коде RC **1.5.2 (20)**, не опубликован.
- [ ] KO во всех компонентах, физическая HealthKit/CloudKit/Watch QA, реальные показы РСЯ, редактура и новый IPA/SHA-256.

[Статус портфеля](../core/docs/LOCALIZATION_STATUS_2026-10-26.md).

## Release RC 26.10.2026

- [x] Restore Photo/PDF advertising consent, IDFA ATT prompt and analytics as previously deployed; no change to the live Apple privacy label.
- [x] Prepare versions Photo/PDF 1.0.3 (15) and ChickMark 1.5.2 (20).
- [ ] Test fresh binary, archive/sign/export and collect exact SHA-256. Owner per-build approval required for Apple uploads.


## 26.10.2026 · P0 — реклама больше не перекрывает привычки; onboarding готов в коде
- [x] VoiceOver 26.10 на Mac mini: Photo/PDF 2/2 + ChickMark 3/3 PASS; системный VoiceOver после тестов **выключен** и подтверждён через AppKit/Settings.

- [x] Native YAN блок `R-M-20183085-1` перенесён из sticky-футера в конец прокручиваемого списка; legal/ad assets не прячем, banner unit намеренно не подменяем Native ID.
- [x] Onboarding 3 шага: создание привычки → отметка выполнения → необязательные напоминания; есть «Пропустить», перелистывание и persisted completion. Существующим пользователям с привычками не мешает. 11 локалей.
- [x] 5/5 native UI PASS: новые сценарии onboard/skip/persistence + ad in-feed/no-fill/AXXXL.
- [ ] Проверить live Yandex fill/revenue и физический iPhone (offline); отдельный Banner ID при выборе баннера потребуется в РСЯ, не создан.

[Акт](../core/docs/PHOTO_CHICKMARK_REVIEW_QA_2026-10-26.md).


## 26.10.2026 · Signed IPA QA

- [x] Main/Watch/widgets Store-профили обнаружены; локальный автоматический экспорт App Store IPA PASS, codesign/SHA-256 PASS.
- [ ] IPA **1.5.1 (19)** ещё прежнего поколения. Новая версия/build после physical HealthKit/CloudKit/Watch/VoiceOver и human editor QA.
- [ ] Apple upload только с отдельным согласием. [Акт](../core/docs/IOS_SIGNED_IPA_GATE_2026-10-26.md).


## 26.10.2026 · PT-PT приёмка

- [x] PT-PT native iPhone UI 1/1 PASS (без реальных CloudKit данных).
- [ ] KO отсутствует, требуется перевод iPhone/Watch/Widget, human editorial, физический HealthKit/CloudKit и подписанный RC.

[QA](../core/docs/IOS_PTPT_KO_NATIVE_QA_2026-10-26.md).


## 26.10.2026 · App Store RU статус (read-only)

- [x] Apple Lookup подтвердил опубликованную **1.5.1**; категория **Productivity**. Свидетельство: [датированный реестр](../core/docs/APPLE_PUBLIC_LOOKUP_2026-10-26.md).
- [ ] Новые локализации этого цикла не входят в публичный бинарник; дальнейшие загрузки требуют нового RC/QA и отдельного согласования.


## 26.10.2026 · C6.1 локализация и релиз

- [x] zh-Hant Native UI **1/1 PASS**, пустое состояние/новая привычка, без личных CloudKit-данных.
- [x] pt-PT улучшены HealthKit, backup, привычки, включая Watch InfoPlist; структурный аудит PASS.
- [ ] KO исходники отсутствуют; нужна редактура, physical Watch/HealthKit/CloudKit и безопасное обновление.
- [ ] Capability-bearing provisioning и новый signed RC; Apple 1.5.1(19) Review статус 24.10 не обновлён; категория Productivity остаётся отдельной задачей live metadata.
- [ ] Не загружать в Apple без per-release approval. [QA](../core/docs/IOS_ZH_HANT_NATIVE_QA_2026-10-26.md).


## 25.10.2026 · ChickMark: zh-Hant и безопасная приёмка

- [x] Zh-Hant draft: iPhone 302, Watch 22, Phone Widget 16, Watch Widget 5 строк, InfoPlist/HealthKit/Siri AppShortcuts.
- [x] Селектор языка разделяет zh-Hant (TW/HK/MO) и zh-Hans (CN), подготовлены Swift unit/UI тесты.
- [ ] Native Simulator/Watch, редактура HealthKit/Siri/длинных строк, физический VoiceOver.
- [ ] P0: Water check-in/edit/undo на живом UI, revoke/regrant, CloudKit/Watch и недеструктивный upgrade.
- [ ] 1.5.1(19) WAITING_FOR_REVIEW на 24.10; Productivity сверить уже на публичной версии, не считать опубликованной по ASC edit state.

[QA C6](../core/docs/IOS_ZH_HANT_TIER1_DRAFT_2026-10-25.md).



## 24.10.2026 · ChickMark — zh-Hans iPhone/Watch/widgets

- [x] 302 iPhone + 22 Watch + 16 Phone Widget + 5 Watch Widget строк; HealthKit InfoPlist и Siri AppShortcuts.
- [x] Языковой выбор 简体中文, защитный fallback для традиционного китайского.
- [x] Китайский UI 1/1 и Swift unit 9/9 PASS.
- [ ] Физический Apple Health/Watch/VoiceOver и редактура согласий.
- [ ] Публичная версия и данные пользователя не менялись.

[QA](../core/docs/IOS_ZH_HANS_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · ChickMark JA

- [x] JA iPhone 302, Watch 22, Phone Widget 16, Watch Widget 5 строк.
- [x] Японский HealthKit InfoPlist, Siri AppShortcuts, выбор 日本語 из системы и приложения.
- [x] Japanese iPhone UI **1/1**, Swift locale unit **8/8 PASS**.
- [ ] Физический Watch/HealthKit/VoiceOver и японская редактура.
- [ ] Публичная версия и пользовательские данные не менялись.

[QA](../core/docs/IOS_JA_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · ChickMark — итальянский iOS/Watch/widgets

- [x] IT: iPhone 302 + Watch 22 + iPhone Widget 16 + Watch Widget 5; переведены HealthKit InfoPlist и Siri AppShortcuts.
- [x] Выбор Italiano в языке интерфейса доступен через полный каталог; параметры форматирования проверяет Core.
- [x] Итальянский iOS Simulator synthetic-store UI **1/1 PASS**, Swift unit **7/7 PASS**.
- [ ] Физический HealthKit/Watch/VoiceOver и профессиональная вычитка разрешений.
- [ ] Публичные версии и данные пользователя не менялись.

[Акт](../core/docs/IOS_IT_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · pt-BR ChickMark iPhone/Watch/widgets

- [x] pt-BR 302 iPhone + 22 Watch + 16 phone widget + 5 watch widget; HealthKit InfoPlist и Siri AppShortcuts.
- [x] ChickMarkLanguage распознаёт pt-BR из настроек устройства и приложения.
- [x] pt-BR iPhone synthetic-store new-habit UI 1/1 PASS, без изменения CloudKit.
- [x] Swift XCTest pt-BR: Pushkin 11/11, Ухват 9/9, ChickMark 6/6 PASS.
- [ ] Физический HealthKit/Watch/VoiceOver QA и экспертная вычитка.
- [ ] Публичные версии и пользовательские записи не изменены.

[QA](../core/docs/IOS_PTBR_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · ChickMark DE — iOS, Watch, виджеты

- [x] DE: iPhone 302, Watch 22, iPhone Widget 16, Watch Widget 5 строк; Siri AppShortcuts и HealthKit разрешения переведены.
- [x] Селектор языка допускает только полные каталоги; немецкий теперь доступен для выбора.
- [x] unsigned iOS и watchOS Simulator builds PASS, Core 37/37 PASS.
- [x] Немецкий UI Simulator synthetic-store 1/1 PASS (без изменений CloudKit).
- [ ] Физический HealthKit/Water/Shortcuts/VoiceOver QA и экспертная вычитка.
- [ ] Публичная версия ChickMark и уже отправленная на review 1.5.1 не менялись.

[Акт](../core/docs/IOS_DE_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · Текущее окно релиза и QA

- [x] **ChickMark 1.5.1 (19)** с RU/EN/ES/FR уже отправлен на App Review, WAITING_FOR_REVIEW, AFTER_APPROVAL. [Акт](../core/docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md).
- [x] Primary category **Productivity** проверена в редактируемом ASC AppInfo версии 1.5.1; последняя датированная публичная 1.5.0 ещё была **Health & Fitness**. Проверить фактическую смену после READY_FOR_SALE.
- [x] Safe scoped HealthKit water API QA и simulator consent PASS; не считать их полной hardware/UI приёмкой.
- [ ] **P0:** физический user-flow check-in/edit/undo и revoke/regrant для HealthKit, Watch/CloudKit sync, недеструктивный upgrade и пользовательский VoiceOver.
- [ ] **P1:** проверить опубликованные языки/скриншоты и продуктивность новой категории, затем работать с retention и review prompt без накруток.


- [x] 24.10.2026: ChickMark 1.5.1(19) отправлен на App Review после iPad 13 screenshot gate; WAITING_FOR_REVIEW и AFTER_APPROVAL; категория Productivity. [Акт](../core/docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md).


- [x] **24.10.2026: 4 языка, подписанный кандидат 1.5.1(19).** RU/EN/ES/FR во всех iPhone/Watch/widgets и French Shortcuts, PR #139 merged. Category Productivity в source; ASC ещё не изменён. [Свидетельство](../core/docs/FOUR_LANGUAGE_RELEASE_CANDIDATES_2026-10-24.md).


## 24.10.2026 · категория App Store — свежая публичная проверка

- [x] Официальный Apple RU Lookup подтвердил категорию **Health & Fitness**, genreId 6013, в опубликованной ChickMark 1.5.0. [Датированный baseline](../growth/docs/APP_STORE_BASELINE_2026-10-24.md).
- [ ] Выбранная владельцем **Productivity** ещё НЕ опубликована. Смена — только при отдельной авторизации редактируемой ASC версии; не создавать её автоматически. Физические HealthKit/CloudKit и safe upgrade по-прежнему открыты.

### UX/дизайн-код: очередь D2 (19.10.2026, план)
- [x] D4.3 (20.10): ссылка на прикреплённую заметку использует контрастный semantic accent и ≥44pt; меню «…» получило корректную подпись действия на RU/EN/ES. 2/2 unit локализации и UI разового напоминания с проверкой меню PASS. Физическая заметка/VoiceOver отдельно.
- [x] D4.4 (20.10): Мягкое возвращение при AXXXL — все 4 категории системного аудита включённого и выключенного экрана PASS; UI переключение + 2 unit локализации, всего 5/5 PASS, лог design-d44-restart-v14.log; обычный шрифт: дополнительный UI PASS (design-d44-restart-normal-v2.log). Физические QA и HealthKit остаются открытыми.
- [x] D4.1 (20.10): Today header 44pt, общий радиус карточек, первый запуск — прокручиваемое empty state без обрезания One-time reminder. Today/Manage accessibility audits **2/2 PASS**, Debug build PASS.
- [x] iPhone 17 Pro iOS 27: реальный VoiceOver Today PASS. Произносит ChickMark, Manage habits, Add, Today Marked: 0 of 2, 0%, Reading, Mark complete. Полный rotor/physical QA открыт.
- [x] 20.10: XCUIAccessibilityAudit Сегодня и Управление привычками на iPhone 17 Pro iOS 27 / AXXXL **2/2 PASS**. После исходного FAIL нижняя панель настроек вынесена в прокручиваемую область при Accessibility Type; язык и выбранное системное значение расположены двумя строками. Обычная About/Privacy/Support регрессия PASS.
- [x] 20.10: заполненный список с тремя тестовыми привычками и группой на реально форсированном SwiftUI AXXXL — **системный audit 4 категорий PASS**. Длинную строку удаления группы перенесли в доступное меню 48pt, привычки сохраняются; настройки достижимы прокруткой. Log: chickmark-filled-axxxl-verified-audit-20261020.log.
- [x] После изменений 2/2 unit локализации и 2/2 обычные UI тесты About/Manage — PASS (chickmark-filled-normal-locale-final-20261020.log).
- [ ] Физические VoiceOver/HealthKit, реальные группы с миграцией и полноценный сценарий удаления требуют отдельной приёмки.

- [x] Из-за семантики resolvedCount (выполнено или пропущено) используется «Отмечено: N из M»; EN/ES/RU, VoiceOver-значение и unit-тест 2/2 PASS, Simulator BUILD PASS.
- [ ] Проверить, нужен ли прямой первый шаг «Новая привычка» при сохранении разового напоминания; без предварительного переписывания навигации.
- [ ] iPhone 17 Pro AXXXL UI PASS: Сегодня → управление → привычка → расширенная история. Остаются тёмная тема, контраст и физический VoiceOver; мигрировать только доказанно общие токены.
- [ ] Не затрагивать выполнение привычек, HealthKit и рекламу без их QA.

Полный аудит: [единый дизайн-код](../core/docs/UNIFIED_DESIGN_CODE_2026-10-19.md).


## 19.10.2026 — App Store update prompt: E2E и релизная граница

- [x] Исходники общей проверки версии App Store и кнопок «Обновить»/«Позже» интегрированы в `main` (PR #133, коммит `08107c3`).
- [x] Симулятор iPhone 17 Pro / iOS 27.0, Debug-фикстура опубликованной версии `99.9.9`, **1/1 PASS**: новое окно, «Позже», повторное предложение при новом запуске; in-memory SwiftData без CloudKit/HealthKit.
- [ ] **Release gate:** при следующем отдельно разрешённом выпуске проверить реальный App Store URL, реальный установленный/опубликованный build, сохранность данных и поведение на физическом iPhone. До подтверждения не считать обновление доставленным пользователям.

Тестовый сценарий доступен только в Debug и исключён из Release. [Общая приёмка](../core/docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md).


## 19.10.2026 · P0 Water consent UI: simulator PASS, физический runner blocker

- [x] Изолированный **iOS 27 Simulator 2/2 PASS**, 0 ошибок: количество воды выключено по умолчанию, добровольное включение, Cancel и отказ разрешения не сохраняют opt-in. [Акт](docs/WATER_SETTINGS_QA_RECHECK_2026-10-19.md).
- [ ] **Физический UI STILL OPEN:** iPhone XCTest Runner дважды остановился на системном **Timed out while enabling automation mode**, до assertions; не считать UI hardware тест пройденным или доказанной ошибкой приложения.
- [x] Ранее отдельный реальный HealthKit QA 250→500→0→750→0 мл и удаление только собственных записей PASS. Этот факт **не заменяет** живые check-in/edit/undo, системный revoke/regrant или двухустройственный CloudKit.
- [ ] Публично ChickMark 1.5.0, HealthKit water по-прежнему только в source main; отправки новой версии не было.


## 19.10.2026, вечер — ChickMark: HealthKit water в main, не в публичной версии

**Текущее:** публично **1.5.0 (18)**, RU категория **Health & Fitness**. [PR #94](https://github.com/arvectum2/arvectum-tools/pull/94) **MERGED** в main — добровольный экспорт dietaryWater, выключен по умолчанию; версия в Store эту новинку не содержит.

- [x] Источник WaterHealthKitWriter и синхронизация встроены; **15/15** QA (13 fake HealthKit + 2 isolated UI) PASS; отдельный настоящий физический QA-цикл **250→500→0→750→0 мл** PASS без остаточных чужих samples.
- [ ] **P0:** пользовательский живой habit check-in/edit/undo + HealthKit Settings revoke→regrant (не mock) на iPhone, идемпотентность и точное удаление **только собственных** samples.
- [ ] **P0:** CloudKit на двух устройствах, backup/restore без риска пользовательских данных, Watch/widgets и signed in-place upgrade при следующем RC.
- [ ] **P1 · карточка Apple:** согласованная категория **Productivity**. Неподвижная публичная READY_FOR_SALE 1.5.0 ранее ответила **409** на PATCH; выполнить в следующей разрешённой редактируемой версии и перепроверить опубликованную карточку.
- [ ] **P1:** физические iPad/Duo/split/VoiceOver, межприложный одноразовый handoff из Ухвата с корректной дедупликацией и отказом разрешений.
- [ ] Для новой сборки/App Review получить отдельное согласие. Сама интеграция PR #94 не означает публикацию нового бинарника.

[Единый портфельный срез](../core/docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md). Ниже сохранены архивные состояния draft PR #94, теперь заменённые этим merge-результатом.


## ВЫПОЛНЕНО · 19.10.2026 — native HealthKit вода интегрирована

- [x] [PR #94](https://github.com/arvectum2/arvectum-tools/pull/94) **MERGED** (`b189a6a`), полный GitHub CI SUCCESS. Export `dietaryWater` в `main` с per-habit explicit opt-in OFF, отдельным выбором 10…1000 мл, RU/EN/ES и точным own-ID delete; **публичный бинарник 1.5.0 функции не содержит**.
- [x] Physical iPhone13 QA: 13 fake HealthKit sync+2 UI = **15/15 PASS**; одноразовый реальный HealthKit `WaterHealthKitWriter` + production sync engine **250→500→0→750→0** мл PASS; journal `completedClean`, **0 own residual**; второй запуск не повторил запись. [Доказательства](docs/PHYSICAL_WATER_EDIT_UNDO_2026-10-19.md).
- [ ] Осталось до App Review: проверка настоящего **UI** habit check-in→undo с HealthKit, iOS Settings revoke/regrant и безопасный переход личной базы/CloudKit/Watch. Эти сценарии **не** объявлять пройденными на основании engine-level QA.
- [ ] Сменить категорию App Store c Health & Fitness на **Productivity** в следующем *редактируемом* версии: published 1.5.0 API PATCH вернул 409. Новую версию и загрузку бинарника не создавать без отдельной полной приёмки.


## CM18-3 · физический iPhone 13, 19.10.2026

- [x] `ChickMark Water QA` `1.5.0(202)` на iPhone, **13/13 fake HealthKit sync + 2/2 UI = 15/15 PASS**, без ошибок/пропусков. Unit включают multi-checkin 250→500→750 мл, undo/reentry, revoke→regrant mock и раздельные дни; UI проверяет включение только по явному согласию и безопасный отказ. [Протокол](docs/PHYSICAL_WATER_QA_2026-10-19.md), [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94).
- [x] Журнал предыдущего тестового HealthKit write+delete (18.10) после текущих UI тестов **не изменился**: `completedClean`, `ownDeletionCompleted=true`, **0 residual**. Новых реальных sample не создавали, приложение пользователя/Watch/CloudKit не меняли.
- [ ] Настоящие изменения отметок через UI с живым HealthKit, revoke в iOS Settings и безопасный production upgrade остаются выпускным блокером. Не считать mock revoke физическим доказательством изменения разрешения.
- [ ] Категория Productivity будет доступна лишь при следующей редактируемой версии в ASC (текущая `READY_FOR_SALE` дала 409).


## CM18-3 · Дополнительные safe-unit тесты воды (19.10.2026)

- [x] В [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94), source `b673339`, добавлены **3 fake-HealthKit** регрессии: реальные изменения количества/undo/re-entry одного дня, revoke→regrant WRITE и независимые дни с удалением только нужного дня. `swiftc -frontend -parse` PASS; **новый GitHub CI ещё выполнялся** на момент фиксации, результаты не заявлять успешными заранее.
- [ ] QA real habit UI (несколько отметок/undo), физическое revoke/regrant и safe upgrade по-прежнему открыты. Существующая физическая проба одного тестового образца 250 мл, запись + own-source deletion 0 residual, уже подтверждена; повторные операции с личным Apple Health не проводить.


## Исполнение CM18-3 · уточнение физического HealthKit QA (19.10.2026)

- [x] **Подтверждена физическая запись и безопасное удаление:** по сохранённому [протоколу 18.10](docs/PHYSICAL_WATER_QA_2026-10-18.md) владелец разрешил write-only HealthKit в изолированном `ru.arvectum.tools.chickmark.waterqa`; production `WaterHealthKitWriter` создал **250 мл dietaryWater**, затем удалил только свой образец; повторная own-ID source-scoped проверка показала **0 оставшихся**. Данные пользовательского ChickMark/Watch не изменены; **в этом этапе не выполнялись повторные операции с Apple Health**.
- [x] **Дополнительная физическая QA:** 31 unit PASS и 2/2 UI PASS в отдельном QA-бандле; 276/276 полного iPad unit набора/2 UI ранее пройдены на ветке [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94).
- [ ] **Открыто до merge/release:** проверка через реальный UI нескольких отметок воды и undo, revoke/regrant, отказов и повторной попытки после прерывания; safe upgrade публичной 1.5.0 без нарушения CloudKit/Watch. PR #94 остаётся draft, экспорт **не опубликован**.


## Опубликована 1.5.0 · следующий релизный gate (19.10.2026)

- [x] **CM19-RELEASE:** Apple RU storefront подтверждает публичную **ChickMark 1.5.0** (18.10.2026 22:22:41 UTC): [карточка](https://apps.apple.com/ru/app/id6818711298). По релизной истории это отправленная 1.5.0(18); Apple Lookup не выдаёт build number. Старый «ждём Apple для 1.5.0» закрыт, чекпоинты ниже сохранены как датированные факты.
- [x] **CM19-SOURCE:** OneOff/Ухват, Gentle Restart и недельная сводка реализованы в источниках `main`; их релизный состав нельзя автоматически приписывать публичному build 18 без release-аудита. Экспорт воды в HealthKit остаётся **draft PR #94**, не опубликован.
- [ ] **CM19-P0 · Public QA:** недеструктивное обновление/сохранность привычек, one-off/Ухват, виджеты/Watch, CloudKit на двух устройствах, HealthKit Deny/Revoke, реальные native РСЯ и UX/accessibility; не перезаписывать production-данные backup restore.
- [ ] **CM19-P1 · Health WRITE:** довести PR #94 с idempotent dietaryWater, разрешениями, ограничением удаления только собственных образцов и полным регрессионным тестом; физическое подтверждение write/revoke перед выпуском.
- [ ] **CM19-P1 · UX и карточка:** онбординг и нативная навигация по обратной связи Raizy, iPad/Duo; отдельное изменение публичной категории **Health & Fitness → Productivity** пока не подтверждено Apple и принадлежит Growth/ASO.

[Общий аудит](../core/docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md).



## PR #90 объединён в main · 18.10.2026

- [x] Код ChickMark 1.5.0 и адаптивных экранов iPad/Duo находится в main после PR #90, 38/38 CI PASS; отправленный Apple бинарник 1.5.0(18) не менялся.
- [x] Тесты переходов, сохранности и layout на симуляторах пройдены; физический Duo не обязателен для продолжения разработки.
- [ ] Экспорт воды CM18-3: отдельно [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94), 276/276 unit, 2/2 iPad UI, не в main и не отправлен Apple. Реальный HealthKit write/delete остаётся релизным gate.


## Актуальный релизный чекпоинт · 18.10.2026
**Подтверждённая публичная версия:** ChickMark 1.4.1(15), ASC READY_FOR_SALE 16.10. **1.5.0 (build 18)** с разовыми напоминаниями Ухвата, Watch и виджетами **отправлена на App Review 18.10 09:01 МСК**; upload VALID, состояние WAITING_FOR_REVIEW, выпуск не подтверждён ([релизный аудит](https://github.com/arvectum2/arvectum-tools/blob/release/what-chickmark-20261018-rc1/what/docs/RELEASE_AUDIT_WHAT_CHICKMARK_2026-10-18.md)).

- [x] **CM18-0 · Кандидат:** OneOff для импортированных заметок Ухвата с UUID, полным локальным текстом, обратной ссылкой, защитой от дублей, privacy-safe уведомлениями и совместимым backup; production build 18, 245 unit и E2E PASS.
- [x] **CM18-1 · Физическая изолированная QA:** iPhone 13 — импорт, источник, повтор, реально доставленное уведомление, нажатие и открытие текста; публичную CloudKit/Watch базу при этом не меняли.
- [ ] **CM18-2 · Релиз:** дождаться решения Apple, READY_FOR_SALE и распространения; затем недеструктивная приёмка привычек, one-off, Watch/виджетов/CloudKit. Не путать предыдущий signed 1.4.2(16) с новым submitted 1.5.0(18).
- [ ] **CM18-3 · HealthKit WRITE / вода:** отдельный экспорт количественных чек-инов в Здоровье (dietaryWater), единицы/объём и явные права на запись, идемпотентность, повтор офлайн, изменение/удаление только своих записей. Ранее реализованное ЧТЕНИЕ HealthKit не закрывает экспорт.
- [ ] **CM18-4 · Приёмка и улучшения:** native РСЯ/fill и privacy, разрешение/отзыв HealthKit, Focus/quiet-hours, iPad/Duo, частичные цели; gentle restart, недельная сводка и отображение интервалов повторений — после обязательных gate.

**Границы:** одноразовый import владеет ChickMark, создание текста/звука и передача — [Ухват](../what/ROADMAP.md), общие адаптивные/StoreKit функции — [Core](../core/ROADMAP.md).


## CM18-3 · Версии после отмены и повторной записи (18.10.2026)

- [x] После удаления последней отметки воды номер HealthKit sync-версии сохраняется в локальном журнале; повторная отметка в тот же день использует следующую версию, не начиная нумерацию с 1.
- [x] Тесты write → undo/delete → add again, монотонности версии и повреждения нового журнала; полный набор **276/276 unit PASS**.
- [ ] Проверка реальных HKQuantitySample на физическом устройстве остаётся отдельным блокером выпуска.

## CM18-3 · Ручные настройки не перезаписывают повреждённый журнал (18.10.2026)

- [x] Перед запросом разрешения Apple Health проверяется целостность JSON согласия, подтверждённых записей и незавершённых операций.
- [x] Сохранение/отключение блокируется при повреждении журнала; исходные данные не перезаписываются, пользователь получает локализованную ошибку EN/RU/ES.
- [x] Новый тест сохранения при повреждении. **276/276 unit PASS**, **2/2 UI iPad PASS**. Реальные HealthKit операции остаются неиспытанными.

## CM18-3 · Усиление сохранности данных — 18.10.2026

- [x] Ошибка чтения SwiftData прерывает синхронизацию без изменения HealthKit; запрещено считать ошибку БД отсутствием привычек или отметок.
- [x] 4 новых регрессионных теста для обоих сбоев чтения и корректных пустых результатов. Полный регресс ChickMark **270/270 PASS**, экспортный UI iPad **2/2 PASS**.
- [ ] Проверка реальной HealthKit записи и удаления остаётся обязательной до пользовательского релиза; существующая Apple IPA не затронута.

## CM18-3 · Экспорт воды в «Здоровье» — фаза 1 (симулятор), 18.10.2026

Проверка приватности: системное разрешение HealthKit обновлено для EN/RU/ES и подтверждено по ресурсам собранного .app; CI-аудит теперь запрещает неверное обещание «не добавляет данные здоровья». При удалении привычки локальные настройки экспорта удаляются только после подтверждённой очистки собственных HealthKit-записей. Полный регресс 270/270; UI iPad и обычный iPhone по 2/2, включая запрет реального HealthKit в режиме UI-тестов и отказ без сохранения opt-in.



- [x] Настройка экспорта для количественной привычки, выключена по умолчанию, явные мл за отметку, тексты RU/EN/ES.
- [x] HealthKit dietaryWater writer; явное WRITE разрешение только при сохранении выбранного экспорта, удаление только собственных samples.
- [x] Синхронизация после локальных отметок, исправлений, отмены, отключения и удаления привычки; версия/идентификатор, durable pending после прерванных записей.
- [x] Полный ChickMark **270/270 модульных тестов**, **2/2 UI iPad и 2/2 UI iPhone** без реальных HealthKit операций.
- [ ] Проверка реальной авторизации, записи/удаления, отказа и повторных попыток в контролируемой среде с явно согласованными тестовыми данными.
- [ ] Приёмка Watch, доступности и отдельный App Store build; **CM18-3 пока не опубликована**.

[Протокол фазы 1](../core/docs/CHICKMARK_WATER_EXPORT_CM18_3_PHASE1_2026-10-18.md).

## CM18-3 · Экспорт воды в «Здоровье» — фаза 0, 18.10.2026

- [x] Количественная отметка не равна миллилитрам: объём (мл за отметку) задаётся явно, без догадок по названию привычки.
- [x] Локальное правило opt-in и план синхронизации, версии для идемпотентности, сценарии отмены и корректировок, защита других источников; 12/12 изолированных тестов PASS; полный ChickMark 257/257 PASS.
- [ ] HealthKit write permission, реальные HKQuantitySample, отказ и отзыв разрешения, retry.
- [ ] UI, связь с долговременными отметками, тесты сбоя и приёмка Apple Health.
- [ ] Следующий отдельный билд; CM18-3 пока не готовая пользовательская функция.

[Протокол фазы 0](../core/docs/CHICKMARK_WATER_EXPORT_CM18_3_PHASE0_2026-10-18.md).

## 1.5.0 + адаптивность · 18.10.2026

[Интеграционный QA](../core/docs/ADAPTIVE_CHICKMARK_1_5_INTEGRATION_2026-10-18.md): в отдельной ветке перенесён актуальный код уже отправленной ChickMark 1.5.0(18) поверх адаптивности, чтобы следующий релиз не потерял handoff заметок Ухвата, вложения, уведомления и backup. Core 13/13, ChickMark unit 245/245, iPad UI 2/2, iPhone/Duo UI 1/1 + 1/1, simulator build PASS. Исходная 1.5.0 (18) в Apple не менялась; не переиспользовать build 18 для нового выпуска.

## Адаптивный пилот ChickMark · 18.10.2026

[QA](../core/docs/ADAPTIVE_CHICKMARK_PUSHKIN_2026-10-18.md): iPad-ориентации, центрированные Today, sticky ad и HabitDetail; iPhone portrait без изменений. Debug build PASS; изолированная привычка/поворот на iPad и Duo **2/2 PASS**. Следом отдельные full QA, CloudKit, HealthKit и релиз; не трогать рассматриваемую Apple 1.5.0.

## Адаптация iPad / iPhone Duo — 2026-10-16

**Статус:** бэклог P1 после открытых стабильностных и релизных проверок; iPad/Duo пока не заявлять поддерживаемыми. [Общая матрица Core](../core/DEVICE_ADAPTATION_ROADMAP.md).

**Инфраструктура (16.10.2026):** Xcode 27.1 активна, общий адаптивный Core — отдельный прототип. CM-D0…D3 остаются открытыми; проверка на Duo ждёт iOS 27.1 Runtime (T3/T4). В опубликованном приложении ничего не меняем.

- [ ] **CM-D0 · Аудит устройств:** текущий iOS target iPhone-only; проверить включение iPad, orientations, SwiftData/CloudKit scene lifecycle, safe areas и экраны «Сегодня», список/редактор привычки, календарь, недельная сводка, HealthKit, виджеты и реклама.
- [ ] **CM-D1 · iPad:** адаптивные списки и детали привычек, календарь/статистика, редакторы, крупный шрифт, Split View/Stage Manager, клавиатура, VoiceOver; не менять алгоритм чек-инов и скользящего повторения.
- [ ] **CM-D2 · iPhone Duo:** свернутая/раскрытая компоновка, переход от списка к деталям, fold/unfold во время редактирования/отметки; никаких повторных check-in, откатов или конфликтов CloudKit при resize, split-window и фоне.
- [ ] **CM-D3 · QA и отдельный релиз:** iPhone regressions, iPad portrait/landscape/Split View, Duo folded/unfolded/resize, доступность и сохранность привычек, WidgetKit/Watch/HealthKit/CloudKit, рекламу проверять отдельно. Target family 1,2 только после завершения QA; опубликованную 1.4.1 не трогать.

**Источник истины:** этот файл. Прежняя дорожная карта целиком, со всеми исходными чекбоксами, датами и ссылками, без изменений сохранена в [архиве через 1.4.1 (15)](docs/history/ROADMAP-through-2026-10-14-build15.md). Дополнительные старые снимки — в docs/history/. Незакрытые пункты для тестовых сборок (9)–(13) и версий 1.3.x **не переносятся автоматически** в текущий план.

## Проверка Apple — 2026-10-16

- [x] **Apple одобрила последнюю отправленную ChickMark 1.4.1 (15)**. После сообщения владельца повторно выполнен авторизованный read-only запрос App Store Connect: **READY_FOR_SALE**; Apple App ID `6818711298`. [Публичная карточка](https://apps.apple.com/ru/app/id6818711298). Предыдущий срез от 2026-10-15 также показывал READY_FOR_SALE. **Не путать** с подписанной, но ещё не загруженной в Apple A5 1.4.2 (16) и с будущим P1 кодом 1.5.

## Единый срез портфеля — 2026-10-15

**Новый checkpoint A3:** [отчёт по сохранности, HealthKit, CloudKit, РСЯ и доступности](docs/A3_STABILITY_RECONCILIATION_2026-10-15.md): с физического iPhone в режиме чтения получено 4 привычки / 19 отметок / 20 изменений дня, как в предыдущем снимке; исходный потенциальный crash Cloud KVS при повторных ID устранён, добавлены два теста, полный локальный suite **216/216 PASS**; [PR #71](https://github.com/arvectum2/arvectum-tools/pull/71) слит в main (`1a65c96`), оба GitHub CI прогона (unit/UI/archive) **SUCCESS**, GitVerse SHA совпадает. Двух независимых iCloud-устройств для реальной сверки нет; отзыв HealthKit, боевые native-показы и физический VoiceOver всё ещё OPEN. Более свежая проверка ASC 2026-10-15: **1.4.1 (15) READY_FOR_SALE**, опубликована; прежний IN_REVIEW-срез устарел. [A5 подписанный кандидат 1.4.2(16)](../core/A5_SIGNED_RELEASE_CANDIDATES_20261015.md) не загружен. Новые исправления не входят в уже отправленную 1.4.1.


Публичная версия — **1.4.1 (15) READY_FOR_SALE**, подтверждена ASC API 2026-10-15. Подписанный **A5 1.4.2 (16)** пока локальный RC, не App Store. Спринт A:
A2 (реальный офлайн Watch), A3 (смена суток) и A5 (виджеты)
**закрыты**. Открыты A1 (CloudKit на двух устройствах),
A4 (физический отзыв разрешений HealthKit),
A6 (боевые показы РСЯ после установки обновлённого native-блока)
и A7 (физическая доступность/матрица устройств).
Исправление native-рекламы протестировано в **исходниках**,
но не входит в уже отправленный бинарник 1.4.1 (15).
[Портфельный статус](../core/PORTFOLIO.md).

## Текущий выпуск: 1.4.1 (15)

- [x] В публичном App Store — 1.4.1 (15), подтверждено ASC 2026-10-15. Версия 1.4.1 (15) собрана из main, подписана для App Store; iPhone, iPhone Widget, Watch и Watch complication имеют одинаковый номер; Production CloudKit и HealthKit разрешения проверены.
- [x] Владелец проверил на физических устройствах: клавиатура со стрелкой вниз, автоматическая галочка на Watch и самостоятельное обновление циферблата без открытия ChickMark. Задержка в одном испытании была более 25 минут; мгновенное обновление не гарантируется.
- [x] GitHub CI релизного кандидата и main успешен: [38615994169](https://github.com/arvectum2/arvectum-tools/actions/runs/38615994169) и [38619713713](https://github.com/arvectum2/arvectum-tools/actions/runs/38619713713).
- [x] What's New для RU/EN/ES-ES/ES-MX, App Review Notes, опубликованная политика конфиденциальности и восемь корректно заполненных категорий SDK App Privacy в App Store Connect.
- [x] Apple получила сборку 1.4.1 (15); свежая проверка App Store Connect 2026-10-15 показывает **READY_FOR_SALE** (latest 2026-10-15 ASC) (ранее Waiting for Review). Режим **AFTER_APPROVAL** ранее установлен и подтверждён; приёмка публичного распространения по-прежнему открыта.
- [x] **R1 — решение Apple:** 1.4.1 (15) перешла в READY_FOR_SALE, подтверждено ASC 2026-10-15.
- [ ] **R1 — региональная витрина:** при необходимости подтвердить доступность в целевых регионах; ASC READY_FOR_SALE не доказывает индексацию во всех странах.

[Акт подготовки публичной сборки](docs/RELEASE_CANDIDATE_1.4.1_PUBLIC_15.md) · [аудит App Privacy](app-store/metadata/privacy-review-1.4.1.md)

## Спринт A — стабильность и QA

**Цель:** недеструктивно подтвердить сохранность истории и согласованность поведения iPhone, Apple Watch, CloudKit, HealthKit, WidgetKit и рекламы. Детальный протокол и доказательства — [SPRINT_A_QA.md](docs/SPRINT_A_QA.md).

- [x] **A1 / A3 portfolio read-only физический срез 2026-10-15:** текущие счётчики 4 привычки, 19 отметок, 20 day-mutation совпали с предыдущей read-only выборкой; CoreDevice только копировал файлы, временная SQLite/WAL/SHM копия удалена. Исторические ID, миграция после следующего App Store обновления и второе независимое CloudKit-устройство **не проверены**. Новый guard для дублированных записей cloud group ledger и 2 XCTest, полный suite 216/216 PASS; [отчёт](docs/A3_STABILITY_RECONCILIATION_2026-10-15.md).
- [ ] **A1 · CloudKit, JSON backup и сохранение истории после обновления.** Модульные тесты и физическое чтение существующих данных; никаких restore-REPLACE или удаления приложения на устройстве владельца.
- [x] **A2 / PHYSICAL Watch offline undo -> iPhone persisted convergence, 2026-10-15:** Owner put Apple Watch SE into airplane mode and manually disabled remaining Watch Wi-Fi/Bluetooth; CoreDevice reported Watch unavailable while iPhone13 remained connected. For one dedicated QA Test 20261015 habit (not real user habits), owner marked complete from Watch online and the iPhone UI updated to 1/4; read-only app-container SQLite (including WAL/SHM) confirmed exactly one check-in and one day-mutation for that habit. Owner then unchecked the same habit on Watch while it was genuinely disconnected. During disconnection iPhone UI stayed at 1/4 and SQLite still had one check-in. Owner restored Bluetooth/Wi-Fi and confirmed reconnect; iPhone UI automatically converged to 0/4 without user edit, with QA habit unchecked. Fresh read-only SQLite confirmed QA habit still exists, 0 check-ins, 1 day-mutation, and 19 check-ins for other habits. No duplicate QA check-in and no change to any other habit were observed. **A2 functional physical offline-to-online acceptance CLOSED**, building on genuine simulator WCSession+explicit ACK+Watch-app restart and dedup PASS #63. Scope: physical UI/database on existing iPhone app **1.4.1(14)**, not yet upcoming build; physical Watch internal ACK ID inaccessible, tested by simulator and not independently read from real Watch; manual Watch restart during real outage was not performed. No physical iPhone upgrade, reset or HealthKit change. QA Test habit remains pending cleanup after owner allows it.
- [x] **A2 / paired watchOS+iOS SIM transport acceptance 2026-10-15:** Reused an already-booted/connected iPhone 18 Pro Max + Apple Watch Series 12 46mm simulator pair, updated ONLY the two test ChickMark apps to DEBUG build 15 after saving private simulated-data backups. No simulator reboot/new watchOS first boot. A DEBUG-only transport suppression flag simulated offline delivery while Watch commands persisted across app restart; latest check/undo replaced older pending commands. After restoring actual WCSession transfer, phone received and ACKed only latest action, Watch queue drained. Second delayed check wrote exactly ONE SwiftData check-in and ONE day mutation; online undo removed check-in, Watch and phone converged to 0/2, pending 0, ACK IDs identical. Added an explicitly opt-in paired-simulator QA script and ran it end-to-end: **SIMULATOR_A2_ACCEPTANCE_PASS**. **A2 simulator transport PASS, but physical radio disconnect/reconnect gate OPEN**. Complete iOS 214/214 unit PASS, generic watchOS build PASS, architecture/release/l10n PASS. No physical device used.
- [x] **A2 · WatchConnectivity offline → online.** Очередь, ACK, порядок команд, перезапуск и конфликт последнего действия; автоматический тест и физический smoke без сброса.
- [x] **A3 · Смена суток, DST и часовых поясов.** Календарный день, скользящие повторения, HealthKit и виджеты; эмуляция без изменения системного времени реального iPhone.
- [x] **A4 / owner physical HealthKit first-denial + manual fallback 2026-10-15:** On existing iPhone 13 ChickMark 1.4.1(14), linked ONLY disposable QA Test 20261015 to the HealthKit Sleep/day metric, not Steps used by existing Walk habit. Genuine HealthKit native permission sheet requested read-only Sleep access, initially OFF. Owner completed the system sheet without enabling Sleep and reported returning test habit to manual mode. App remained responsive after sheet, test habit detail displayed zero progress and zero checkins. Later read-only SQLite+WAL copy found 4 habits including QA, 0 QA checkins and 19 total checkins. No false Sleep completion, no Steps permission changes, no Health samples written. **A4 physical initial denial and manual fallback PASS; previously granted access revocation and regrant remain OPEN.** Earlier isolated denied/revoked unit tests PASS but do not substitute for physical access transitions. No new App Store binary installed.
- [ ] **A4 · Отказ/отзыв HealthKit.** Нет аварийного завершения и ложных автоматических галочек, ручной режим сохраняется; тестовая среда, без изменения согласий владельца.
- [x] **A5 · Виджеты Home/Lock Screen на iPhone.** Непустые данные, три семейства экрана блокировки, check/undo и обновление после смены дня; Watch face уже прошёл основной физический сценарий.
- [x] **A6 / live partner and physical-eligibility QA (2026-10-15):** authorized YAN MacBook Safari app list confirms ChickMark application 20183085 (Active, 1 ad unit), but its ONLY R-M-20183085-1 ad unit is **Native advertising**, whereas the iOS code passes this ID to Yandex **BannerAdView** with sticky BannerAdSize. This is a confirmed format mismatch and a release blocker for filled banner delivery; issue #59 records the remedy. Physical iPhone ChickMark 1.4.1(14) eligibility read-only check: first launch >13 days ago, 81 cold launches, 36 successful check-offs (all 3 gate thresholds met); a current app screenshot showed no banner, with no ad clicks or synthetic impressions. General partner report for Oct 9-14 showed 1.40 RUB aggregated over all in-app blocks, NOT attributable to ChickMark. YAN itself warns about reporting delay. **A6 remains OPEN until owner authorizes a new Banner ad unit or chooses an intentional Native SDK redesign, the next version is built, and per-unit fill/impressions are confirmed.** Neither advertising-account settings nor user check-ins were altered.
- [x] **A6 / approved pinned Native advertising, 2026-10-15:** User chose the already active Native YAN block R-M-20183085-1 over creating a Banner block. Replaced BannerAdView with Yandex Mobile Ads 8.6 SwiftUI NativeAdState/NativeAdContainer/NativeAdAsset and replaced configured YandexBannerAdUnitID with YandexNativeAdUnitID. Demo-native-app-yandex is DEBUG and opt-in only; eligibility remains 3 days + 5 cold launches + 3 completed checkoffs. A transparent 1pt anchor starts the first async request without allocating ad height; SDK load expands the card, no-fill/binding error returns space to habits. Real SDK demo Yandex Taxi creative loaded/impression callback observed. **Fixed a verified overlap defect:** navigation safeAreaInset let habit rows peek under ad, so footer is now a separate VStack sibling below the constrained ScrollView. **3/3 A6 UI acceptance PASS**: 12th habit above pinned ad after scrolling, AXXXL main controls accessible, no ad space for ineligible users. Dark-mode and AXXXL screenshot visually reviewed. **214/214 full iOS units PASS after final layout, 3/3 A6 UI PASS, watchOS simulator build PASS, architecture/release/l10n PASS**. **A6 external remains OPEN** for real partner fill/no-fill and per-unit impressions after the next release; no real ad traffic/clicks was generated, physical iPhone and Apple 1.4.1(15) unchanged. Issue #59 resolved in source, not yet in released build.
- [x] **A6 / native simulated no-fill + a11y rerun 2026-10-15:** Discovered a real no-fill layout defect: native ad failure kept an extra ~35pt empty footer on iPhone13 simulator (ScrollView bottom Y=809 vs 844). Updated failure and binding-error callbacks to unmount the whole native footer on unavailable ad, restoring all height to habit list. Added a DEBUG-only fake no-fill switch gated by native demo+XCTest so no real Yandex request/impression occurs. New UI test RED before fix, PASS after; previously merged pinned Native, AXXXL and ineligible scenarios also **3/3 PASS**, so **4/4 A6 targeted UI PASS**. Further A4/A7 simulator suite **5/5 PASS**, including real iOS 27 VoiceOver. Real R-M-20183085-1 fill/revenue remains OPEN until future release.
- [ ] **A6 · РСЯ.** Проверить боевой блок R-M-20183085-1, право показа, fill/no-fill, реальный показ и отчётность партнёра; компиляция SDK не доказывает рекламу.
- [ ] **A7 · Языки и доступность.** RU/EN/ES, крупный текст, VoiceOver, светлая/тёмная тема и верстка на поддерживаемых устройствах.

- [x] **A / автоматизированный старт 2026-10-14:** architecture, privacy/release hygiene, 12 PNG Store assets и generic watchOS build успешны; базовые 173/173 iOS unit и расширенные **177/177** iOS unit успешны. Добавлены четыре теста A2/A3: offline check→undo с поздним snapshot/ACK, команда прошлого дня, смена London↔New York и две DST-границы Нью-Йорка.
- [x] **A / интерфейсный smoke в симуляторе:** HealthKit-редактор и XCTest accessibility audit прошли первоначально; три старых сценария ввода (история, ES, крупный шрифт) обнаружили тестовую ошибку — отсутствие фокуса при программном вводе. Обновили тесты: **3/3 повторных запуска PASS**, плюс отдельно прошёл крупный текст для режима 5 отметок за день. В совокупности **6 UI-сценариев** имеют успешные прогоны, реальное устройство / все виджеты не проверены.
- [x] **A / недеструктивный осмотр:** на физическом iPhone установлена ChickMark 1.4.1 (14); не удаляли приложение, не меняли HealthKit разрешения и пользовательские записи.
- [x] **A1 / full-history upgrade, idempotent JSON/group merge and Cloud KVS conflict handling — 2026-10-15:** real temporary SQLite v1 store seeded with habit, day-keyed check-in, skip, pause and last-mutation record; opened under production v2 split-store configuration, added one-off reminder, restarted the container and verified exact IDs/day keys survived; JSON backup round-trip and repeated merge into a second in-memory device preserved its independent history without duplicates. Fixed JSON group merge that previously skipped missing membership in an existing group ID; existing device group names/assignments take precedence and incoming missing members are imported without duplicates. Fixed Cloud group ledger LWW tie if revisedAt **and** author coincide: deterministic payload tie-break, deletion and unassignment win ties, joins converge regardless of arrival order. **214/214 full iOS units PASS, watchOS simulator build, 12 Store PNGs, architecture/release hygiene/l10n RU/EN/ES PASS.** A1 stays OPEN for actual **read-only physical history count and second-device Production CloudKit convergence**; no user CloudKit or physical data modified.
- [x] **A1/A4 / дополнительная автоматизация 2026-10-14:** 4 новых регрессионных теста: повторный JSON merge всех типов истории без дублей, атомарное отклонение некорректного orphan check-in для merge/replace, отсутствие HealthKit-измерений в JSON и fail-closed проекция без медицинских данных. Фокусные 22/22 и полные **181/181** iOS unit, architecture и release hygiene — PASS. Реальный CloudKit, native HealthKit Deny/Revoke и устройства остаются открытыми.
- [x] **A7 / native VoiceOver and accessibility AXXXL QA 2026-10-15:** A real VoiceOver read found an unlabeled TodaySummary: the spoken value was only 0 of 2, 0%. The progress summary now exposes localized Today/Hoy/Russian today context plus the completed/total count and percent via one accessibility element, with stable today.summary identifier. Native XCUIVoiceOverService on iOS 27 **PASS** through Today, Manage habits, Detail and metrics. Legacy Manage test expectations were reconciled with the actual iOS 27 VoiceOver order. New AXXXL UI tests cover Home Manage/Add/complete actions, habit details, scrolling into expanded history, and progress accessibility labels/values in EN/RU/ES. Tests **PASS in light and dark modes**, including screenshots. Original audit 3/3 PASS; full 199/199 iOS units, architecture, release hygiene and RU/EN/ES localization PASS. **A7 remains OPEN for physical iPhone VoiceOver and full supported-device matrix.** Known iOS 27 Done-button contrast audit exception remains narrowly scoped. No physical devices, production user data, or submitted App Store 1.4.1 (15) were changed.
- [x] **A3/A5/A7 / расширение 2026-10-14:** защитили Home/Lock Screen widget intent от устаревших команд вчерашнего или будущего дня (после смены суток/часового пояса запрашивается refresh вместо изменения истории); локализованный VoiceOver value у малого кольца прогресса. Новые 2 теста, полный suite **183/183 PASS**; сборка iPhone Widget extension, RU/EN/ES audit, architecture, release hygiene и 12 Store assets — PASS. На симуляторе iPhone 13: **3/3 UI PASS** (автоматический аудит контраста/элементов и скриншоты RU/ES); отдельно английский сценарий в dark mode PASS. Скриншоты RU/ES извлечены в приватный QA-артефакт. **VoiceOver runtime / реальные непустые Lock Screen виджеты НЕ приняты:** служба AX iOS 27 не запустилась на iPhone 18 Pro и зависла при отдельной VoiceOver-проверке на iPhone 13; Android/физические данные не затронуты.
- [x] **A3 + A5 / owner physical midnight acceptance, 2026-10-15:** Owner confirmed that ChickMark widgets update by themselves after the local calendar day turns over, and the displayed day progress resets to **0** without manual refresh. Combined with the earlier automated calendar/DST/timezone and sliding-recurrence cases, genuine iOS Home/Lock Screen WidgetKit simulator tests for all supported families and check/undo, and the previously confirmed Watch-face update, **A3 and A5 are ACCEPTED / CLOSED**. This is owner-reported physical observation, not a new engineer-run test of real DST or travel. Real timezone travel and DST on a physical device were not separately witnessed; deterministic simulator/unit coverage stands for those edge cases. No phone clock, saved check-ins or App Store binary was changed.
- [x] **A3 / детальная регрессия 2026-10-15:** добавлены 5 проверок 23-/25-часовых суток New York, скользящих сроков от реального выполнения (несколько отметок подряд), устойчивого dayKey при перелёте London → Los Angeles, неполной цели 4/5 при DST/смене зоны и переключения горизонта виджета у местной полуночи. **39/39 профильных, 188/188 полных XCTest PASS**, архитектура и RU/EN/ES audit PASS. Закрыта автоматизированная часть A3; визуальное обновление WidgetKit в симуляторе у полуночи и физическая приёмка ещё не подтверждены. Бинарник 1.4.1 (15) не меняли.
- [x] **A4 / denied and revoked HealthKit regression, 2026-10-15:** Added an availability recheck immediately before publishing asynchronous Health queries, preventing stale automatic completions when access disappears while a read is pending. DEBUG-only isolated rule store and fake read/availability injections NEVER request native Health permissions or access real samples. New unit cases: zero/denied read fail-closed, successful reading followed by revocation (auto removed, manual check-in/history/link preserved, manual fallback remains usable), and availability lost during a successful in-flight read. **22/22 focused and 202/202 full iOS unit tests PASS**. Real iOS 27 simulator UI test uses --simulate-health-unavailable: linked save shows an error, turning off Health lets users save and manually complete the habit (**UI PASS**). Architecture, release hygiene and RU/EN/ES resource audit PASS. **A4 stays OPEN only for native system Deny/Revoke sheet and real device callback behaviour**; simctl privacy cannot control Health service. App Store 1.4.1 (15) and physical permission state untouched.
- [x] **A4 / HealthKit unavailable fail-closed, 2026-10-15:** Early unavailable-health exit now clears transient automatic checkmarks/progress and the local widget projection and notifies Watch/UI without changing SwiftData manual history or Health authorization. Three new regressions, including real coordinator refresh with injected unavailability: focused **19/19**, full iOS units **191/191**, architecture/release hygiene PASS. Native Deny/Revoke system sheet and actual Watch/Lock Screen widget visuals remain **OPEN**.
- [x] **CI / PR #45-#46:** all build-and-test, architecture, catalog and mirror checks PASS on 2026-10-15.
- [x] **A2 / pending Watch Health override + isolated transport trial, 2026-10-15:** Fixed a second offline/reconnect edge case: the Watch might temporarily suppress local Health auto-completion when manually unchecking a habit, but a phone snapshot merged before ACK could drop that temporary suppression. New optional Watch-only pending-command marker survives intermediate snapshots and blocks watchOS foreground/local complication Health re-completion only while its manual action is unacknowledged; it clears when explicit ACK arrives, preserving existing policy allowing a fresh Health threshold to auto-complete later. Backwards compatible with protocol v2 snapshots. **44/44 focused, 209/209 total iOS unit tests PASS, generic watchOS Simulator build PASS, architecture/l10n/release audit PASS.** Isolated iPhone 17 + Watch SE3 pair was created and reached connected status, but first-boot watchOS 27 daemon load spiked Mac mini above 300, before app installation or offline/ACK smoke; only this disposable pair was shut down and deleted. Existing test pairs were not modified. **Live WatchConnectivity transport remains OPEN.** Apple 1.4.1 (15) and physical owner data unchanged.
- [x] **A2 / explicit ACK-only Watch queue, 2026-10-15:** Fixed silent loss of pending Watch actions when a newer iPhone snapshot coincidentally matches a check, undo, or partial desired count but does not contain the command ID in its ACK list. Snapshot state is NOT proof of delivery; pending commands now leave the queue only after explicit iPhone acknowledgement. The previously state-acknowledged partial-target test is updated, plus four new cases for Health auto-completion disappearing/reappearing around a Watch undo, partial 3/5 goals, persistence through Watch restart, partial ACK of several targets and repeated/out-of-order snapshots. **28/28 focused, 206/206 full iOS units PASS, watchOS simulator build PASS, architecture/release/l10n PASS.** A2 remains OPEN for paired real offline-to-online WCSession ACK delivery and physical device smoke; owner records and Apple 1.4.1 (15) untouched.
- [x] **A2 / durable transfer dedup (2026-10-15):** repeated offline refresh no longer cancels and re-enqueues an identical WatchConnectivity transferUserInfo command. A genuinely new check/undo or incremental count supersedes only pending transfer(s) for the same habit and day; other dates and habits are untouched. Three regression tests; focused **22/22**, full **194/194** iOS XCTest, generic watchOS build, architecture and release hygiene PASS. **A2 remains OPEN:** real disconnection/reconnection and ACK delivery on paired devices have not been physically accepted.
- [x] **A2/A3 / Watch day-boundary guard 2026-10-15:** on-screen Watch taps (both check/undo and partial +/- goals) now reject stale/future-day snapshot keys and request current-day refresh before a new tap. Unlike Home Widget intent, Watch app previously lacked this protection. Added two DST/timezone tests: **24/24 focused, 196/196 full iOS unit PASS; watchOS Simulator scheme build, architecture/release hygiene PASS**. No change to saved user history or App Store version 1.4.1 (15).
- [x] **A2 / paired simulation deferred (historical blocker; superseded by paired simulator PASS #63 and physical offline/reconnect acceptance):** a dedicated clean iPhone 18 Pro + Watch Series 12 pair was created and connected, but first-boot watchOS 27 system daemons overloaded the Mac mini; Watch app installation stalled before live ACK testing. The isolated pair was stopped, unpaired and deleted, and logs kept in QA evidence. Do **not** mark real offline to online delivery as PASS; rerun on an already-provisioned pair when host is stable.
- [x] **A5 / календарная шкала WidgetKit (2026-10-15):** вместо единственной записи до следующего `reload` iPhone Home/Lock Screen виджеты получают 14 локальных календарных записей, подготовленных из уже существующего горизонта приложения; новое состояние дня планируется на местную полночь с учётом DST, повторный запрос данных — после окончания горизонта. Три новых теста: 14 последовательных дней, 23/25-часовые сутки, отсутствие вчерашних отметок при недоступном будущем снимке. **18/18 профильных, 199/199 полных XCTest PASS**, отдельная watchOS-сборка, architecture, release hygiene и RU/EN/ES localization PASS. **A5 остаётся ОТКРЫТЫМ:** реальные снимки и взаимодействия во всех трёх Lock Screen семействах, системное обновление на устройстве и check/undo визуально ещё не проверены. Отправленная Apple 1.4.1 (15) не менялась.
- [x] **A5 / on-screen Home Widget QA 2026-10-15:** on an isolated iOS 27 simulator (ChickMark-Compact-iPhone13), the real pinned systemMedium widget displays Water (5 times) 3/5, completes to 5/5 and 1/1 after its own button tap, and can be undone to 0/1 in the iPhone app. The SpringBoard XCUI check+undo test PASSED after simulator reboot; it SKIPs rather than falsely passing on devices without a preconfigured Home widget. Light/dark visual screenshots also PASS. The empty widget seen in an initially unsigned test build was caused by missing App Group registration; a locally signed simulator build correctly stored the current widget snapshot and 14-day horizon with no product-code changes. Lock Screen Collections/Customize editor was reached, but the three accessory families are NOT yet visually accepted: widget-gallery navigation was not reliable. No physical devices, CloudKit production, or App Review 1.4.1(15) binary changed. A5 remains OPEN pending Lock Screen, small Home widget, day rollover and real device scheduling.
- [x] **A5 / Lock Screen three-family on-screen QA 2026-10-15:** на изолированном iOS 27 симуляторе ChickMark-Compact-iPhone13 через настоящий редактор Apple установлены и проверены все три семейства **accessoryCircular, accessoryRectangular, accessoryInline**. После локального сидирования Water (5 times) снимок самого экрана блокировки подтвердил: строка над часами «0 of 1 today», прямоугольник «Today», 0/1 + Water (5 times), круглый прогресс 0/1. **Новый XCUI тест testA5LockScreenLiveAfterSeed PASS**: проверяет одновременно два отдельных WidgetKit-элемента, разные размеры их рамок, непустое название Water и строковый счётчик; в CI без предустановленных виджетов SKIP, не ложный PASS. Экспортированы реальные скриншоты Xcode из xcresult. В галерее перед установкой возможны пустые placeholder-превью; финальный статус подтверждён только после применения и обновления данных приложения. **A5 остаётся OPEN** для systemSmall Home, приёмки поведения реальной фоновой смены суток и физического устройства; 1.4.1 (15) не тронута.
- [x] **A5 / systemSmall Home WidgetKit QA 2026-10-15:** маленький виджет добавлен через штатную iOS-галерею на QA iPhone 13 симуляторе и найден на другом рабочем столе (не перепутан со средним виджетом). При сидированной привычке Water (5 times) systemSmall **вживую показывает кольцо 0/1 и «1 remaining»**; реальный medium рядом показывает Water 3/5. Новый testA5SmallHomeWidgetActualProgressRing использует SpringBoard, проверяет геометрию **именно systemSmall**, 0/1 и подпись; успешно прошёл в светлой и тёмной темах. CI без закреплённого виджета получает SKIP, не ложный PASS. Данные реального пользователя и 1.4.1 (15) не изменялись. A5 **остается OPEN только по системной смене суток без принудительной перезагрузки и физическому устройству**.
- [x] **A6 / статический аудит:** в production проекте указан боевой блок R-M-20183085-1, SDK включает отключение location tracking и user consent, gate — 3 суток + 5 запусков + 3 успешных выполнения; реальный fill и отчёт партнёра пока не подтверждены.

**Сводка по уровням приёмки, 2026-10-15:** все доступные автоматизированные проверки A1–A7 выполнены с зафиксированными результатами; это **не означает** закрытия спринта целиком. Открыты только подтверждения, требующие внешнего источника истины: A1 — существующая история и реальная синхронизация CloudKit на двух устройствах; A4 — настоящий системный Deny/Revoke HealthKit; A6 — аккаунт РСЯ и реальный заполненный/незаполненный показ с отчётом; A7 — физическая VoiceOver/поддерживаемые устройства. R1 ждёт решения Apple. Никакие user-device/ASC действия без отдельного разрешения не выполнялись. **Обновление приёмки (2026-10-15): A3 и A5 закрыты по подтверждению владельца о самостоятельном обновлении виджетов при реальной смене суток и сбросе прогресса до 0; автоматизированные DST/timezone и все поддерживаемые типы виджетов проверены ранее.** **Актуализация позднее 2026-10-15:** A2 теперь закрыт после подлинного физического Watch offline/reconnect теста с проверкой SQLite iPhone, в дополнение к сопряжённому симуляторному WCSession/ACK. Открыты A1 (мультиустройство CloudKit), A4 (системные разрешения HealthKit), A6 (боевые показы и отчёты РСЯ после релиза) и A7 (физическая доступность/матрица устройств); R1 зависит от проверки Apple. Ранее записанные незакрытые A2-гейты ниже — исторические срезы QA, а не актуальная задолженность.

**Правило закрытия:** различать unit, simulator, archive, real device, external account. Для полной приёмки нужен зафиксированный результат соответствующего уровня. Не изменять отправленный Apple бинарник незаметно; исправления после 1.4.1 — отдельная версия.

## Продуктовый бэклог после A

### P1 — ChickMark 1.5
- [x] **Gentle Restart — P1 MERGED [PR #77](https://github.com/arvectum2/arvectum-tools/pull/77), `fcc05e6`, 2026-10-16:** добровольное включение в Manage, локальный порог 3/7/14 дней, спокойная ненавязчивая карточка только для давно не отмечавшихся привычек. Никаких пропусков/серий/исторических чек-инов не переписывать; для интервальной привычки своевременный срок не считать перерывом. Xcode27 build, **222/222 unit**, **1/1 новый UI** и RU/EN/ES audit прошли. Два независимых GitHub CI прогона ([push 38856169226](https://github.com/arvectum2/arvectum-tools/actions/runs/38856169226) и [PR 38856175245](https://github.com/arvectum2/arvectum-tools/actions/runs/38856175245)) полностью **SUCCESS**, включая unit/UI и archive. GitVerse `main` синхронизирован с `fcc05e6`. **Открыта только [физическая приёмка #78](https://github.com/arvectum2/arvectum-tools/issues/78)**; Apple 1.4.1 (15) неизменна. Следующая P2 задача — [локальная недельная сводка #80](https://github.com/arvectum2/arvectum-tools/issues/80); вода в HealthKit — отдельная [#79](https://github.com/arvectum2/arvectum-tools/issues/79). [QA-план](docs/A7_GENTLE_RESTART_2026-10-16.md).
- [ ] Дополнительные edge-case тесты — часовые пояса, частичные цели, пересекающиеся интервалы выполнения с учётом результатов A3.

### P1 — UX: фидбэк Raizy (18.10.2026)
- [ ] **CM-UX-1 · Онбординг при первом запуске (Add onboarding):** короткое знакомство с ChickMark (создание первой привычки, отметка выполнения, напоминания/виджеты); возможность пропустить, вернуться к подсказкам из настроек. Уже активным пользователям не показывать обязательный онбординг после обновления; не сбрасывать историю и настройки. Проверить первый/повторный запуск, RU/EN/ES, Dynamic Type и VoiceOver.
- [ ] **CM-UX-2 · Не уводить пользователя из приложения по кликам (Clicks should not redirect to external browser):** провести аудит ссылок и CTA внутри ChickMark; внутренние действия открывать нативной навигацией, а необходимые веб-страницы — во встроенном просмотрщике с понятным закрытием/возвратом. Внешний браузер — только при явном намерении пользователя или технической необходимости (например, системная авторизация); не перехватывать произвольные/недоверенные URL. Проверить все точки перехода на iPhone/iPad, возврат, доступность и отсутствие неожиданного Safari.

**Источник:** отзыв о ChickMark на Raizy от 18.10.2026. Пункт «Add review request» относится к карточке Raizy, **не к приложению**; в бэклог ChickMark не включать. Эти задачи — будущие улучшения, не часть уже отправленной 1.5.0(18).

### P2
- [x] **Локальная недельная сводка — P2 [PR #81](https://github.com/arvectum2/arvectum-tools/pull/81) MERGED (`9159e1b`), 2026-10-16:** опциональная страница в Manage Habits (OFF по умолчанию); две законченные календарные недели, дни по расписанию, нейтральные пропуски/паузы, целевые недельные привычки и скользящие выполнения отдельно. Лучший день и тренд — по числу завершённых привычко-дней; HealthKit-linked привычки пока исключены, чтобы не подменять автоматическую историю ручными отметками. Нет сети, изменений SwiftData, фоновых напоминаний и экспорта HealthKit. [QA-протокол](docs/P2_WEEKLY_SUMMARY_QA_2026-10-16.md); **230/230 unit, 1/1 UI, iOS/watchOS-сборки PASS**; два независимых GitHub [push CI 38861433076](https://github.com/arvectum2/arvectum-tools/actions/runs/38861433076) и [PR CI 38861470827](https://github.com/arvectum2/arvectum-tools/actions/runs/38861470827) SUCCESS с архивами. GitHub/GitVerse main совпали. **Основная задача [#80](https://github.com/arvectum2/arvectum-tools/issues/80) CLOSED**, но физическая приёмка [#82](https://github.com/arvectum2/arvectum-tools/issues/82) остаётся OPEN; отдельное числовое отображение интервалов между скользящими выполнениями вынесено в [#83](https://github.com/arvectum2/arvectum-tools/issues/83) (не заявлять внедрённым). Опубликованная Apple 1.4.1(15) неизменна.
- [ ] Привычки сокращения / воздержания — отдельная семантика успеха, срыва и лимита, миграционные тесты.
- [ ] **Экспорт количественных привычек в Apple Health (HealthKit, запись; как в Yazio).** Например, пользователь отмечает 250 мл выпитой воды в ChickMark — в «Здоровье» появляется запись «Вода» на 250 мл (`dietaryWater`). Это **однонаправленный экспорт ChickMark → Apple Health**, независимо от уже существующего чтения HealthKit.
  - Настройка соответствия: тип привычки/метрика, единица измерения и объём одного выполнения или точное вводимое количество; для воды — мл/л. Нельзя превращать обычную галочку в произвольное количество без явной настройки.
  - Раздельные разрешения HealthKit на чтение и запись, явное включение экспорта для конкретной привычки; при отказе запись привычки в ChickMark продолжает работать, а ошибка экспорта отображается без ложного статуса успеха.
  - Идемпотентность при повторной синхронизации iPhone/Watch/CloudKit: один check-in → одна запись HealthKit; изменение количества корректирует экспорт, отмена/удаление удаляет только связанные записи, созданные ChickMark.
  - Проверки: отсутствие дублей, офлайн → повторная попытка, отказ/отзыв разрешения, смена дня/часового пояса, частичные цели; данные HealthKit не попадают в JSON-бэкап, аналитику и рекламу. Сначала вода, другие поддерживаемые HealthKit-метрики — после отдельной проверки соответствия и разрешений.
- [ ] Apple Reminders — создание напоминания по согласию, без дублирования и фиктивной двусторонней синхронизации.
- [ ] Apple Calendar — создание события по согласию без конфликтующих уведомлений.

### P3 / research
- [ ] Короткие заметки к выполнению — миграция, бэкап, синхронизация.
- [ ] Достоверное определение времени чтения — событие закрытия приложения не является доказательством прочтения.
- [ ] Дополнительные рекламные места — только при подтверждённом удержании и доходности.

## Правила ведения
1. Только действующие задачи и однозначные критерии приёмки; старые стадии не остаются открытыми рядом с новым выпуском.
2. Не путать успешный автоматический тест с физическим пользовательским QA.
3. Доказательства релиза, App Review и QA сохранять в документах, прошлые списки — в docs/history/.
4. При изменении релизных условий обновлять эту страницу и протокол спринта, не переписывая исторический документ.
