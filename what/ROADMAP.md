# What? — Product Roadmap

## 28.10.2026 · P2 — импорт существующих записей через Files

- [x] В библиотеке Ухвата добавлен явный импорт аудио из системных «Файлов» (пустое состояние и меню настроек). M4A копируется без перекодирования, поддерживаемый WAV преобразуется локально в M4A; оригинал не перемещается и не удаляется. Файл сохраняется как защищённая аудиозаметка в существующем UUID-хранилище, исходное имя показывается и участвует в поиске; `displayName` опционален, старые Watch/iPhone JSON сохраняют совместимость. Воспроизведение, расшифровка и напоминания используют штатные механизмы.
- [x] Native XCTest **4/4** PASS: WAV→M4A с неповреждённым оригиналом и рабочим сохранённым аудио; M4A byte-for-byte; повреждённый M4A отвергнут без записи в индекс и без изменения источника; старый Watch JSON без имени декодируется. Существующие **15/15 Watch ACK/queue unit-tests PASS** (всего 19/19). Для импорта установлено ограничение 500 МБ и проверка длительности.
- [x] Native UI smoke: команда импорта доступна из заполненной библиотеки, `TEST SUCCEEDED`. Добавлены 6 локализованных строк для всех 12 языков; **91/91 Core pytest + 77 subtests PASS**; регрессии импорта включены в `what-ios-ci`.
- [ ] Требуется GitHub CI/слияние, реальная Files/iCloud/provider QA на физическом iPhone, VoiceOver и Android/другие форматы по отзывам. Публичное приложение не изменено, Apple upload только по отдельному разрешению.

## 28.10.2026 · C19 — iPad runtime восстановлен, базовая UI-приёмка

- [x] На iPad Air 11″ (M3), iOS 27.0 Simulator успешно завершились 2/2 XCUITest: portrait→landscape→portrait и библиотека/редактор/кнопка захвата. `xcodebuild TEST SUCCEEDED`, exit 0. Прежний блокер ограниченного iOS 27.1 runtime **обойдён другим совместимым runtime**, а не исправлен внутри 27.1.
- [ ] Split View, Stage Manager, реальная камера/mic, аппаратные прерывания и Watch остаются отдельными P0/P2 задачами. [Акт C19](../core/docs/IPAD_C19_ADAPTIVE_QA_2026-10-28.md).


## 28.10 · C18 · публичный статус подтверждён повторно

- [x] **1.1.2 в 16/16 регионах** по отдельным запросам Lookup; групповой Lookup 4 ID возвращал закэшированную старую 1.1.1 — не признавать эту ошибку источника откатом. Физические background/offline/Watch reboot и tap-through с ChickMark остаются OPEN. [C18 аудит](../core/docs/ASO_C18_PUBLIC_STORE_QA_2026-10-28.md).


## Актуально 28.10.2026 · опубликован C17

- [x] **Ухват 1.1.2 (10) опубликован:** 28.10 App Store Connect (только GET) вернул `READY_FOR_SALE`, `AFTER_APPROVAL`; публичный Apple iTunes Lookup подтвердил `version=1.1.2` в **RU, US и GB** (`currentVersionReleaseDate=2026-10-27T23:29:12Z`). 16 ASC локалей и 128 скриншотов были приняты на C17. [Историческое отправление 27.10](../core/docs/INDIEAPPCIRCLE_C17_APPLE_SUBMITTED_2026-10-27.md).
- [x] По отзыву IndieAppCircle добавлена подсказка о транскрипции, локализованная на 12 языков UI.
- [ ] P0: физический Watch→iPhone→ACK при блокировке экрана, offline/reconnect, долгой записи, прерывании, сохранении/восстановлении без риска личных файлов.
- [x] P1 source: opt-in «напомнить о заметке» +1/+2/+3 часа, восстановление разрешённых локальных уведомлений и согласованная приватная передача текста/ссылки в ChickMark реализованы; **31/31 регрессионных тестов PASS** в 28.10 прогоне, включая 13 тестов напоминаний и 3 теста handoff.
- [ ] P1 приёмка: тихие часы, фактический tap-through на физическом iPhone с установленным/отсутствующим ChickMark, отказ в доступе к уведомлениям и приватность lock screen. P2: импорт готовых телефонных записей и semantic memory после feasibility/правовой проверки.
- [x] Публичная версия 1.1.2 подтверждена **16/16** региональных витрин iTunes Lookup RU/US/GB/AU/CA/ES/MX/FR/DE/IT/JP/KR/BR/PT/CN/TW; ASC `READY_FOR_SALE` (28.10, только GET).

[Общий срез](../core/docs/ROADMAP_PORTFOLIO_2026-10-27.md).


## 28.10.2026 · Дополнение — физический реальный запрос и Apple Store

- [x] **iPhone 13 iOS 27.2 / Watch SE watchOS 26.6:** обновлены исключительно отдельные подписанные QA bundles; до/после очередь тестовых записей Watch 0, production apps и пользовательские медиа не менялись.
- [x] Под `WATCH_ROUTE_QA` добавлен одноразовый физический запуск без UI Automation: реальный iPhone `WCSession.transferUserInfo` подтвердил `phone-qa-manual-request=queued`. После безопасного foreground-запуска Watch QA с `what-watch-qa-audit` зафиксировано **`watch-sync-request-received` (1)** при нулевой очереди AAC. **Сквозной запрос с открытием Watch PASS**; полностью фоновая доставка без открытия Watch остаётся OPEN, сроки iOS не гарантирует.
- [x] **Физический UI XCUITest — PASS 28.10 09:44 МСК** на iPhone 13 iOS 27.2: нажатие `watchQueueRequestRecovery`, ответ `watchQueueRecoveryFeedback`, `TEST SUCCEEDED`, 15.971 с; в телефонном QA trace состояния queued/already-pending/rate-limited. Предыдущие `Timed out while enabling automation mode` и Locked больше не блокируют приёмку.
- [x] По публичному iTunes Lookup подтверждено `1.1.2` во **всех 16/16** ASO-регионах; App Store Connect read-only `READY_FOR_SALE`.
- [x] Исправлен исторический жёсткий счётчик локализации WhatIOS ES 232 → 237 с проверкой двух новых сообщений; локальные **61/61 Python localization tests PASS**. GitHub CI перепроверить на новом коммите.

[Физический QA-протокол](docs/PHYSICAL_MANUAL_WATCH_RETRY_QA_2026-10-28.md).

## 28.10.2026 · P0 фактическая приёмка и безопасный запрос повторной передачи

- [x] Актуальная iOS Simulator регрессия из `main`: **31/31 PASS** для `WatchA2ReliabilityTests` (15), `NoteReminderTests` (13), `ReviewNoteHandoffTests` (3); оригинальная очередь/ACK и приватность follow-up не переписывались.
- [x] Физический потерянный ACK/повтор того же UUID и восстановление оригинала на Watch подтверждены 19.10; проверка AAC перед ACK на настоящем iPhone подтверждена 22.10; физическое 420-секундное видео — PASS 19.10. Повторять эти сценарии без регрессии не нужно.
- [x] В отдельной исходной ветке добавлена кнопка **«Запросить передачу с часов»** в диагностику. Использует только уже существующий `syncRequest`/durable Watch pump, учитывает очередь запросов и cooldown 60 с; не удаляет/не читает личное аудио, не обещает мгновенный ACK. Сообщения и кнопка локализованы для 12 UI языков.
- [x] UI-тест ручного запроса передачи на iOS 27 Simulator: 1/1 PASS, 0 FAIL; повторный общий прогон 31 unit и 4 RU/EN/ES sync UI: **35/35 PASS**; XcodeGen membership и все 12 `.strings` PASS, общий локализационный аудит PASS.
- [x] Физический UI smoke нового запроса и все GitHub CI checks на `f34e41d` — PASS; **не часть** опубликованной 1.1.2(10). Документационная правка требует повторного green gate перед merge.
- [ ] **Аппаратный P0 остаётся:** после разрыва реальной радиосвязи eventual background-delivery при заблокированном iPhone без ручного foreground, Watch reboot с pending на текущей сборке, звонок/длинное прерывание и 30–120 мин/аппаратный ENOSPC только в безопасном QA окружении. Запись до ACK должна сохраняться; WatchConnectivity не гарантирует сроки фоновой доставки.
- [ ] Новые настоящие iPhone/Watch beta и публичные релизы — отдельные разрешения и per-build release gate. В этом цикле пользовательские заметки, radio-переключатели и системное сопряжение не трогались.

[Актуальная физическая матрица](docs/PHYSICAL_WATCH_ACCEPTANCE_DEDUP_2026-10-22.md) · [Background UX](docs/WATCH_BACKGROUND_DELIVERY_UX_2026-10-24.md).



Историческое состояние 27.10 (до публикации 28.10): C17 IndieAppCircle — понятная подсказка под непротранскрибированной записью на всех 12 языках UI; 232 iPhone key, повторные XCUITest PASS. Candidate 1.1.2(10), signed QA/preflight, ожидает per-release approval.

C15 (27.10): улучшено естественное KO название действия «Ухвати мысль»; подготовлены 48 маркетинговых iPad JPEG и повторная приёмка KO и заполненного settings menu. [C15](../core/docs/ASO_C15_EDITORIAL_ACCEPTANCE_2026-10-27.md).

C14 (27.10): keywords оптимизированы в 15 региональных ASO-карточках, а первый iPad-экран отмечен для проверки объясняющей ценности. [C14](../core/docs/ASO_C14_KEYWORDS_VISUAL_GATE_2026-10-27.md).

C13: переписаны ASO-переводы 11 регионов; исправлены Watch и транскрипционные keywords. [Редактура](../core/docs/ASO_C13_LINGUISTIC_EDITORIAL_2026-10-27.md).

C12: локализованная синтетическая библиотека с 2 заметками и заполненный редактор текста на 12 языках; оба режима iPhone/iPad XCUITest PASS; по 16 региональных слотов на каждом устройстве обновлено. [Акт C12](../core/docs/ASO_C12_EDITORIAL_2026-10-27.md). Ни один пользовательский файл не изменён.

**C11 27.10:** 4 реальных сценария на каждом из 12 UI языков (захват, библиотека, настройки, текст) на iPhone/iPad, проверенный манифест [C11](../core/docs/ASO_NATIVE_CAPTURE_C11_2026-10-27.md); содержание медиа/синхронизация Apple Watch на физических устройствах ещё требуют QA.


## C10 — локализованные карточки (26.10.2026)

- [x] 16 draft App Store метаданных; сохранён бренд UhWhat? и ограничения транскрипции и фоновой передачи Apple Watch, 100-byte keywords PASS.
- [x] Исправлены KO смысловые ошибки (перевод транскрипции, Watch/widget имя). Структурный аудит всего портфеля PASS.
- [ ] Редактура носителями, реальные iPhone/iPad/Watch screenshots, физический Watch ACK, новый signed release. [C10](../core/docs/EDITORIAL_ASO_C10_2026-10-26.md).

## C9 — KO iPhone/Watch/widgets (26.10.2026)

- [x] KO draft: iPhone 231 + Watch 6 + PhoneWidget 6 + complication 5, permissions, locale routing и счётчик; транскрипция независима.
- [x] 14 Swift unit и 1 native iPhone AXXXL KO UI PASS; без новых аудио/видео и изменения личных данных.
- [ ] Native speaker/permissions и физические Watch ACK, background, VoiceOver; затем новый signed RC.

[Сводка](../core/docs/LOCALIZATION_C9_2026-10-26.md).


## 26.10.2026 · C8 — актуальный статус Ухвата

- [x] 11 полных исходных языковых пакетов iPhone/Watch/widgets; PT-PT и zh-Hant native smoke PASS.
- [x] Публичная RU 1.1.1; подписанный IPA прежней версии — только QA.
- [ ] KO для iPhone/Watch/widgets, физическая Watch→iPhone ACK/фон/длительная запись, редактура/новый build и явный Apple approval.

[Статус портфеля](../core/docs/LOCALIZATION_STATUS_2026-10-26.md).

## 26.10.2026 · Signed IPA QA

- [x] Все 4 Store-профиля main/Watch/widget установлены, автоматический локальный экспорт IPA PASS, codesign/SHA-256 PASS.
- [ ] Подписанная IPA **1.1.1 (9)** повторяет прежнюю версию, **не upload-ready**; до нового release — новая версия/build и physical Watch ACK/VoiceOver/review.
- [ ] App Store upload только по отдельному согласию. [Акт](../core/docs/IOS_SIGNED_IPA_GATE_2026-10-26.md).


## 26.10.2026 · PT-PT приёмка

- [x] PT-PT native iPhone UI 1/1 PASS, синтетический AXXXL экран.
- [ ] Корейский KO пока отсутствует; Watch/Widget перевод, физический ACK/VoiceOver и signing заблокированы до приёмки.

[QA](../core/docs/IOS_PTPT_KO_NATIVE_QA_2026-10-26.md).


## 26.10.2026 · App Store RU статус (read-only)

- [x] Apple Lookup подтвердил опубликованную **1.1.1**; категория **Productivity**. Свидетельство: [датированный реестр](../core/docs/APPLE_PUBLIC_LOOKUP_2026-10-26.md).
- [ ] Новые локализации этого цикла не входят в публичный бинарник; дальнейшие загрузки требуют нового RC/QA и отдельного согласования.


## 26.10.2026 · C6.1 локализация и релиз

- [x] zh-Hant Native UI **1/1 PASS**, AXXXL synthetic экран без записи; pt-PT восстановление и разрешения отредактированы.
- [ ] KO пока отсутствует; нужна редактура/физическая VoiceOver/Watch ACK/background no-loss приёмка.
- [ ] Provisioning iPhone/Watch/widgets и новые signed RC; Apple 1.1.1(9) Review статус 24.10 не обновлён.
- [ ] Apple upload только с отдельным подтверждением версии/build/hash. [QA](../core/docs/IOS_ZH_HANT_NATIVE_QA_2026-10-26.md).


## 25.10.2026 · Ухват: zh-Hant во всех компонентах

- [x] Zh-Hant draft: iPhone 231, Watch 6, Phone Widget 6, complication 5 UI строк, InfoPlist; UI регион zh-TW/HK/MO не зависит от языка транскрипции.
- [x] Добавлены Swift/XCUITest для языковой маршрутизации и AXXXL без реального аудио.
- [ ] Xcode iOS/watchOS, VoiceOver, редактура permissions и физических Watch/widget.
- [ ] P0: Watch→iPhone ACK при фоне (~171 с наблюдалось), offline/reboot, звонок и 30+ минут, без риска личным записям.
- [ ] 1.1.1(9) WAITING_FOR_REVIEW по 24.10; публичный статус перепроверить, upload только отдельно разрешённый.

[QA C6](../core/docs/IOS_ZH_HANT_TIER1_DRAFT_2026-10-25.md).



## 24.10.2026 · Ухват — zh-Hans iPhone/Watch/widgets

- [x] 231 iPhone + 6 Watch + 6 Phone Widget + 5 complication китайских строк; системные разрешения.
- [x] CaptureBrand выбирает zh-Hans/zh-CN, не подменяет zh-Hant, форматирует китайские счётчики. Офлайн-транскрипция от языка UI независима.
- [x] Китайский AXXXL UI 1/1 и Swift unit 12/12 PASS (после обновления старого fallback теста).
- [ ] Реальный Watch/VoiceOver/permissions и редактура.
- [ ] Личные аудиофайлы и очередь Watch не трогали.

[QA](../core/docs/IOS_ZH_HANS_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · Ухват JA

- [x] iPhone 231, Watch 6, Phone Widget 6, Watch Complication 5 японских строк.
- [x] JA InfoPlist и разрешения; CaptureBrand поддерживает ja-JP, счётчик 件のメモ.
- [x] Язык интерфейса не связан с независимой настройкой транскрипции.
- [x] Japanese iPhone AXXXL UI **1/1**, Swift unit **11/11 PASS**.
- [ ] Физический Watch/VoiceOver и редактура, отдельное согласование релиза.
- [ ] Личные аудиофайлы и очередь Watch не изменялись.

[QA](../core/docs/IOS_JA_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · Ухват — итальянский для iOS/Watch/widgets

- [x] IT: 231 iPhone + 6 Watch + 6 Phone Widget + 5 Watch Complication.
- [x] Итальянские системные разрешения и реальный выбор it/it-IT в CaptureBrand; nota/note. Язык интерфейса не означает поддержку итальянской локальной транскрипции.
- [x] Итальянский iPhone AXXXL Simulator UI **1/1 PASS**, Swift unit **10/10 PASS**.
- [ ] Физический Watch/VoiceOver, редакторская вычитка, релизный approval.
- [ ] Личные записи и очереди Watch не изменялись.

[Акт](../core/docs/IOS_IT_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · pt-BR Ухват iPhone/Watch/widgets

- [x] pt-BR 231 iPhone + 6 Watch + 6 phone widget + 5 complication; системные InfoPlist разрешения.
- [x] CaptureBrand поддерживает pt-BR/pt_BR, nota/notas; язык транскрипции независим.
- [x] pt-BR iPhone AXXXL UI 1/1 PASS, без записи реального аудио.
- [x] Swift XCTest pt-BR: Pushkin 11/11, Ухват 9/9, ChickMark 6/6 PASS.
- [ ] Физический Watch/VoiceOver, редактура и релизный gate.
- [ ] Личные аудио и очередь Watch не менялись.

[QA](../core/docs/IOS_PTBR_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · Ухват DE — iPhone, Watch и виджеты

- [x] DE: iPhone 231, Watch 6, iPhone Widget 6, Watch Complication 5 строк. Дополнительные InfoPlist разрешения переведены.
- [x] CaptureBrand маршрутизирует интерфейс на DE, форматирует de_DE и склоняет Notiz/Notizen.
- [x] unsigned iOS/watchOS Simulator builds PASS; Core проверка ключей/параметров PASS.
- [x] Немецкий iOS AXXXL Home UI 1/1 PASS и Swift LanguageFallback unit 8/8 PASS.
- [ ] Физический Watch/VoiceOver/AXXXL, редактура; немецкая речь не обещается (транскрипция — отдельная настройка).
- [ ] Не затрагивать личные аудиозаметки и очередь Watch; релиз только с отдельным разрешением.

[Акт](../core/docs/IOS_DE_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · Текущее окно релиза и следующая приёмка

- [x] **Ухват / What? 1.1.1 (9)** с четырьмя языками и Watch/widget уже отправлен на App Review: WAITING_FOR_REVIEW, AFTER_APPROVAL; публично по последнему датированному RU Lookup — 1.1.0. [Акт](../core/docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md).
- [x] Физическая Watch→iPhone cold-background доставка и ACK подтверждены адресно; очереди и защита файлов проверялись. Задержка другого фонового маршрута около **171 с** измерена, своевременная повторяемая доставка не доказана.
- [x] Пояснение об opportunistic background transfer, хранении Watch AAC до ACK и не-live статусе очереди разработано и слито; физическая проверка VoiceOver остаётся открытой.
- [ ] **P0:** после review подтвердить READY_FOR_SALE; выполнить физическую пользовательскую приёмку ожидания/доставки, восстановления и доступности, без повторов закрытых QA.
- [ ] **P1:** звонок/interrupt, длительное видео, reboot→first unlock, ENOSPC и backup/restore — только в изолированном безопасном QA-контуре и без вмешательства в личные медиа.


- [x] 24.10.2026: Ухват 1.1.1(9) отправлен на App Review с 4 языками, WAITING_FOR_REVIEW и AFTER_APPROVAL. [Акт](../core/docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md).


- [x] **24.10.2026: 4 языка, подписанный кандидат 1.1.1(9).** RU/EN/ES/FR во всех iPhone/Watch/Widget/complication, PR #138 merged. [Свидетельство](../core/docs/FOUR_LANGUAGE_RELEASE_CANDIDATES_2026-10-24.md). App Review ещё не отправлен.


## 24.10.2026 · UX задержанной доставки — готов в feature-ветке

- [x] Вместо предположения о мгновенной доставке iPhone поясняет сохранение AAC на Watch до ACK и негарантируемое фоновое ожидание; для пустой последней очереди не заявляет синхронизацию в реальном времени. RU/EN/ES + unit 1/1 PASS, локализационный аудит PASS. [Акт](docs/WATCH_BACKGROUND_DELIVERY_UX_2026-10-24.md).
- [ ] Отдельные CI, физический UI/VoiceOver и аппаратная повторяемость background остаются открытыми до приёмки.


## 24.10.2026 · Физические фоновые условия получены

- [x] QA bundle на iPhone 13 запущен; журнал 38 событий подтверждает active → Settings/background → active; refresh=available, lowPower=true, protectedData=true, WCSession activated, paired=true, watchInstalled=true, reachable=false. Новых AAC нет. [Акт](docs/WATCH_BACKGROUND_WAKE_POLICY_QA_2026-10-24.md).
- [ ] Проверить продуктовый UX задержанной передачи/очереди; Low Power — гипотеза, а не доказанная причина задержки ~171 с.


## 24.10.2026 · Фоновые условия iPhone: инструментация без новых аудиозаписей

- [x] Только в QA добавлен снимок Background App Refresh, Low Power Mode, protected data, scene phase и WCSession на MainActor. Подписанная сборка установлена на физический iPhone 13. [Протокол](docs/WATCH_BACKGROUND_WAKE_POLICY_QA_2026-10-24.md).
- [ ] Физические значения пока не получены: iOS отклонила запуск QA-приложения с RequestDenied: Locked (телефон заблокирован). Не разблокировали удалённо и не меняли настройки.
- [ ] После обычной разблокировки пользователя — один замер active → Settings/background → active и чтение QA-событий. Новые Watch AAC создавать не нужно.
- [x] Apple подтверждает opportunistic delivery без SLA; произвольные background capabilities в production не добавляли.
- [x] Исправлен несинхронизированный штатный What.xcodeproj: ссылки на ранее добавленные Swift-исходники восстановлены; после XcodeGen штатная iOS/watchOS-сборка без подписи проходит, добавлен семантический CI gate совпадения Swift source membership (не буквального форматирования pbxproj).


## 22.10.2026 · Измерен реальный маршрут WatchConnectivity

- [x] QA-only журнал времени/UUID на обеих физических сторонах и режим синтетического AAC без 10-секундного удержания. [Физический протокол](docs/PHYSICAL_WATCH_WCSESSION_ROUTE_TIMING_2026-10-22.md).
- [x] Watch isReachable=false: transferFile scheduled, watch-side completion за 0.328 с. iPhone didReceive(file:) только через 170.883 с при возврате из background; ACK/commit быстрые, 4 уникальных UUID, пустая очередь Watch.
- [ ] Своевременная повторяемая фоновая доставка всё ещё OPEN; не приписывать задержку автоматически багу iOS без дополнительных системных данных. Следующая новая задача — исследовать условия пробуждения фонового iPhone, без повторов базовых ACK/offline тестов.

## 22.10.2026 · Сверка Watch QA без повторов

- [x] [Единая матрица физических PASS / PARTIAL / OPEN](docs/PHYSICAL_WATCH_ACCEPTANCE_DEDUP_2026-10-22.md) сверяет 13/19/22 октября. Уже проверены 3 записи при реальном offline, частичный reboot, две записи без открытия iPhone, реальный lost ACK и 1 cold-background доставка. Исторические TODO ниже не отражают более поздние результаты.
- [x] Новый тест: обычный iPhone background через Settings, **PID 45941 сохранился**; Watch UUID 2BFE4FBF оставался в очереди до foreground; при возврате в тот же процесс iPhone index **2 → 3**, затем штатный Watch journal reconcile удалил отложенные AAC/.ack. Background latency OPEN.
- [ ] Не повторять закрытые basic offline/ACK/10-sec hold тесты без регрессии. Следующее новое измерение — instrumented WCSession route/timing.

## 22.10.2026 · Реальный Watch → iPhone background WCSession

- [x] **Физический cold-background PASS (1 прогон):** QA iPhone остановлен до старта Watch, iOS автоматически запустила приёмник, настоящий синтетический AAC 3.84 с доставлен по WCSession ровно один раз. На Watch status ack-observed, pending=0, очередь пустая. [Протокол](docs/PHYSICAL_WATCH_BACKGROUND_WCSESSION_2026-10-22.md).
- [x] Физически подтверждена durable очередь Watch во втором прогоне, когда передача задержалась: UUID и AAC сохранились после остановки QA транспорта и перезапуска Watch.
- [ ] **Повторяемость/своевременность background OPEN:** второй прогон передал UUID лишь после foreground iPhone; Watch ACK после него не удалось проверить через CoreDevice. Radio offline и reboot остаются OPEN.

## 22.10.2026 · PhoneCaptures защищены на физическом iPhone 13

- [x] Временные iPhone AAC, manifest JSON и аварийные файлы получают CompleteUntilFirstUserAuthentication до записи; старые мигрируют только атрибутами, отказ защиты блокирует запись/импорт.
- [x] Физический iPhone: **132 XCTest, 0 FAIL, 3 expected SKIP**, включая 7 PhoneCaptureStorageTests и синтетический playable AAC. [Протокол](docs/PHYSICAL_PHONECAPTURES_PROTECTION_2026-10-22.md).
- [ ] Реальное микрофонное прерывание, reboot/first unlock, Watch background, encrypted backup/restore OPEN.

## 22.10.2026 · Защита старых AAC/MOV + политика backup

- [x] Физическая QA: старые AAC/MOV и временные recovery segments мигрируют метаданными без потери байтов; новые видео получают защиту до индекса. Регрессия 125 тестов без FAIL (3 skips), recovery 18/18 PASS. [Протокол](docs/PHYSICAL_LEGACY_MEDIA_BACKUP_2026-10-22.md).
- [x] Канонические локальные медиа не исключаются из системной резервной копии устройства; приложение само в облако их не отправляет. Реальный backup/restore остаётся OPEN.
- [ ] До релиза: физический reboot/first-unlock, PhoneCaptures, Watch background, полный VoiceOver, ENOSPC (на тестовом устройстве).

## 22.10.2026 · Watch AAC / index FileProtection: аппаратный фикс

- [x] Физически воспроизведено наследование NSFileProtectionNone для AAC из Watch временного файла; после фикса staging защищён до commit, аудио+index имеют CompleteUntilFirstUserAuthentication, legacy index меняет только атрибуты. **95 XCTest executed, 0 FAIL, 3 expected SKIP**. [Протокол](docs/PHYSICAL_WATCH_AUDIO_FILE_PROTECTION_2026-10-22.md).
- [ ] Legacy пользовательские AAC/MOV, reboot до первого unlock, реальная фоновая передача Watch и backup-policy OPEN; исходные данные не трогали.

## 22.10.2026 · Watch receive gate на физическом iPhone

- [x] WCSession file receiver выделен в тестируемый gate: реальные iPhone AAC файловые операции, late replay/deletion, 24 queued UUID, полный Watch A2 reliability **15/15 PASS** (адресный 3/3). [Протокол](docs/PHYSICAL_WATCH_INBOUND_GATE_2026-10-22.md).
- [ ] Реальная фоновая передача Watch и радиоканал остаются OPEN: CoreDevice Watch QA app launch timed out; системное сопряжение и настройки не меняли.

## 22.10.2026 · Физический AXXXL библиотеки: RU/ES PASS

- [x] На iPhone 13 найден и исправлен регресс: горизонтальный фильтр/подпись скрывали записи, а 4-строчный предпросмотр обрезал AXXXL текст. Компактные меню/счётчик и полный body на accessibility size, реальные системные аудиты RU+ES **2/2 PASS**; обычный UI **4/4 PASS**, последовательный editor+RU+ES **3/3 PASS**. [Протокол](docs/PHYSICAL_AXXXL_IPHONE_LIBRARY_2026-10-22.md).
- [ ] Физический VoiceOver rotor/gestures и iPad Split View всё ещё OPEN.

## 22.10.2026 · Физический iPhone 13: FileProtection / Recovery

- [x] Изолированная QA-сборка ru.arvectum.tools.what.fileprotectqa (без Watch) прошла **18/18 тестов**: FileProtection 3, Recovery UI 5, Debug interruption 5, AXXXL UI 5, 0 FAIL. [Протокол](docs/PHYSICAL_FILE_PROTECTION_RECOVERY_2026-10-22.md).
- [ ] Ещё открыто: первая разблокировка после reboot, Watch background/offline, аварии/ENOSPC, AAC/MOV/индексы и backup-policy, полноценный VoiceOver. Production bundle не трогали.


## 22.10.2026 · L4.17b: подтверждение восстановления (симулятор)

- [x] Исправлен реальный доступ к кнопке восстановления на AXXXL: уменьшен максимально допустимый размер текста только для CTA; подтверждение разрушительного действия переведено на системный `alert` с отдельными «Отмена» / «Восстановить» и предупреждением об устаревших текстах.
- [x] Изолированный Debug-репозиторий с двумя синтетическими расшифровками: XCUITest ES проверил отмену без записи, повторное открытие, явное восстановление, здоровый каталог, исчезновение CTA и закрытие успешного системного сообщения. **PASS 1/1**, `RecoveryConfirmationRetry5.xcresult`; прежний безопасный preview тест **PASS 1/1**, `PreviewRegression.xcresult` (артефакты на ArvectumSSD в `Arvectum/tmp/what-recovery-qa-20261022`).
- [x] **22.10 · Запрет небезопасного восстановления (симулятор):** четыре дополнительные Debug-ситуации (missing backup, corrupt backup, empty backup, healthy main) и прежний Cancel → Confirm; **5/5 XCUITest PASS, 0 FAIL** на отдельном синтетическом репозитории. В четырёх состояниях «Восстановить» отсутствует, предупреждение не возникает, доступно закрытие. Результат: `Arvectum/tmp/what-recovery-unavailable-qa-20261022/RecoveryUnavailable.xcresult`. Ни одного пользовательского файла не меняли.
- [ ] **Физический gate остаётся:** iPhone/iPad, VoiceOver, отсутствие копии на реальном устройстве, hardware FileProtection, независимое воспроизведение после реального повреждения и защита личных файлов. App Store и TestFlight не затронуты.


### UX/дизайн-код: очередь D2 (19.10.2026, план)
- [x] D4.3 (20.10): TextEditor имеет локализованную VoiceOver-подпись и подсказку автосохранения; декоративный placeholder скрыт из AX дерева. Тест текстовой заметки, возврата и фильтра библиотеки PASS. Реальные ввод/Watch/rotor отдельно.
- [x] D4.5 (20.10): диагностика AXXXL — прокручиваемые три секции с полными подписями, кнопка закрытия 64pt; обычный размер сохраняет системный List. Полный Xcode accessibility audit вверху и на блоке Watch PASS; RU/EN обычный UI 2/2 PASS. [Отчёт](../core/docs/UNIFIED_DESIGN_D45_WHAT_DIAGNOSTICS_2026-10-20.md). Физический Watch/VoiceOver остаётся открытым.
- [x] D4.1 (20.10): доступная панель библиотеки 64pt, отступы и Mint из SwiftPM ArvectumCore; полный system accessibility audit заполненного списка **PASS**, Debug build PASS.

- [x] VoiceOver: подсказка аудио объясняет двойное касание и действие Видеозапись вместо удержания; проверка audio/video/text accessibility labels на iPhone 17 Pro Simulator PASS.
- [x] XCUIVoiceOverService на iPhone 17 Pro iOS 27: короткий VoiceOver аудио/видео/текста PASS, включая исправленную подсказку. [ ] Полная проверка редактора, Watch и физического VoiceOver открыта.
- [x] 20.10: XCUIAccessibilityAudit экранов Capture и Library при AXXXL **2/2 PASS**. После исходного FAIL подпись «Сохранено на устройстве» и число заметок перенесены в две строки. Обычный Capture UI smoke PASS.
- [x] 20.10: выделенный 13-дюймовый iPad Simulator iOS 27, AXXXL, регрессия редактора и библиотеки 1/1 PASS; переход Capture ↔ Library при поворотах Portrait/Landscape 1/1 PASS. Не является тестом реального Fold/Duo/камеры или Split View.
- [x] 20.10: заполненная тестовая библиотека (2 текста, 1 отсутствующее видео, 1 архивная заметка) — **реальный SwiftUI AXXXL: labels/traits/textClipped PASS** после увеличения высоты действий до 64pt. Синтетика только в Debug, реальных файлов/камеры нет. Логи: what-axxxl-increased-actions-20261020.log, what-filled-final-after-empty-state-20261020.log.
- [x] Пустая библиотека: вместо обрезающего ContentUnavailableView прокручиваемый layout и лаконичная подсказка; системный audit PASS. Кнопки аудио/текст/видео на Home — UI PASS (what-empty-custom-state-20261020.log, 2/2).
- [x] **HitRegion исправлен (20.10):** при SwiftUI Accessibility Dynamic Type нативная UINavigationBar заменяется отдельной 64pt панелью действий в контенте; стандартный размер сохраняет iOS toolbar. Полный системный audit заполненного списка (labels, hitRegion, trait, textClipped) **iPhone 17 Pro PASS + iPad 13″ PASS**. Действия назад/текст/настройки 2/2 UI PASS, Home/пустая библиотека 2/2 PASS. Логи: what-filled-four-category-icon-record-20261020.log, what-ipad13-full-ax-custom-bar-20261020.log, what-library-combined-regression-final-20261020.log.
- [ ] iPad Split View, реальная камера/микрофон, Watch ACK, редактор заполненной заметки и физический VoiceOver/rotor остаются в QA.

- [x] Кнопки «Видео» и «Текст» видны на Home; мгновенное аудио и long-press сохранены (BUILD + UI discoverability + long-press PASS).
- [x] Дублированную инструкцию убрали; в компактной раскладке HStack → VStack. iPhone 17 Pro AXXXL UI PASS: аудио, текст, пустой редактор, библиотека. iPad/Duo/физический VoiceOver ещё открыты.
- [x] «Все заметки», склонение RU/EN и VoiceOver label; добавлен стабильный identifier what.open.library, исправлены ожидания в пяти файлах UI-тестов. AXXXL UI PASS.
- [ ] VoiceOver, Reduce Motion и запись/сохранение/Watch ACK regression QA перед выпуском.

Полный аудит: [единый дизайн-код](../core/docs/UNIFIED_DESIGN_CODE_2026-10-19.md).


## 19.10.2026 — App Store update prompt: E2E и релизная граница

- [x] Исходники общей проверки версии App Store и кнопок «Обновить»/«Позже» интегрированы в `main` (PR #133, коммит `08107c3`).
- [x] Симулятор iPhone 17 Pro / iOS 27.0, Debug-фикстура опубликованной версии `99.9.9`, **1/1 PASS**: диалог, «Позже», повторный запуск; аудио/видео/личные заметки не трогались.
- [ ] **Release gate:** при следующем отдельно разрешённом выпуске проверить реальный App Store URL, реальный установленный/опубликованный build, сохранность данных и поведение на физическом iPhone. До подтверждения не считать обновление доставленным пользователям.

Тестовый сценарий доступен только в Debug и исключён из Release. [Общая приёмка](../core/docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md).


## 19.10.2026, вечер — Ухват: 1.1.0 публично, QA новых исправлений продолжается

**Текущее:** Apple RU **1.1.0**, build8 по ранее проверенному ASC. Код более новых восстановлений видео, фоновых сценариев, ACK/Watch и QA есть в main, но их нет оснований считать доставленными через App Store.

- [x] Подтверждённый физический iPhone QA: writer непрерывно работал **420 с**, итоговый **434.885-секундный** MOV с аудио и видео воспроизводится; это закрывает ранний отдельный сбой на ~340 с в рамках одного теста.
- [x] Изолированная QA установка поверх сохранила **18/18** прежних записей; дополнительно пройдено возвращение из фона с **25.56-секундной** записью и сохранением прежних **19** QA ID.
- [ ] **P0:** реальный входящий звонок/interruption, 30+ минут видеозаписи с контролем нагрева/места, Watch offline/reboot/ACK на физических часах; не заменять симулятором или коротким фоновым тестом.
- [ ] **P0:** безопасный signed upgrade публичной 1.1.0 с сохранением пользовательской истории; личное хранилище не удалять и искусственный ENOSPC на устройстве не запускать.
- [ ] **P1:** настоящее Speech permission allow/deny, iPad Split View/Dynamic Type/VoiceOver, independent iPhone/iPad acceptance.
- [ ] **P1:** прототип напоминания +1/2/3 часа и одноразовой передачи транскрипции в ChickMark проверить на живых совместимых сборках: permission denied, дубль, отмена, quiet hours.
- [ ] Новый upload/App Review — только по отдельному разрешению владельца; публичная 1.1.0 не заменяется автоматом при merge в main.

[Единый портфельный срез](../core/docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md). Прежние записи о непройденных 8 мин относятся к более раннему этапу до прогона 420 секунд.


## ВЫПОЛНЕНО · 19.10.2026 — видео и background

- [x] [PR #128 MERGED](https://github.com/arvectum2/arvectum-tools/pull/128), физические QA **420 секунд**, работа MOV writer до 118,678,546 байт и сохранение playable **434.885s MOV с аудио+видео**; in-place QA 8→9: 18 прежних заметок побайтово сохранены.
- [x] Дополнительно физический QA после 3 смен front/back и ухода через Settings в `ScenePhase.background`: **одна** заметка 25.56s, все 19 предшествующих QA ID сохранены; [акт испытания](docs/PHYSICAL_BACKGROUND_3_FLIPS_BUILD9_2026-10-19.md). **Публичная App Store версия остаётся 1.1.0**.
- [ ] Ещё необходимы именно физический звонок, аппаратный Watch offline/reboot, длительные 30+ мин в контролируемой среде и неразрушающее production upgrade. Не приписывать их успешным штатным foreground/background тестам.


## Длинное видео · физический iPhone 13, 19.10.2026

- [x] **Реальная 420-секундная foreground AVFoundation запись SUCCESS** после прошлого ~340-секундного обрыва: на 420 с `sessionRunning=true, writerRecording=true`, MOV вырос до **118,678,546 байт**. Нативный callback сохранил одно новое видео, фактическая длительность индекса **434.885 с**.
- [x] Отдельная QA-проверка `AVURLAsset`: оба последних MOV (434.88 с и ранее восстановленный 339.82 с) **playable, есть видео и аудио**.
- [x] in-place обновление `ru.arvectum.tools.what.multimodalqa` с QA build 8 на **build 9**: 18 прежних заметок сохранились **побайтово идентично**; после записи 19 заметок, без потерь и дублей. [Детальный протокол](docs/PHYSICAL_LONG_VIDEO_420S_ACCEPTANCE_2026-10-19.md), [PR #128](https://github.com/arvectum2/arvectum-tools/pull/128).
- [ ] Всё ещё открыто: interruption при реальном звонке/уходе в фон, 30–120 мин видео, аппаратный Watch offline/reboot, upgrade **публичной** версии без изменения личных данных. Этот QA не означает новый релиз App Store.


## P0 · QA диагностика долгого видео уже в main (19.10.2026)

- [x] [PR #127](https://github.com/arvectum2/arvectum-tools/pull/127) **MERGED** (5768ba0): только под `REVIEW_HANDOFF_QA` каждые 30 секунд журналируются реальные `AVCaptureSession.isRunning`, `AVCaptureMovieFileOutput.isRecording`, размер текущего MOV/сегмент и SwiftUI status. Локальный Xcode 27.1 **BUILD SUCCEEDED**, GitHub capture-reliability/watch-build CI **SUCCESS**. Аудио/видео не читается в лог; производственная логика не менялась.
- [ ] 8+-минутная непрерывная физическая запись и причина остановки ~340 секунд **не подтверждены**; следующий физический прогон должен сравнить file writer против логического UI статуса на отдельном QA-бандле. [Протокол](docs/PHYSICAL_LONG_VIDEO_LIVENESS_QA_2026-10-19.md).


## Исполнение P0 · проверка видео и исходной QA (19.10.2026)

- [x] Из предыдущего независимого полного [тестового прогона видеосегментов](docs/PHYSICAL_12_FLIPS_LONG_VIDEO_2026-10-19.md) известны **126 XCTest / 0 failures / 3 skipped**, включая recovery и сегменты. [PR #125](https://github.com/arvectum2/arvectum-tools/pull/125) merged, GitHub capture-reliability и watch-build CI SUCCESS.
- [ ] Новые попытки локально повторить более поздний симуляторный QA long-heartbeat прерваны самим Xcode (**BUILD INTERRUPTED**, без ошибки assertion). Эти попытки **не зачтены** за PASS. В реальном тесте 480 секунд камера остановилась примерно на 340-й секунде; отрезок восстановлен, но полноценная непрерывная 8-минутная запись ещё не доказана. Не запускать стресс/ENOSPC/аварийный reboot на личном устройстве без безопасной отдельной процедуры.
- [ ] Дальше: диагностировать триггер обрыва AVFoundation по heartbeat/scenePhase, повторить non-destructive compile/unit QA на стабильном раннере и safe upgrade опубликованной 1.1.0. Предыдущий локальный archive 1.1.1(9) — **не опубликован** и не означает пройденную physical приемку.


## Публикация 1.1.0 и очередь после неё · 19.10.2026

- [x] **WH19-RELEASE:** [публичный Apple RU каталог](https://apps.apple.com/ru/app/id6822476399) подтверждает **1.1.0** (18.10.2026 22:21:56 UTC). Отдельная read-only проверка ASC 19.10 подтвердила **1.1.0(8) READY_FOR_SALE**. Старые статусы WAITING_FOR_REVIEW ниже — исторические.
- [ ] **WH19-NEXT-P0:** публичный build 8 не содержит исправлений после отправки в `main`: recovery video, partial segments, локальное удаление, защита AAC и дополнительные Watch-ACK QA. Сначала повторить прерванную симуляторную проверку новой long-video диагностики и выяснить физическую остановку ~340 с; затем подписанный **новый номер build** и недеструктивный upgrade QA.
- [ ] **WH19-NEXT-DEVICE:** непрерывные 8+ минут видео, радио-offline/перезагрузка Watch, реальный Speech и права, iPad Split View/VoiceOver; запрещены ENOSPC-проверки на production-памяти и удаление оригинальных заметок. Потерянный ACK физически уже подтверждён 19.10 — не переоткрывать как невыполненный.
- [ ] **WH19-NEXT-UX:** напоминания о заметках +1/2/3 часа и one-off handoff в ChickMark (код есть) — проверить на **двух публичных версиях**, включая отказ разрешения, тишину/quiet hours, повтор доставки и связь с удалённой заметкой. Семантические функции позже.

[Сверка портфеля](../core/docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md).



## WH19-FINAL-QA · Ускоренная физическая регрессия и регулируемый long-video тест (19.10.2026)

- [x] **Восстановление локальных QA-данных после установки поверх:** физический iPhone 13, QA bundle `ru.arvectum.tools.what.multimodalqa`, приложение 1.1.0 (8) повторно установлено `devicectl install app` **без uninstall**. `local-notes.json` совпадает побайтно до/после: **18 заметок (15 видео, 3 текста)**. Пользовательское production приложение и Watch QA-бандл не менялись.
- [x] **Читаемость media после установки:** на самом iPhone QA-запрос `what-physical-qa=verify` подтвердил `AVURLAsset.isPlayable`, существование аудио- и видеодорожек у двух последних роликов **339,82 с** и **37,00 с**. Ни один исходный MOV не переносили на Mac. Это **проверка повторной установки той же сборки, НЕ signed upgrade с новой версией**.
- [x] QA-контур длительного видео теперь поддерживает `what-physical-qa=long` и отдельный параметр `what-physical-qa-seconds=N` в диапазоне **60–900 секунд**; прежний `480s` оставлен для воспроизводимости истории. Восемь минут — **произвольная величина прошлого теста, а не предел/требование iOS**. При тесте каждые 30 секунд пишется heartbeat состояния AVFoundation; в момент преждевременной остановки логируется точный elapsed и ошибка. Производственная видеокамера/лимиты не менялись.
- [x] Изолированная iOS QA-сборка компилируется (`BUILD SUCCEEDED`, Xcode 27.1), `swiftc -parse` прошёл. **Полный локальный симуляторный прогон этого нового изменения прервался на сборке модулей (`BUILD INTERRUPTED`) и НЕ зачтён как прошедший**; требуется повторить CI перед merge.
- [ ] **Физические ограничения:** новая непрерывная запись 6/8/10 минут здесь не запускалась; валидная аварийная recovery ~340 с из предыдущей проверки не равна успешной непрерывности. Не заполнять реальный телефон для ENOSPC, не имитировать реальный звонок и не выключать Bluetooth/Wi-Fi/Watch pairing без безопасной отдельной процедуры. Reboot часов при живой очереди и 30–120 мин реального видео остаются открытыми.
- [ ] **Upgrade gate:** после установленного 1.1.0 (8) требуется отдельный подписанный release-candidate с новым build number и сверкой сохранности пользовательского хранилища. Не считать QA-повторную установку таким обновлением, не отправлять новый App Store build автоматически.

[Протокол](docs/QUICK_DEVICE_QA_AND_LONG_CAPTURE_2026-10-19.md).

## WH19-STRESS-RELEASE · Реальные 12 смен камер, восстановление 5:40 и статус App Store (19.10.2026)

- [x] **Статус App Store Connect проверен напрямую только для чтения (10:03 МСК):** `What? / Ухват` iOS **1.1.0 (build 8) — READY_FOR_SALE, VALID**. Версии 1.0.1(6) и 1.0.0(5) также READY_FOR_SALE; все три review submissions COMPLETE. **Это опубликованный build 8, а не новая исходная ветка `main`: внесённые позже исправления ещё не выпущены.** Никакого ASC API POST / upload не выполнялось.
- [x] **Физические 12 back/front переключений камеры** в изолированном `ru.arvectum.tools.what.multimodalqa` на iPhone 13: ровно один MOV с 13 фрагментами, UUID `FDA36A2E-8A55-46C8-B932-9EF86D51C02D`, длительность библиотеки **36,985 с**, AVFoundation **37,00 с**, **28,4 МБ**. Тестовый callback `saved` зафиксирован; временная сессия новой записи не оставлена в `VideoCaptures`. Исторические нерешённые QA-журналы не тронуты.
- [x] **Восстановление после остановки продолжительной записи:** QA-режим `480s` стартовал в 10:04, но отдельный прямой AVFoundation-контроллер перестал писать примерно на 340-й секунде (исходный MOV **57 МБ**, статус `recording` висел до foreground, затем `failed`). **8-минутная непрерывная запись НЕ зачтена.** После перезапуска только QA-приложения штатный `VideoCaptureRecovery` создал **одну** заметку UUID `EC124AD7-483B-42A9-82DC-2CB15EE4E426` длительностью **339,817 с**, исходник перешёл в библиотеку. На физическом iPhone `AVURLAsset` подтвердил воспроизводимые **339,82 с** видео+аудио и соседние 37,00 с видео+аудио; дублей UUID нет.
- [x] Новый `PhysicalCaptureQAProbe` умеет `stress12` и `480s`, **не приступает к опасной стресс-записи при доступном объёме менее 1 ГБ**, не производит искусственный ENOSPC; QA-only атомарный timeline scenePhase/status подготовлен для следующего воспроизведения прерывания. Не изменяет production bundle.
- [x] **13 реальных MOV-фрагментов** от двух тестовых камер: `VideoCameraSwitchTests` проверяет все 13 декодированных кадров по порядку, суммарную длительность, аудио/видео, защиту от сохранения первых 12 без 13-го и нетронутые исходники. **24 Watch UUID**: отдельный unit test долговременной очереди с двумя relaunch, 12 ACK в обратном порядке, повторными ACK и финальной очисткой без потерь. Полный iOS регрессионный прогон — **126 tests, 0 failures, 3 expected skips**.
- [ ] **Релизные блокеры, не выдавать за закрытые:** 8+ минут именно *непрерывного* физического видео / 30–120-минутный тест; причина неожиданного прерывания; настоящий радио-offline и reboot Watch; реальный ENOSPC и телефонный звонок при записи; полная проверка производства 1.1.0 → новая подписанная версия с неизменными пользовательскими данными. Последнее требует отдельного release-candidate/upgrade gate. Не выключать Wi-Fi/Bluetooth на личных устройствах и не заполнять их хранилище ради QA.

[Подробный физический протокол](docs/PHYSICAL_12_FLIPS_LONG_VIDEO_2026-10-19.md).

## WH19-IPAD-A11Y · Максимальный системный текст на iPad (19.10.2026)

- [x] На отдельном iPad-симуляторе `Arvectum-T5-iPad` вручную установлен **accessibility-extra-extra-extra-large** через `simctl ui content_size`, затем запущен воспроизводимый `AdaptiveLayoutUITests.testAccessibilityTextSizePreservesCaptureAndEmptyTextEditor`.
- [x] **1/1 PASS:** основная большая круглая кнопка записи остаётся hittable, «+» открывает пустой текстовый редактор, `Готово` закрывает его без создания заметки, Inbox доступен, кнопка фильтра «Все» hittable и возврат к записи работает. На экране не требуются разрешения камеры/микрофона. После теста размер текста восстановлен к исходному `large`.
- [x] Отдельный iPad rotation/navigation UI тест в том же релизном коде — 1/1 PASS. Общая поддержка iPad в `main`: `TARGETED_DEVICE_FAMILY=1,2`.
- [ ] Реальные VoiceOver, Stage Manager, Split View и физический iPad здесь **не проверены**; тест максимального Dynamic Type не заменяет их.

[Подробный протокол](docs/IPAD_ACCESSIBILITY_DYNAMIC_TYPE_QA_2026-10-19.md).

## Сводный светофор · исходный код main / QA · 19.10.2026

Актуальные статусы, в отличие от исторических невыполненных M1–M7 и WH-D0–D3 ниже. Старые чекбоксы — снимок **плана**, а не достоверная оценка текущего `main`; наличие кода не означает доступность функции в опубликованной версии App Store.

| Направление | Статус | До завершения |
| --- | --- | --- |
| Watch P0, UUID, очередь, ACK | 🟢 Код и физический lost-ACK подтверждены | Реальные Watch→iPhone, отложенная доставка и подавление первого ACK с повтором того же UUID проверены 19.10; **настоящее отсутствие радиосвязи, reboot и очередь 20+** остаются аппаратными воротами |
| Текст, аудио, видео, единый Inbox, автосохранение | 🟢 Реализовано в `main` | Большие записи, безопасный upgrade и реальные отказы — отдельная QA |
| Локальное удаление видео | 🟢 Исправлено по WH19-LOCAL-DELETE | 124 теста без ошибок; физический ENOSPC ещё не испытан |
| Расшифровка: язык, повтор, коррекция | 🟡 Код есть | Реальный Speech/permission, длинная запись, крайние состояния |
| Напоминания и ChickMark | 🟡 Код есть | Тихие часы, уведомление и tap-through на публичной сборке |
| iPad / Duo | 🟡 iPad target family `1,2`, адаптивный UI и симуляторные тесты есть | Split View, Stage Manager, VoiceOver/large text и физическая проверка при наличии оборудования |
| Семантический поиск / Ask Your Memory | 🔴 Следующий этап | Прототип LocalSemanticSearch не равен полноценному обоснованному ответу и продуктовой приёмке |
| App Store 1.1 / пользовательский upgrade | 🟡 1.1.0(8) опубликована | `READY_FOR_SALE` проверен через ASC 19.10; последующие исходники `main` пока не вошли в App Store, новый signed upgrade и data-preservation QA остаются |

**Правило приоритета:** пока физического iPhone нет, дорабатывать надёжность хранения, доступность и симуляторные проверки. Не переоткрывать реализованные M1–M6 как «не начатые» без анализа действующих файлов.

## WH19-LOCAL-DELETE · Надёжное удаление видео после сбоя (19.10.2026)

- [x] Durable UUID-only журнал `pending-local-video-deletions.json`: фиксируется до удаления заметки из индекса, восстанавливается после перезапуска и очищается только после удаления канонического MOV.
- [x] Если источник не удалось удалить, он остаётся для следующей попытки, UUID скрыт из Inbox; нечитаемый журнал не инициирует массовую очистку чужих файлов.
- [x] Ошибка очистки обновляет UI и отменяет связанные напоминания, только если заметка уже логически удалена.
- [x] Четыре новые регрессии: commit intent, отказ файловой системы, crash между intent/index и сохранность незнакомого MOV. **124 WhatIOSTests, 0 failures, 3 skipped.**
- [ ] Физическая проверка реального ENOSPC и upgrade — совместно с остальной аппаратной приёмкой.

[QA-протокол](docs/LOCAL_VIDEO_DELETION_RECOVERY_2026-10-19.md).

## WH19-LOST-ACK · Повторная доставка того же UUID при неполученном ACK (19.10.2026)

- [x] Реализован безопасный, **только для QA** сценарий `what-watch-qa-drop-ack`: после запуска семисекундной записи запоминает её UUID, перехватывает подтверждение от iPhone как из `sendMessageData.replyHandler`, так и из фонового `didReceiveUserInfo`, **не удаляет Watch оригинал и не изменяет индекс очереди**. При таймауте 60 с или ошибке повторной отправки тестовый фильтр автоматически снимается без удаления AAC. Учтено, что оба ACK могут прийти в разном порядке.
- [x] Как только Watch получил хотя бы одно корректное подтверждение по этому UUID (значит приёмник уже зафиксировал файл), QA-пробник сверяет `pending>0` и наличие исходного `.m4a`, а затем снимает тестовый фильтр и отправляет **этот же AAC и UUID** вторым `WCSession.transferFile`. Повторное подтверждение должно очистить очередь. Ни pairing, ни Bluetooth/Wi-Fi, ни бандл обычного «Ухвата» не трогаются.
- [x] В симуляторные регрессионные тесты добавлена проверка **реального декодируемого AAC** при двух вызовах `RecordingRepository.acceptTemporaryFile` с одним UUID: при первом потерянном ACK исходный Watch-файл и очередь сохраняются, при повторе телефон имеет единственную заметку и идентичные аудиобайты, только `WatchAcknowledgementJournal.acknowledge` удаляет оригинал. Это *детерминированный* тест протокола, не имитация реального радиоканала.
- [x] Отдельная Watch QA сборка компилируется в Xcode 27.1 через `generic/platform=watchOS` с изолированными bundle IDs; никаких изменений в производственном ACK-коде вне `#if WATCH_PHYSICAL_QA`.
- [x] **Физический lost-ACK + real AAC replay — PASS (09:49–09:51 МСК)**: после снятия блокировки iPhone оба QA-приложения активированы; baseline Watch queue `[]`, телефонный Inbox 4 UUID. Watch создал полноценную ~7,6-секундную запись `63BEBAD8-68A7-4DC7-9005-07941EE3E8EE`; в `timeline.json` зафиксированы `ack-filter-armed`, `ack-suppressed count=1, sourceKept=true` и `same-uuid-retransmission` именно этого UUID. После второго ACK `status.json=ack-observed,pending=0`, `WhatOutbound/queue.json=[]`. На iPhone **один** элемент этого UUID длительностью 7,612 с; после отдельного перезапуска обоих QA-приложений — всё ещё один, общий индекс 5 уникальных UUID и пустая Watch очередь. Никакие пользовательские bundle/audio, Wi-Fi, Bluetooth или pairing не менялись. Старый QA-фрагмент 0,124 с сохранён. Это физический путь WatchConnectivity с программно потерянным ACK, но **не** отключение радиоканала.

[Протокол и условия запуска](docs/PHYSICAL_WATCH_LOST_ACK_REDELIVERY_2026-10-19.md).

## WH19-WATCH-LIFECYCLE · Реальная аудиосессия Watch: диагностика внезапного обрыва (19.10.2026)

- [x] В изолированную QA-сборку Watch добавлен атомарный JSON-журнал `Documents/WatchPhysicalQA/timeline.json` (до 100 событий): `ScenePhase`, AVAudioSession interruption/route changes, начало записи, семисекундный stop timer, результат и времена. **Аудиоданные в журнал не входят**, production Watch-сборка эти события не собирает.
- [x] Два физические автозапуска на Apple Watch SE после корректного разрешения микрофона дали **полноценные записи 7,548 и 7,612 с**. В обоих trace есть `start-capture-called`, `recording-observed`, `audio-route-change(3)` и `stop-timer-fired` приблизительно через 7,3 с; **событий interruption/background между началом и остановкой нет**. Нельзя выводить из этого, что watchOS прерывание невозможно — исходный 0,124-секундный сбой не воспроизведён.
- [x] Первый из новых файлов ожидал в Watch queue при неактивном QA-приёмнике, после foreground iPhone QA и повторной активации Watch был доставлен с тем же UUID `55F1B526-5095-41D2-B8E4-13815ED4CCE9` **ровно один раз**, Watch queue очищена. Второй UUID `1154309C-AEFC-4E17-98DC-419CBD1BAAD1` доставлен автоматически с `ack-observed`. Четыре валидные QA-аудиозаписи по одному UUID хранятся только в iPhone QA-контейнере.
- [x] Добавлен модульный тест реального дефектного AAC **25 247 байт / 0,124 с** при ожидаемых 7 с (запрещает считать длительность исходя из размера файла) и контроль принятия валидной записи 7,612 с. Сам повреждённый источник сохранён на Watch и не отправлен.
- [ ] **Причина 0,124-секундного обрыва не доказана**. При следующем воспроизведении сравнить `timeline.json` с системным событием (sceneBackground, audio interruption/route change) и определить корректный способ восстановления; **не ослаблять проверку AAC** и не удалять исходник до расследования.

[Физический протокол](docs/PHYSICAL_WATCH_AUDIO_LIFECYCLE_2026-10-19.md).

## WH19-ACK-PHYSICAL · Watch → iPhone → ACK на настоящих устройствах (19.10.2026)

- [x] **Ручная запись на реальных Apple Watch SE** после подтверждения микрофона владельцем доставлена в отдельный iPhone QA bundle: UUID `39B7AFC0-F2D7-487B-BAC0-03DD7E0E92A7`, **4,4 с / 94 КБ**, в `recordings.json` ровно одна запись. Watch `WhatOutbound` пуст, а входящий WatchConnectivity UserInfo появился в 07:56. Ни одно пользовательское приложение не изменено.
- [x] **Полностью автоматический физический сценарий с искусственно задержанной отправкой:** Watch QA записал реальный AAC **7,228 с / 45 КБ**, UUID `A2BE3682-31DA-40AF-95B3-FF1592A1F3D4`; на 10 секунд приостановлен только `pumpTransfers()` **в QA-бандле**. На Watch подтверждены `offline-queued`, `pending=1`, источник на диске; после возобновления — `ack-observed`, `pending=0`, исходный `.m4a` отсутствует. iPhone индексирует этот UUID **ровно один раз**. Это не физическое отключение Wi-Fi/Bluetooth.
- [x] После перезапуска **только QA-приложений** Watch и iPhone подтверждены пустая исходящая очередь Watch и обе аудиозаписи на iPhone по **одной копии каждого UUID**. QA-приложение не копировало оригинальные AAC на Mac.
- [x] Ещё один автономный прямой запуск обнаружил **неполную запись 0,124 с / 25 247 байт**, не прошедшую `WatchCaptureValidation`: новая заметка не создавалась, файл `E048D504-A943-49B8-AAA4-BBDEA76A0048.m4a` сохранён **на часах**. Длительность подтверждена `AVAudioPlayer` непосредственно на Watch. Не удалять до отдельного решения; причина обрыва записывающего сеанса ещё не установлена.
- [x] QA probe доработан: только явный параметр запуска инициирует тестовую запись; диагностический/обычный перезапуск Watch QA больше не запускает микрофон автоматически, не влияет на production; различаются UUID новых и ранее оставшихся исходников, есть режим чтения `what-watch-qa-audit` и автоматическая проверка ACK. Обе физические сборки компилируются под Xcode 27.1.
- [ ] Физическое выключение/восстановление реального транспорта, **потеря ACK с повторной доставкой**, перезагрузка самих Apple Watch и длительные офлайн-очереди ещё **не проверены**. Не подменять их QA-local 10-секундным удержанием передачи.

[Подробный протокол](docs/PHYSICAL_WATCH_ACK_AUTO_QA_2026-10-19.md).

## WH19-SEGMENTS · Не сохранять неполную видеозаметку после переключений камеры (19.10.2026)

- [x] **Физически воспроизведено на iPhone 13:** `VideoRecordingSheet` → три переключения камеры (4 файла MOV) → системные «Настройки» → назад в тот же QA-процесс. Два прогона старого кода преждевременно добавили заметку лишь **6,86 с** (первые три фрагмента), а финальный `segment-000003.mov` продолжал дописываться (21–24 МБ); все исходники оставались в журнале. QA-заметки не удалялись.
- [x] **Оба пути исправлены:** обычное `saveCompletedVideo` теперь проверяет на serial camera queue, что число завершённых MOV точно равно числу начатых и активный writer остановлен; fallback после возврата в приложение требует все ожидаемые и читаемые сегменты (никакого частичного salvage в живом процессе). При отсутствии последнего файла никакого нового UUID в библиотеку не записывается, оригиналы остаются. После реального аварийного завершения прежний осторожный частичный salvage доступен.
- [x] В процедуре удаления журнала после ранее сохранённой частичной заметки проверяется суммарная длительность всех восстановленных исходников: если в них имеется ещё не включённое видео, **их нельзя удалять**. Предыдущие QA-исходники сохранены для отдельного, безопасного восстановления полной записи.
- [x] **Повторный физический тест после двойного исправления:** три реальные смены камеры, сворачивание в «Настройки» и возвращение без остановки QA-процесса → одна видеозаметка **28,62 с** (AVFoundation измерила **28,63 с**), на телефоне присутствуют видео/аудиодорожки, новый UUID создан один раз, именно новая временная сессия очищена. Предыдущие два тестовых журнала оставлены без изменения.
- [x] Восстановление/переключение подтверждено **26 целевыми модульными тестами без ошибок**, включая три новых теста неполного четвёртого сегмента, отсутствующего сегмента и безопасности исходников уже индексированной частичной заметки, а также gate обычного экспорта.
- [x] Watch ↔ iPhone physical ACK: после разрешения микрофона и реальных передач закрыт в WH19-ACK-PHYSICAL; физический radio outage, lost ACK и device reboot продолжают оставаться открытыми там же.

[Протокол QA](docs/PHYSICAL_VIDEO_FOUR_SEGMENT_RACE_2026-10-19.md).
## WH19-WATCH-PAIR · Изолированная пара Watch/iPhone для физического ACK QA (19.10.2026)

- [x] Создан отдельный XcodeGen-спек `project.watch-physical-qa.yml` с уникальными идентификаторами iPhone, Watch, WidgetKit и complication. Командой Xcode 27.1 собраны и подписаны обе разработки: iPhone `ru.arvectum.tools.what.watchphysqa`, Watch `ru.arvectum.tools.what.watchphysqa.watch`; Watch companion указывает **ровно на QA iPhone bundle**. Оригинальные production и старые QA-bundle не заменены.
- [x] Пара установлена отдельно на физические iPhone 13 и Apple Watch SE через `devicectl install app` (без сброса часов/удаления записей); перед запуском существующая Watch QA-очередь `queue.json` была пуста. Новый тестовый сценарий создаёт лишь **одну 7-секундную запись** по специальному аргументу запуска и сохраняет агрегированный статус без копирования AAC на Mac.
- [ ] Реальная запись/потеря связи/ACK **не подтверждены**: Watch QA статус остался `waiting-for-microphone`, очередь нового QA-бандла пуста, затем CoreDevice кратковременно потерял туннель к часам. Новый QA-probe подтвердил `AVAudioApplication.recordPermission = undetermined`; требуется ручное подтверждение системного доступа к микрофону на разблокированных Apple Watch перед физическим ACK QA. **Не менять** сопряжение/сетевые параметры и не перезаписывать пользовательские приложения.

[QA-конфигурация и инструкция](docs/PHYSICAL_WATCH_ISOLATED_PAIR_2026-10-19.md).

## WH18-BG · Сохранение видео после сворачивания без перезапуска (18.10.2026)

- [x] **Физический регрессионный сценарий** на iPhone 13: через изолированный QA-бандл открыт настоящий `VideoRecordingSheet`, начата съёмка MOV, затем через CoreDevice активированы системные «Настройки»; QA фиксирует `ScenePhase.background`. После возвращения в **тот же процесс** исходный MOV оставался в `VideoCaptures` и не попадал в библиотеку даже спустя ~30 с. Личные приложения/камеру/watchOS не изменяли.
- [x] **Сохранность данных до исправления:** два источника (примерно 4 МБ и 3 МБ) удалось восстановить через штатную launch recovery после перезапуска QA-приложения, каждый с исходным UUID и без уничтожения заметок. Это воспроизводимый UX-дефект, а не потеря оригиналов.
- [x] Исправлено: `VideoRecordingSheet` при выходе из Active инициирует ограниченную фоновую задачу iOS для завершения MOV; при возвращении, если callback `didFinishRecordingTo` не пришёл, контроллер **на serial capture queue** проверяет, что писатель окончательно остановился, и только затем снимает `active` с UUID и запускает существующий `VideoCaptureRecovery`/индексацию. Повторные вызовы и дубли UUID защищены; при неудачной/неполной записи исходники сохраняются.
- [x] Защита первого разрешения Camera/Mic: временная `.inactive` во время системного диалога **не прерывает подготовку камеры**; незавершённую подготовку останавливаем только при фактическом `.background`. Код не запрашивает новые разрешения на пользовательском устройстве для этого теста.
- [x] **Повторный физический тест с исправлением:** настоящий экран камеры → системные «Настройки» → тот же живой QA-процесс. `saved-after-background`: **ровно один MOV 20,93 с (~2,9 МБ)**, приватный индекс содержит **1 заметку с исходным UUID**, временный журнал — **0 файлов**, перезапуск не требовался. На самом iPhone `AVURLAsset` подтвердил воспроизводимость, видео и аудиодорожки (20,93 с).
- [x] QA-only режим `what-physical-qa=background-sheet` запускает **производственный экран видеозаписи**, а не фальшивый тестовый AVFoundation-контроллер. Принудительный SIGKILL, настройки пользователя и системные разрешения в этом тесте не менялись.
- [x] Полный Xcode 27.1/iOS 27.0 Simulator регрессионный прогон: **114 модульных тестов, 0 failures, 3 expected skips**; тест включает отсечение открытого writer и восстановление завершённого MOV ровно с одним UUID.
- [ ] Отдельно проверить фон при **незавершённом переключении камеры**, длительную блокировку экрана, прерывание телефонным вызовом и низкий остаток памяти; физический Watch ACK остаётся открытым.

[Подробный физический протокол](docs/PHYSICAL_VIDEO_BACKGROUND_RECOVERY_2026-10-18.md).

## WH18-PHYSICAL · Камера, 3+ минуты и аварийный обрыв на iPhone 13 (18.10.2026)

- [x] **6 реальных последовательных переключений** задней/фронтальной камер в отдельно установленном `ru.arvectum.tools.what.multimodalqa` (iOS 27.0.1): исходные 7 фрагментов → **один MOV 22,69 с / ~12 МБ** с тем же UUID, ровно одна заметка в локальном индексе, `VideoCaptures` после сохранения — **0 файлов**. Прямой QA-пробник обошёл ошибку инициализации XCTest UI Automation, не затрагивая производственную сборку.
- [x] **180 секунд непрерывной физической камеры**: итоговый MOV длительностью **191,38 с / ~26,3 МБ**, записан и проиндексирован, временные оригиналы очищены; не равно многочасовому тесту.
- [x] После обновления **только изолированного QA-приложения** видеозаметки сохранились. `AVURLAsset` непосредственно на iPhone подтвердил оба MOV как воспроизводимые, с видео- и аудиодорожками; видео на Mac не копировалось.
- [x] **SIGKILL во время первого сегмента** QA-записи, до штатного `Stop`: на iPhone остался манифест UUID и оригинальный MOV. Последующий обычный запуск восстановил в библиотеку **одну запись 9,32 с / ~1,2 МБ**, `VideoCaptures` очистился; AVFoundation на iPhone подтвердил воспроизводимость и звук. Дополнительный перезапуск — ровно тот же UUID и **без дубля** (9 QA-заметок всего).
- [x] Все проверки — изолированный bundle без компаньона Watch, App Groups и доступа к личным контейнерам. Установленный production Ухват и очередь Watch не менялись. Сбой запуска физического UI-раннера XCTest фиксируется отдельно, **не считается** ошибкой продукта или успешно пройденным UI XCTest.
- [ ] Физические многочасовая запись, реальное исчерпание места и фон/долгая блокировка экрана, а также Watch ACK и upgrade публичного production bundle — **не закрыты**.

[Подробный протокол](docs/PHYSICAL_VIDEO_STRESS_RECOVERY_2026-10-18.md).

## WH18-VIDEO · Многократная смена камеры и проверка места для MOV (18.10.2026)

- [x] Перед сохранением видеозаметки добавлена консервативная оценка **свободного пространства для экспорта и копирования в библиотеку**: один фрагмент — ~1× исходный объём + 32 МиБ, несколько — ~3× + 32 МиБ; используется системная ёмкость `volumeAvailableCapacityForImportantUsage`. Если система не сообщает число, сохраняется прежний безопасный механизм обработки ошибок записи.
- [x] При недостатке места дорогостоящий экспорт не начинается, пользователь видит ошибку, исходные `.mov` остаются в журнале для повторного сохранения/восстановления после освобождения места. Это профилактическая оценка, **не гарантия**, что при реальном заполнении запись завершится успешно.
- [x] 10 последовательных фрагментов от двух камер (10 × 0,8 с): проверены порядок/цвет каждого кадра, итоговая длительность, аудиодорожка и неизменность исходных MOV. В тестовом `AVAssetImageGenerator` зафиксирован допуск времени 0,05 с во избежание выбора соседнего кадра.
- [x] Симуляторный отказ при свободном объёме 1024 байта: экспорт отклонён до создания итогового файла, все исходные фрагменты сохранены; повтор при нормальной ёмкости успешен.
- [x] Xcode 27.1 / iOS 27.0 Simulator: **113 модульных тестов, 0 failures, 3 expected skips**; 8/8 VideoCameraSwitchTests PASS.
- [ ] Проверить 30–120 минут физической записи, 10+ реальных переключений камеры, фактический остаток места, фон/возобновление и перезапуск на изолированном физическом устройстве — не считать это закрытым симуляторными тестами.

[Протокол видео-QA](docs/VIDEO_STORAGE_MULTISWITCH_QA_2026-10-18.md).

## WH18-ACK · Устойчивость ACK при разрыве связи и перезапуске Watch (18.10.2026)

- [x] При подтверждённом сохранении аудио на iPhone перед изменением очереди Watch атомарно фиксируется маркер ACK для UUID; исходный `.m4a` удаляется **только после** успешного обновления `queue.json`. При сбое на любом из этапов маркер/оригинал остаются до следующей безопасной попытки.
- [x] После перезапуска Watch завершает прерванную ACK-очистку **до** поиска «осиротевших» аудиозаписей, а сканер не возвращает подтверждённые UUID в очередь. При недоступном на заблокированных часах индексе исходная очередь не заменяется пустой.
- [x] Повторный live/background ACK не затрагивает другие заметки; запоздавший `didFinish` для уже подтверждённого UUID не меняет retry/backoff состояния.
- [x] **12/12** целевых `WatchA2ReliabilityTests` PASS; полный `WhatIOSTests`: **110 выполнено, 0 failures, 3 expected skips** на iOS Simulator, Xcode 27.1. Временные файлы и XCT отчёты только на ArvectumSSD.
- [ ] Физическое воспроизведение потери ACK, Watch offline/reboot, нескольких несинхронизированных записей, фоновой доставки и аудио после приёма; код и симуляторные тесты **не закрывают** этот релизный gate.

[Подробный QA-протокол](docs/WATCH_ACK_RACE_QA_2026-10-18.md).

## WH18-QA · Защита восстановления до первого сегмента и при нехватке места (18.10.2026)

- [x] Пустая незавершённая видеосессия после аварийного обрыва до первого `MOV`: сохраняется её UUID/манифест; при следующем запуске показывается уведомление о невосстановленной записи вместо молчаливого пропуска. Оригинальные данные не удаляются, фантомная заметка не создаётся; повторный запуск идемпотентен.
- [x] Симуляция ENOSPC **после частичного копирования** видео: неполный `.incoming` / `.repair` очищается, исходный фрагмент и индекс заметок сохраняются; дальнейшее восстановление с тем же UUID не блокируется устаревшим staging-файлом.
- [x] Детерминированные модульные тесты на iOS Simulator (без заполнения накопителя и без личных медиа): **107 executed, 0 failures, 3 expected skipped**, включая 13/13 сценариев VideoCaptureRecovery; физическая проверка самого раннего обрыва и реального малого остатка места остаётся отдельным открытым пунктом.
- [ ] Реальные стресс-проверки многочасового видео, нехватки места и завершения до финализации первого MOV на **изолированном физическом QA-устройстве**; итоговый production build/Watch не трогать до отдельной приёмки.

[Протокол испытаний](docs/VIDEO_EARLY_CRASH_ENOSPC_QA_2026-10-18.md).

## Физический iPhone: дополнение к QA Ухвата 1.1 · 18.10.2026

- [x] Реальное аудио: короткое нажатие, микрофон, сохранение — физический iPhone 13, 1/1 UI PASS.
- [x] Реальное видео: длинное нажатие, смена камеры, сохранение MOV — физический iPhone 13, 1/1 UI PASS.
- [x] Открытие ранее сохранённого MOV через библиотеку после нового запуска: физический iPhone 13, 1/1 XCTest PASS (11.400 с), системная связь восстановлена. Первоначальный CoreDeviceError остался в истории QA.
- [x] 90-секундная реальная видеозапись: Stop and save, файл сохраняется и Home возвращается; физический iPhone 13, 1/1 UI PASS (102.699 с теста).
- [x] Отмена короткой реальной видеозаписи и возврат Home: 1/1 физический UI PASS.
- [x] Отмена после переключения задней/фронтальной камеры: 1/1 дополнительный UI PASS на iPhone 13; независимый просмотр приватной QA-папки `VideoCaptures` показал **0 файлов** до и после перезапуска, `local-notes.json` не изменён (дата модификации 20:49 при тесте 21:15); временный журнал удалён. Этот сценарий не требует физического iPhone повторно без регрессий.
- [x] Физический аварийный обрыв после переключения камеры: 1/1 XCTest PASS, два сегмента и манифест сохранились; при запуске объединены в один MOV, повторный запуск не породил дубль (один UUID). Проверка только на изолированном UhWhat QA. Воспроизведение именно восстановленного ролика — PASS (1/1 физический UI); разрыв до закрытия первого сегмента — OPEN.
- [ ] Watch ACK, фоновый жизненный цикл, **многочасовые** записи и Store rollout — открыто. Физические медиа остаются только в собственном QA-контейнере.
- [ ] Возобновить приёмку после переподключения iPhone, не сбрасывая и не удаляя личные приложения.

[Физический QA-протокол](docs/PHYSICAL_MULTIMODAL_1_1_QA_2026-10-18.md).


## PR #90 объединён в main · 18.10.2026

- [x] Исходники реального Ухвата 1.1.0 (текст/аудио/видео, Watch, ChickMark handoff) и iPad/Duo адаптивность в main через PR #90, 38/38 GitHub checks.
- [x] Финальные тесты на обычном iPhone: 104 executed, 0 failures, 3 expected skip; [протокол](../core/docs/ADAPTIVE_MAIN_INTEGRATION_2026-10-18.md).
- [ ] Ранее отправленная Apple сборка 1.1.0(8) не заменялась новым бинарником. Новые iPad-релизы, реальные доступы камеры, окончательная физическая приёмка и настоящее fold/unfold не закрыты.


## Мультимодальный iPad/Duo · 18.10.2026

[QA 1.1.0](../core/docs/ADAPTIVE_T4_T5_MULTIMODAL_2026-10-18.md): интегрированы общие адаптивные редакторы в actual 1.1.0 с текстом/аудио/видео/ChickMark. Core 13/13, What 104 unit (3 skipped), iPad UI 5/5 и Duo 4 executed (2 skipped) прошли. По решению владельца физический Duo не блокирует разработку; симуляторная проверка и исправления по user feedback. Живое fold/unfold не доказано. Релиз и данные на обычном iPhone — отдельные ворота.

## Пилот iPad/Duo · 18.10.2026

В отдельной ветке feature/core-ipad-duo-pilots-20261018: ArvectumCore, читаемая библиотека/редактор, широкий/компактный layout, iPad target только для QA; Debug build PASS, 61 unit (3 skipped) и 2 UI PASS. Мультимодальная версия 1.1.0 не интегрирована и не менялась, WH-D0…D3 и физическая приёмка всё ещё открыты. [QA](../core/docs/ADAPTIVE_T4_T5_PILOT_2026-10-18.md).

## Актуальный релизный чекпоинт · 18.10.2026
**Ухват / UhWhat:** последняя подтверждённая публичная iOS версия — 1.0.1(6), ASC 18.10. **1.1.0 (build 8)** с Watch/complication/widget и интеграцией ChickMark **отправлена в App Review 18.10 09:01 МСК**: upload VALID, WAITING_FOR_REVIEW на момент [релизного аудита](https://github.com/arvectum2/arvectum-tools/blob/release/what-chickmark-20261018-rc1/what/docs/RELEASE_AUDIT_WHAT_CHICKMARK_2026-10-18.md). До READY_FOR_SALE не считать выпущенной.

- [x] **WH18-0 · Реализовано в кандидатах:** единый local-first Inbox audio/text/video, короткое касание большой кнопки — аудио, удержание — видео, отдельный «+» — текст; автонапоминания о новых заметках по opt-in Off/+1/+2/+3 ч; ручная отправка полной заметки в разовое напоминание ChickMark. Изменения не приписывать публичной 1.0.0.
- [x] **WH18-1 · QA evidence:** физическая проверка обеих камер iPhone 13, recovery и сохранности старых файлов; Watch→iPhone UUID/ACK+транскрипция; изолированная физическая связка с ChickMark (импорт, обратная ссылка, дедупликация, реальное приватное уведомление). Это разные QA-сценарии, не замена полной приёмке публичного обновления.
- [x] **WH18-2 · Подготовка Apple:** production 1.1.0(8) с RU/EN release notes, reviewer instructions и iPad скриншотом принята обработкой и отправлена на review.
- [ ] **WH18-3 · Релиз:** решение Apple, READY_FOR_SALE, storefront и безопасный upgrade без потери аудио/видео/текста и очереди Watch.
- [ ] **WH18-4 · Оставшийся QA:** физический iPad и multitasking, экстремальное завершение/**многочасовое** видео и низкая память, реальные отказы доступа камеры/микрофона, Watch ACK race, тихие часы и настоящий продакшен push/tap-through после обновления.
- [ ] **WH18-5 · После релиза:** исправления транскрипций, расширенный поиск/архив и semantic memory — без нарушения мгновенной записи.

**Связанные планы:** [ChickMark](../chickmark/ROADMAP.md), [Core](../core/ROADMAP.md), [Growth](../growth/ROADMAP.md). Старые невыполненные пункты ниже относятся к прежней версии MVP и проверяются по чекпоинту 1.1.0.


## Адаптация iPad / iPhone Duo — 2026-10-16

**Статус:** бэклог; реализация iPad **частично есть только в feature/what-multimodal-20261016**, а не в текущей main и не в опубликованной версии. [Общая матрица Core](../core/DEVICE_ADAPTATION_ROADMAP.md).

**Инфраструктура (16.10.2026):** Xcode 27.1 активна; частичная поддержка iPad уже реализована в feature/what-multimodal-20261016. Первый пилот адаптивного Core — библиотека/редактор. WH-D0…D3 остаются открытыми; Duo QA ждёт runtime iOS 27.1 (T3/T4). Проверка физической камеры и Watch — отдельно.

- [ ] **WH-D0 · Подтвердить baseline:** перенести/сверить M5a из multimodal feature-ветки и готовность iPad target family 1,2 без случайного включения в релиз.
- [ ] **WH-D1 · iPad:** сохранить одну большую круглую кнопку (короткое нажатие — аудио; долгое — видео), отдельный плюс для текстовой заметки; проверить editor, библиотеку, камеру, кнопки Стоп и смены камер, portrait/landscape/Split View/Stage Manager, VoiceOver.
- [ ] **WH-D2 · iPhone Duo:** закрытый экран — один жест записи и быстрая библиотека; раскрытый — полноценная библиотека/редактор. При fold/unfold во время видео, переключения фронтальной камеры, аудиозаписи или незавершённого текста не терять медиа/черновик и не запускать дубль записи. Watch одно касание сохраняется без изменений.
- [ ] **WH-D3 · QA и отдельный релиз:** симулятор на обоих размерах Duo, реальные разрешения Camera/Mic, recover journal, большие записи, жесты, background/foreground, Watch ACK, уведомления о заметках и App Store assets. Отсутствие Duo runtime фиксировать как блокер физической/симуляторной приёмки, а не как успешно пройденный тест.

## Active release checkpoint — 2026-10-15

**A5 RC:** [Ухват 1.0.2 (7)](../core/A5_SIGNED_RELEASE_CANDIDATES_20261015.md) подписан, iPhone/Watch/complication/widget проверены, CI PASS, **не загружен в ASC**. Отправленная 1.0.1 (6) ещё WAITING_FOR_REVIEW; физическая 1-tap/ACK/офлайн-проверка остаётся OPEN.

**Brand:** Ухват (RU) / UhWhat? (international), code directory what/.
**Public 1.0.0 (5):** READY_FOR_SALE independently rechecked in App Store Connect API 2026-10-15
(App ID 6822476399). **Submitted 1.0.1 (6):** Waiting for Review, recorded
2026-10-15. Exact details and release evidence belong to the
[1.0.1 release-branch roadmap](https://github.com/arvectum2/arvectum-tools/blob/release/what-1.0.1/what/ROADMAP.md);
release-proven iOS/watchOS source was **selectively integrated into main** 2026-10-15 via [PR #67](https://github.com/arvectum2/arvectum-tools/pull/67) (`e129efc`); private RuWordNet corpora and research pipeline were not copied.

**North star:** Catch the thought before it disappears. Reliable immediate
capture, durable original audio and Watch-to-iPhone delivery have priority.

- [x] iPhone capture-first UI, Watch recording, local Inbox/Archive,
  transcription, searchable text and sharing shipped in 1.0.0 (5).
- [x] Release 1.0.1 (6) source fixes complication to launch Watch recording
  in one tap, uses branded Watch glyph and saves active recording upon
  app backgrounding. Signed IPA and simulator tests passed, submitted.
- [x] A2 source-level queue and receiver hardening: atomic on-disk enqueue/ACK/recovery before in-memory mutations; iPhone rejects unreadable/corrupt AAC before ACK. 7/7 focused tests PASS; complete suite 61 executed, 0 failures, 3 skipped. Both Watch and iOS builds and GitHub PR CI pass. [PR #70](https://github.com/arvectum2/arvectum-tools/pull/70) merged into main at `2f9239f`. [A2 QA](docs/A2_CAPTURE_DELIVERY_QA_2026-10-15.md). Changes are **not** in Apple's submitted 1.0.1 (6) binary.
- [ ] Physical proof for 1.0.1: one Watch complication tap → audio,
  Digital Crown/background → saved playable audio on iPhone exactly once,
  including offline / ACK / reboot and duplicate-delivery scenarios.
- [ ] Measure real capture latency and playback survival; sudden power loss
  or force termination may leave unfinished AAC unplayable.
- [x] Shippable 1.0.1 source, widgets and tests integrated into main with
  source provenance, without the private RuWordNet corpus. No user-device
  records were modified in this merge; physical regression remains open.
- [ ] Keep semantic Ask Memory research out of release-critical P0.

**Updated:** 2026-10-16 (multimodal text/audio/video + iPad backlog added; no application code or release binary changed). **Shared Core:** [Core](../core/ROADMAP.md).
**Growth:** [Growth](../growth/ROADMAP.md).
**Note:** P0–P5 checklist below retains historic and research milestones.
The current main now includes the release source; unchecked device/research
acceptance cases must not be confused with absent capture, Inbox, transcript
or export features.

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Automated A2 queue crash/write-failure/offline-batch and receiver AAC integrity regression tests added; no real Watch devices tested yet.
- [ ] Complete remaining disconnected-device, multiple-pending-recording and device-reboot acceptance cases on a physical paired Watch and iPhone.
- [ ] Reconcile final physical test evidence and prove no recorded thought is lost.

## P1 — Voice + transcribed text (existing; not a manually typed note)
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [ ] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection, retry/cancel controls and transcript corrections.

## P2 — iPhone inbox
- [ ] Today/Yesterday grouping, search, archive/delete and sync status; playback available in initial list.

## P2a — Unified multimodal capture on iPhone and iPad (new backlog, 2026-10-16)

**Target experience and device matrix:**

**Capture controls (mandatory UX contract):** On **iPhone and iPad**, keep the existing **large round recording button** as the primary control: **short tap → start audio recording immediately**, **long press → start video capture with the camera** (no Text/Audio/Video selection menu). The small **`+` button opens a new typed text note only**. Watch keeps its **one-tap audio** complication and audio-only interface. Distinguish a long press from a short tap before triggering capture: a long press must never accidentally start an audio recording first. Keep obvious recording state, haptic/visual feedback, Stop/Save/cancel and permission handling for both media types.

| Device | Text note (typed) | Audio note | Video note |
| --- | --- | --- | --- |
| **Apple Watch** | — | **Yes — one-tap voice capture**, existing primary flow | — |
| **iPhone** | **Yes — compose and edit** | **Yes — keep existing fast audio capture** | **Yes — record with camera in app** |
| **iPad** | **Yes — compose and edit** | **Yes — record with microphone** | **Yes — record with camera in app** |

**Status:** backlog only; the current iOS Xcode target uses `TARGETED_DEVICE_FAMILY = 1` (iPhone only), so **native iPad support is not implemented or validated**. Existing on-device Speech audio transcription does **not** mean manually composed text notes are already supported. Preserve the current Watch capture-first/ACK reliability before introducing new capture modes; none of these changes are in the public or Apple-submitted releases.

- [ ] **M1 · Unified local note model:** one inbox for `text`, `audio`, and `video`, with stable UUID, creation/edit timestamps, explicit media kind, optional body/transcription, local original-media URL and source device. Keep Watch audio IDs, migration, ACK/dedupe and existing archives backward-compatible; never replace original media with generated text.
- [ ] **M2 · Native text note (iPhone/iPad):** `+` → Text, instant empty editor with keyboard focus, manual typing and editing, reliable local draft/autosave, cancel/delete safeguards and optional title. Text must work offline without Speech permission, microphone or camera.
- [ ] **M3 · Preserve fast audio (iPhone/iPad):** a **short tap on the existing large round record button** starts the existing audio recording immediately (no mode chooser); support playback, transcription (with explicit permission), edit transcription separately from original audio and reuse stable note identity. On Watch retain **audio-only** complication → immediate recording, with no new selection screen.
- [ ] **M4 · Native video note (iPhone/iPad):** a **long press on the same large round record button** starts video capture with the device camera **inside Ухват**, without an intermediate mode chooser; provide clear recording/Stop state, elapsed timer and preview. Resolve short-vs-long press before starting audio so a video gesture never leaves a stray audio note; show haptic/visual confirmation. Ask Camera/Microphone permissions only when needed, handle refusal and interruption, and never record without an explicit user action. Save original video locally atomically; support preview/playback, poster frame, size/duration indication and safe delete/export. If video speech-to-text is added, it must be optional and must not overwrite the video. Importing existing library videos is a separate enhancement, not a prerequisite for recording.
- [ ] **M5 · iPad-first-class UI:** expand iOS device family to include iPad, make text editor/recorders/camera preview and Inbox usable in portrait, landscape, split view and large text; ensure iPhone-specific layouts, Share sheet, permission copy, icons and Store device assets remain correct. Do not claim an iPad release until actual build and device/simulator QA passes.
- [ ] **M6 · One Inbox, sensible presentation:** preserve the **large round recording button** (short tap = audio; long press = video) and add a separate unobtrusive **`+` for typed text notes only** on iPhone/iPad; no three-way capture menu. Provide a discoverable long-press hint without cluttering the capture screen, plus type indicators, inline text, thumbnails/previews and type filters; preserve search, archive/delete, timestamps, per-note links and notification-reminder eligibility. Video assets remain local-first; sharing/synchronization across iPhone and iPad is **not automatically implied** by supporting both devices and needs a separate opt-in architecture decision.
- [ ] **M7 · Acceptance and safe release:** tests for app restart mid-draft, background/low storage while recording, media integrity after interruptions, cancelled capture, camera/mic/Speech denied, large video, deletion without orphan files, old audio-model migration, Watch offline/ACK regression, gesture arbitration (short tap audio; long press video; no unintended audio), long-press discoverability and accessibility alternatives for users unable to hold the button, iPhone+iPad layouts, permission/privacy descriptions and no implicit cloud uploads. Gate shipping behind iPhone/iPad physical QA and its own signed release; do not alter already submitted IPA or any existing user's notes.

**Proposed delivery order:** M1 + M2 (typed text first), then M3 (shared audio interface), M4 (video), M5–M7 (iPad/adaptive Inbox + acceptance). New capture modes must remain secondary to Watch's one-tap audio workflow and the existing durable queue.

## P3 — Apple Notes / Shortcuts
- [ ] Export and optional system integration without depending on cloud.

## P4 — Semantic memory
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## P6 — Follow-up reminders for captured notes (post-1.0 backlog)
- [ ] **P1 · Revisit a note later:** after saving a new text/audio/video note (including audio delivered from Watch), offer one-tap "Напомнить" with +1 / +2 / +3 hours from the time it becomes available on iPhone; allow per-note override, reschedule, cancel and mark reviewed. Keep recording/Watch transfer fast and unaffected by notification scheduling. No default reminders unless explicitly enabled by the user.
- [ ] **P1 · Optional auto-follow-up:** opt-in rule "new note → remind after 1/2/3 hours", with quiet-hour/notification-permission handling, duplicate protection by stable recording UUID and no reminders for deleted notes. Add a low-noise daily review/digest only as a subsequent option if individual alerts prove noisy.
- [ ] **P1 · ChickMark handoff:** optional local-only integration to create a distinct "Review this note" follow-up in ChickMark, **not** a recurring habit or an automatic habit completion. Carry the saved/edited transcription as the follow-up's full text, recording UUID, creation time and a deep link back to the original audio in Ухват. The notification itself defaults to privacy-safe generic text; showing transcription on the lock screen is a separate explicit choice.
- [ ] **P1 · Integration feasibility spike:** validate app-to-app transfer for the two signed iOS apps (App Group/shared container versus App Intents/Shortcuts/openURL), actual background/notification limits, permissions and behavior when ChickMark is not installed. Never require cloud, network or an always-running companion app. If unavailable, use Ухват's own local notification fallback.
- [ ] **Acceptance:** test Watch offline/delayed arrival, transcription still pending, edited transcription after handoff, app reinstall/upgrade, duplicate Watch deliveries, deleted/archived notes, ChickMark unavailable, denied notification permission, timezone/quiet hours, and tap-through to the correct audio. Do not silently copy private transcripts to shared or external destinations without opt-in.

## P7 — Запись телефонных разговоров и импорт записей (backlog, 21.10.2026)

**Цель:** хранить телефонные разговоры в едином локальном Inbox Ухвата рядом с аудио-, видео- и текстовыми заметками, с воспроизведением, транскрипцией и поиском. **Статус: не реализовано.** Не путать входящий телефонный звонок как тест прерывания текущей записи с записью содержимого разговора.

- [ ] **CALL-1 · Technical feasibility (до реализации):** проверить актуальные возможности iOS, CallKit/LiveCommunicationKit и правила App Review. Сторонние приложения сейчас не получают аудиопоток обычного сотового звонка из системного приложения «Телефон»; нельзя обещать фоновую/автоматическую/скрытую запись GSM/VoLTE через Ухват. Не использовать private API, jailbreak или обход системных ограничений.
- [ ] **CALL-2 · MVP — импорт готовой записи:** принимать записанный штатными средствами iPhone разговор через «Поделиться»/файл из Apple Notes/Files, когда системная запись доступна в регионе; предусмотреть импорт аудиофайла и ручное добавление. Создавать локальную заметку `phoneCall` с исходным неизменённым аудио, UUID, датой, названием/контактом *только по явному выбору пользователя*, воспроизведением, транскрипцией, поиском и экспортом. Переиспользовать существующие безопасные локальные модели хранения; отсутствие системной записи в регионе не должно ломать импорт других аудиофайлов.
- [ ] **CALL-3 · UX:** понятный пункт «Запись звонка» с объяснением, какие способы поддерживаются на устройстве, и кнопкой «Импортировать запись». Не показывать кнопку, якобы записывающую сотовый вызов напрямую, пока такая возможность не подтверждена официальными API. Не нарушать сценарий одной большой кнопки быстрой записи обычных заметок.
- [ ] **CALL-4 · Возможность прямой записи — отдельное исследование:** изучить только законные поддерживаемые варианты (например, вызов в собственном VoIP-клиенте с явным согласием сторон, если такой продукт будет нужен). Не добавлять VoIP-платформу или платную конференц-связь автоматически в scope Ухвата; архитектурное и коммерческое решение — отдельно.
- [ ] **CALL-5 · Privacy и приёмка:** соблюдать местные правила и согласие участников разговора; не обходить системные уведомления о записи. Все файлы локальные по умолчанию, разрешения минимальные, никакой скрытой отправки в облако. Проверить Share Sheet/Files, формат и длительность файла, транскрипцию, дубли, отмену, low storage, работу offline, миграцию старых заметок и недоступность системной записи в отдельных регионах.

**Порядок:** сначала CALL-1 → CALL-2/3 → CALL-5; CALL-4 только после отдельного решения о продуктовой необходимости.

## Later
- [ ] Optional clustering and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
