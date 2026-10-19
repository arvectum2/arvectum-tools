# PUSHKIN — Product Roadmap

### UX/дизайн-код: очередь D1 (19.10.2026, план)

- [x] VoiceOver iOS 27: короткий тест реального озвучивания истории через XCUIVoiceOverService PASS, исправлен Search Image. Названия истории, поиска, добавления и подключения CapCut произносятся корректно.
- [ ] Проверить полный VoiceOver setup/settings/Shortcuts и системный Accessibility Audit. История коротко PASS; Settings/audit остаются opt-in.

- [x] P1: AXXXL-навигaция и настройки: Setup → каталог через всегда видимую 48pt кнопку, настройки → политика конфиденциальности; два независимых UI-теста PASS на iPhone 17 Pro Simulator. Реальный VoiceOver и физические устройства отдельно.

- [x] P0: не обещать архив всех уведомлений iOS; пустое состояние и подтверждение тестового источника уточнены (19.10.2026, локальная ветка, UI QA).
- [x] P0: 122 RU-строки для основных экранов History/Apps/Settings/Add app/обучения; EN оставлен. Build PASS, 5 unit + RU UI 1 + EN UI 4 PASS. Не полный перевод Developer/Group Planner.
- [x] P1: 34pt чип ArvectumWordmark вместо массивной плашки; iOS Simulator BUILD и UI геометрии PASS, отдельная русская UI проверка PASS, скриншот просмотрен.
- [x] P1: на светлой теме интерактивный tint тёмно-бирюзовый, главная мятная кнопка с тёмно-синим текстом (исправлен белый на mint); заголовок подключения краткий, при этом исходный идентификатор источника не меняется. Unit + 2 отдельных UI PASS.
- [x] P1: контраст подсказки поля поиска исправлен в dark/light без замены системного TextField; Simulator BUILD PASS, тёмный screenshot при Increase Contrast проверен.
- [ ] P1: проверка secondary views, VoiceOver, Dynamic Type, реальных Shortcuts-сценариев без изменения существующих автоматизаций.

Полный аудит: [единый дизайн-код](../core/docs/UNIFIED_DESIGN_CODE_2026-10-19.md).


## 19.10.2026 — App Store update prompt: E2E и релизная граница

- [x] Исходники общей проверки версии App Store и кнопок «Обновить»/«Позже» интегрированы в `main` (PR #133, коммит `08107c3`).
- [x] Симулятор iPhone 17 Pro / iOS 27.0, Debug-фикстура опубликованной версии `99.9.9`, **2/2 PASS**: «Позже» + повторный запуск и отдельное нажатие «Обновить»; изолированный симулятор без личных уведомлений.
- [ ] **Release gate:** при следующем отдельно разрешённом выпуске проверить реальный App Store URL, реальный установленный/опубликованный build, сохранность данных и поведение на физическом iPhone. До подтверждения не считать обновление доставленным пользователям.

Тестовый сценарий доступен только в Debug и исключён из Release. [Общая приёмка](../core/docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md).


## 19.10.2026, вечер — App Review 1.0.1 (5), автоматический выпуск

**Текущее:** публично **1.0** (RU Lookup). После согласования владельца **1.0.1 (build 5)** принята Apple (binary VALID), App Review **WAITING_FOR_REVIEW**, политика **AFTER_APPROVAL**. Текущая версия ещё не опубликована. [Подтверждение ASC](docs/APPLE_REVIEW_SUBMISSION_1_0_1_BUILD5_2026-10-19.md).

- [x] GitHub PR #131 **8/8 checks SUCCESS**; локальная производственная сборка и подпись IPA PASS.
- [x] На iPhone изолированный QA update 7→8: **8/8** синтетических записей сохранились с одинаковыми значениями/идентификаторами; реальная Notification→Shortcuts→AppIntent→SwiftData цепочка PASS.
- [x] Временные QA-команды удалены с подтверждением на двух Mac; пять исходных автоматизаций сохранены.
- [x] Apple build 5 связана с 1.0.1; отдельная новая Review Submission подтверждена **WAITING_FOR_REVIEW**; выпуск **автоматический после одобрения**.
- [ ] **P0 внешний:** дождаться решения Apple, проверить build5/READY_FOR_SALE/фактическое распространение RU и при необходимости других витрин; затем передать дату в Growth.
- [ ] **P1 предел QA:** на подключённом iPhone нет публичного production bundle; не объявлять upgrade реальной личной App Store базы протестированным и не перезаписывать её ради приёмки.
- [ ] Любой дополнительный build/upload/review или изменение карточки — только после нового отдельного согласия. **Ручную публикацию не включать.**

[Канонический портфельный светофор](../core/docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md). **Ниже — исторические чекпоинты, включая отозванную 1.0.1(4); они не отменяют текущий App Review.**


## 19.10.2026 — Apple Review submitted, Pushkin 1.0.1 (5)

- [x] All 8 GitHub PR checks SUCCESS; signed IPA hash and physical QA verified.
- [x] Apple uploaded build5, marked VALID, attached it to version 1.0.1 and accepted new App Review submission. Version and submission now WAITING_FOR_REVIEW.
- [x] Release policy AFTER_APPROVAL confirmed: automatic publication after Apple approval, not manual.
- [ ] Await Apple's decision: public version still 1.0 until approval. Actual personal production app upgrade not tested, isolated QA data-preserving upgrade PASS.
- [ ] Further new uploads or submissions require new explicit owner permission.
- [x] Detailed audit: docs/APPLE_REVIEW_SUBMISSION_1_0_1_BUILD5_2026-10-19.md.


## 19.10.2026 — Release Candidate Pushkin 1.0.1 (5)

- [x] Production Release archive, locally exported Distribution-signed App Store IPA and SHA-256 ready. NO upload to Apple.
- [x] Physical QA bundle upgraded in place from build 7 to 8 with 8 of 8 records completely equal (all persisted fields and identifiers). Existing notification automation E2E and cleanup also passed.
- [x] Designated project CI unit, A6 onboarding, and notification deletion suites passed on a clean simulator. Separate legacy all-UI exploratory suite failed preconditions and was stopped; test-harness debt remains documented.
- [ ] Actual public App Store Pushkin app is NOT installed on connected iPhone, so production-user history upgrade is not verifiable there. Do not claim completed.
- [ ] APPLE REVIEW AND UPLOAD are blocked until the owner's explicit approval for exactly this build. After approval use automatic AFTER_APPROVAL availability, never manual.
- [x] Candidate and evidence: docs/PUSHKIN_1_0_1_BUILD5_RELEASE_CANDIDATE_2026-10-19.md.


## P0 — 19.10.2026, итог: реальный триггер Shortcuts ПРОЙДЕН

- [x] Настоящая локальная нотификация iPhone → iOS 27 Shortcuts Notification trigger → QA AppIntent → штатная логика CaptureNotificationIntent → SwiftData. Маркер 0 → 1, всего 7 → 8 записей, повторный аудит после очистки подтверждает тот же UUID без дублей. Документ: docs/PHYSICAL_NOTIFICATION_SHORTCUTS_E2E_ACCEPTED_2026-10-19.md.
- [x] ОБЕ временные QA-команды удалены через iOS после подтверждения iCloud. Physical XCTest 2/2 PASS; Mac mini + MacBook Air подтвердили 0 совпадений.
- [x] Пять исходных автоматизаций сохранены (отдельный read-only iPhone XCTest PASS), тестовое отложенное уведомление отменено по собственному ID.
- [ ] Перед релизом всё ещё не проверено обновление публичного production приложения с реальной личной историей; не подвергать данные риску.
- [ ] В Apple ничего не подавать без отдельного согласования владельца. Публично 1.0, 1.0.1(4) отозвана, при согласованной будущей подаче публикация AFTER_APPROVAL.


## P0 — 19.10.2026 16:32 МСК: точечная очистка Shortcuts завершена

- [x] Повторный запуск XCUI после ввода владельцем пароля непосредственно на iPhone: scoped `CleanupOneAuthorizedQAShortcutUITests` нашёл **одну** пустую `Новая команда 4`, удалил её после системного подтверждения iCloud. `QA_ONLY_SHORTCUT_DELETED`, `QA_PREEXISTING_ITEMS_RETAINED`, `TEST SUCCEEDED`.
- [x] После теста штатный `shortcuts list` на **Mac mini и MacBook Air** возвращает **0** совпадений с `Новая команда 4`. Тестовая команда не осталась в синхронизируемой библиотеке. QA-автоматизация не была активирована.
- [ ] Сквозной E2E «получено уведомление → Shortcuts → Пушкин» **по-прежнему не проверен**: нужный временный Notification trigger не был найден/настроен. Пять прежних автоматизаций не менялись. Никаких действий в Apple ASC нет, повторная отправка 1.0.1(4) запрещена до явного разрешения.
- [x] Результат локального физического QA и лог сохранены в `/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-temporary-automation-20261019`.


## P0 — 19.10.2026: временная QA-команда, требуется удаление

- [ ] Дополнительный блокер 16:19 МСК: iPhone требует код-пароль в системном диалоге XCTest Enable UI Automation. Runner запускается, но XCTest завершается ожиданием подтверждения. Код вводить только на iPhone. Тестовую команду пока НЕ удалили.

- [ ] Пустая тестовая "Новая команда 4" (из разрешённой проверки iOS 27) пока существует в синхронизируемой библиотеке Shortcuts. Действий и триггеров у неё нет, ничего не включено. XCTest заблокирован системной ошибкой доверия Apple Development. После восстановления доверия удалить только эту команду и проверить отсутствие в CLI.
- [ ] Реальная доставка через Notification trigger остаётся НЕ ПРОВЕРЕННОЙ. Перед повторным тестом обязательно завершить очистку. Протокол: docs/SHORTCUTS_IOS27_TEMP_QA_PENDING_CLEANUP_2026-10-19.md.
- [x] Экспериментальные мутирующие UI-тесты вынесены из Git worktree в локальные QA-артефакты. Никаких действий с Apple Store Connect не выполнялось.


## 19.10.2026 · PR #130 merged, QA snapshot after cleanup

- [x] [PR #130 MERGED](https://github.com/arvectum2/arvectum-tools/pull/130) → `main` (`65d69d1`). GitHub CI `build-for-testing`, `delete-regression`, architecture, catalog, GitVerse — **PASS** after rerunning a transient simulator `Failed to get background assertion` failure.
- [x] Physical iPhone 13 independent QA bundle: **5 prior synthetic records + 1 QA sentinel persisted across in-place upgrades**, same sentinel UUID; direct production AppIntent invoked with synthetic input twice → **one** persisted notification, all 6 earlier records retained. QA source is fully isolated from the production app target.
- [x] Native Shortcuts read-only navigation to **Automation** works. In a separate experiment the bottom floating `+` unexpectedly created an **empty new Shortcut** (not a notification automation). That exactly identified **zero-action** QA-created item was deleted with the native iCloud confirmation; scoped physical XCTest **1/1 PASS**, verifies other known shortcuts remain. No user's existing automation was switched on or edited. Exploratory mutating test code was removed and **never merged**.
- [ ] **Real incoming notification → Shortcuts automation → Pушкин capture** is **UNVERIFIED**. Both Macs independently failed to sign a fresh QA-only shortcut, **NSURLErrorDomain 500 / 504** even on unchanged template. Do not substitute direct AppIntent success or the pre-import preview for genuine Shortcuts trigger delivery.
- [ ] To close the remaining E2E gate, first establish a safe dedicated test automation and guaranteed cleanup path. Any alteration of existing user Shortcuts or iCloud library requires a separate explicit permission; never experiment with the floating `+` again.
- [ ] **Apple release gate:** version **1.0.1(4) remains withdrawn** (`DEVELOPER_REJECTED`), public **1.0**. No upload or App Review submission without explicit approval for a precisely identified future candidate. If approved, `releaseType=AFTER_APPROVAL` so approval publishes automatically, no manual release hold.


## СТРОГИЙ RELEASE-GATE · актуально 19.10.2026, после указания владельца

- [x] Неавторизованная заявка **1.0.1(4) отозвана** (API reviewSubmissions canceled=true, HTTP 200); конечный `reviewSubmission.state=COMPLETE`, `appStoreVersion.appStoreState=DEVELOPER_REJECTED`. Это НЕ активная проверка Apple, опубликованной осталась 1.0.
- [x] Для версии 1.0.1 установлено **releaseType=AFTER_APPROVAL** — автоматический выпуск **только после новой, отдельно согласованной отправки и одобрения**. Сейчас выпуск невозможен, поскольку заявка закрыта.
- [x] QA-only iPhone 13, неразрушающий in-place update `ru.arvectum.tools.notify.physicalqa`: 5 прежних синтетических уведомлений на build 1 → build 2 (+1 уникальный sentinel) → build 3: **6/6 сохранены**, sentinel UUID совпадает, без uninstall.
- [x] Новый DEBUG-only QA вызов **реального CaptureNotificationIntent → SwiftData** дважды подряд создал ровно **один** новый синтетический объект, старые 6 ID на месте (**7** записей). Это тест AppIntent, **не** триггера входящего системного уведомления.
- [x] Реальный UI приложения Shortcuts физически доступен: через `BackButton` из вложенной страницы найдена и открыта вкладка `Automation`; read-only тест успешно прошёл и не трогал существующие автоматизации.
- [ ] Реальная новая QA Shortcuts-автоматизация/уведомление 1.0.1 НЕ ПРОВЕРЕНЫ: `shortcuts sign --mode anyone` вернул **NSURLErrorDomain 500** как для QA-файла, так и для исходного неизменённого control template. Нет подписанного QA shortcut, нет импортированной временной автоматизации, никаких существующих автоматизаций не изменяли.
- [ ] Перед разрешением на следующую отправку: подписать отдельный QA shortcut при восстановлении сервиса, создать и затем удалить одноразовую тестовую автоматизацию без изменения пользовательских, подтвердить реальное уведомление end-to-end; приложить результаты к финальному чек-листу; только затем **спросить** владельца о загрузке/отправке конкретной новой сборки.
- [ ] **Любая загрузка IPA/TestFlight и App Review запрещены без отдельной команды владельца.** См. [AGENTS.md](../AGENTS.md).


## ВЫПОЛНЕНО · 19.10.2026 — релиз 1.0.1(4) в очереди Apple

- [x] [PR #126](https://github.com/arvectum2/arvectum-tools/pull/126) **MERGED** (`22b0f69`), полный CI SUCCESS; signed IPA build **4**, источник `5876711`, iPhone-only. 20/20 физических unit/UI QA и 1/1 native signed Shortcut preview без импорта PASS.
- [x] ASC Validate/Upload **SUCCEEDED**, обработка **VALID**, version **1.0.1**, build **4**, RU/en-US What's New и имеющиеся iPhone скриншоты/Review Detail. Review submission **WAITING_FOR_REVIEW**, version **WAITING_FOR_REVIEW**, release **MANUAL**; **не опубликовано**, публично ещё 1.0.
- [ ] По реальной Shortcuts automation: QA-only файл был сгенерирован из шаблона с привязкой к QA App Intent, но Apple `shortcuts sign --mode anyone` отвечал `NSURLErrorDomain 500`; файл **не импортировали**. Read-only Automation XCTest не нашёл вкладку, **0 изменений личных автоматизаций**. Настоящая доставка через новую тестовую автоматизацию **не доказана**; не приписывать статусу WAITING_FOR_REVIEW готовность этого сценария.
- [ ] После ответа Apple: вручную выпустить при одобрении, проверить наличие в RU storefront, подписанное in-place production upgrade и сохранность истории — **никакого uninstall/сброса**.


## Физическая приёмка iPhone 13 · обновлено 19.10.2026, 13:05 MSK

- [x] Источник патча `1.0.1(4)` в независимом Apple Development QA bundle `ru.arvectum.tools.notify.physicalqa`: **17/17 unit + 3/3 UI = 20/20 PASS**, 0 errors. Поиск, удаление одной синтетической записи, очистка только тестовой истории, доступность подписанных пакетов.
- [x] Дополнительный [native Shortcuts preview](docs/PHYSICAL_SHORTCUT_PREVIEW_ACCEPTANCE_2026-10-19.md): **1/1 physical iPhone UI PASS** — открытие базового signed 1,000-app Shortcut в приложении Apple Shortcuts, наличие native **Add Shortcut**; принципиально **не нажимали Add**, не меняли личные автоматизации. [Draft PR #126](https://github.com/arvectum2/arvectum-tools/pull/126).
- [ ] Доказать именно **реальную доставку уведомления от новой временной Shortcuts-автоматизации** с контролируемой установкой/удалением; нет полномочия считать просмотр Shortcut активацией.
- [ ] Проверить безопасное обновление реальной установленной публичной версии с сохранением истории. QA-бандл отличается от Store; подписанный для App Store 1.0.1(4) **не загружен**.


## P0 · CI подписанного 1.0.1(4) завершён (19.10.2026)

- [x] [Draft PR #126](https://github.com/arvectum2/arvectum-tools/pull/126): **build-for-testing SUCCESS, delete-regression SUCCESS**, architecture/catalog/GitVerse SUCCESS на последнем коммите. Подписанный iPhone-only архив и IPA ранее проверены на исходном SHA 5876711, включая 1001 shortcut; App Store 1.0 пока не менялся.
- [ ] Перед Apple: реальная Shortcuts-автоматизация и доставка тестового уведомления, физический migration/upgrade с сохранением пользовательской истории. Ни прежние изолированные unit/UI тесты, ни зелёный CI не доказывают эти операции.


## Исполнение P0 · 19.10.2026 — подписанный patch без отправки Apple

- [x] **PS19-1a · Локальный RC:** отдельная ветка [release/pushkin-1.0.1-build4-20261019](https://github.com/arvectum2/arvectum-tools/tree/release/pushkin-1.0.1-build4-20261019), [draft PR #126](https://github.com/arvectum2/arvectum-tools/pull/126). Собраны и проверены signed archive + IPA **1.0.1(4)**, iPhone-only, 1001 shortcuts, Apple Distribution и SHA-256; source commit `5876711`. [Release provenance](https://github.com/arvectum2/arvectum-tools/blob/release/pushkin-1.0.1-build4-20261019/pushkin/docs/RELEASE_PATCH_1_0_1_BUILD4_20261019.md).
- [x] **PS19-1b · Code QA:** новый patch `build-for-testing` PASS, **17/17 unit PASS**. Предыдущая физическая изолированная QA 18.10: **17 unit + 3 UI PASS** (реальные пользовательские уведомления не трогали).
- [ ] **PS19-1c · Gate:** новый simulator UI-запуск неоднократно **BUILD INTERRUPTED**, не PASS. GitHub PR CI пока исполняется; настоящие Shortcuts/App Intents и тестовая доставка уведомления с сохранением истории требуют согласованной физической проверки. **IPA не загружать в ASC и не отправлять на review до прохождения gate.**


## Текущий публичный статус и P0 · 19.10.2026

- [x] **PS19-0 · Опубликовано:** Apple RU storefront возвращает **Pushkin 1.0** (дата Apple 18.10.2026 21:34:41 UTC). [Публичная карточка](https://apps.apple.com/ru/app/id6817847111); [общий аудит](../core/docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md). Старые ожидания Apple ниже — исторические срезы.
- [ ] **PS19-1 · Срочный безопасный patch:** публичная 1.0 — первоначальный отправленный build; исправления unsafe SwiftData deletion, micro-shortcut resource и guided A6 onboarding уже **в `main`, но не в публичной версии**. Подготовить новую подписанную patch-версию с однозначным source→build mapping, проверить на изолированных данных unit/UI и миграцию; не подменять старый бинарник и не загружать автоматически.
- [ ] **PS19-2 · Физический gate:** безопасно создать отдельную тестовую запись, проверить удаление одной/нескольких записей без повреждения чужой истории; реальный захват через Shortcuts/App Intents, offline/refresh micro shortcut, две группы, права и бездублирование. Перезапуск/удаление production-приложения не использовать.
- [ ] **PS19-3 · Далее:** локализация интерфейса RU, iPad/Duo device acceptance, улучшения сохранения/отложенных напоминаний. Физическое устройство/Apple review новой patch-версии — отдельные критерии; текст истории не передавать рекламным SDK.



## PR #90 объединён в main · 18.10.2026

- [x] Адаптивные History/Search/Setup/Settings и существующие безопасное удаление, Shortcuts/onboarding интегрированы в main, PR #90, 38/38 CI.
- [x] Независимый iPhone Xcode 27.1 прогон удаления: 3/3 unit и 3/3 UI, включая удаление всей истории на тестовом симуляторе. Один GitHub runner завис на запуске приложения и был успешно повторён.
- [ ] Отправленный Apple 1.0.0(1) не менялся; живые уведомления, реальные Shortcuts, App Review и отдельная iPad-публикация остаются незакрытыми.


## Актуализация · 18.10.2026
**Последний проверенный App Store Connect:** iOS 1.0.0(1) WAITING_FOR_REVIEW 15.10, **публичный релиз не подтверждён**. Это датированная проверка, а не утверждение о состоянии Apple на 18 октября. Signed 1.0.1(3) A5 не загружалась по последним документированным данным.

- [x] **PS18-0 · Код:** fixes безопасного удаления и Shortcuts micro-resource + управляемая настройка A6 merged в main/CI. Это НЕ содержимое 1.0.0(1), отправленной Apple.
- [ ] **PS18-1 · ASC:** проверить актуальное решение Apple, в случае READY_FOR_SALE зафиксировать публичную доступность и только затем готовить безопасный patch.
- [ ] **PS18-2 · Физический QA:** разрешения Shortcuts, загрузка/обновление micro shortcut, группы автоматизаций, реальные push без потерь/дублей, удаление только тестовой записи. Не сбрасывать пользовательскую историю.
- [ ] **PS18-3 · После стабильности:** RU in-app, короткий onboarding, Save/Done, snooze и правила; iPad/Duo по матрице Core. РСЯ не должна получать текст уведомлений.

**Примечание:** 25 элементов — размер удобной группы в A6, не доказанный системный лимит; физически сохранялся триггер 1000 SelectedApps, но доставка от всех источников не подтверждена.


## Адаптивный пилот Pushkin · 18.10.2026

[QA](../core/docs/ADAPTIVE_CHICKMARK_PUSHKIN_2026-10-18.md): iPad-ориентации, читаемые History/Search, Setup и Settings, SwiftUI-native sidebar на широком экране. Debug build PASS; fixture истории, поиск и вкладки через поворот **4/4 UI PASS** на Duo/iPad. Реальные Shortcuts/notifications и релиз остаются открыты; пользовательская история не затронута.

## Адаптация iPad / iPhone Duo — 2026-10-16

**Статус:** бэклог P1 после стабильности Shortcuts и приёмки уведомлений; текущий target iPhone-only. [Общая матрица Core](../core/DEVICE_ADAPTATION_ROADMAP.md).

**Инфраструктура (16.10.2026):** Xcode 27.1 активна, общий адаптивный Core — прототип вне main. PS-D0…D3 остаются открытыми; Duo QA ждёт iOS 27.1 Runtime (T3/T4). Текущий Shortcuts/onboarding не затрагиваем.

- [ ] **PS-D0 · Аудит:** onboarding для Shortcuts, импорт подписанных micro-shortcut, лента/детали/поиск/фильтры/архив, SwiftData, уведомления и privacy при широком экране.
- [ ] **PS-D1 · iPad:** адаптивная лента + детали/поиск, удобный onboarding и группы автоматизаций, split-view/landscape, корректные share/sheet/popover, крупный шрифт и клавиатура.
- [ ] **PS-D2 · iPhone Duo:** внешняя компактная лента и раскрытая двухколоночная лента/детали; fold/unfold и многозадачность не сбрасывают поиск, выбранное уведомление или незавершённый onboarding. Содержимое уведомлений не показывать неожиданно на другом экране.
- [ ] **PS-D3 · QA:** сохранность истории, без дублей/потерь, физические Shortcuts/App Intents и запросы разрешений, iPad/Duo UI matrix, App Store assets. Включение iPad family и релиз — отдельно, после физических проверок.

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
