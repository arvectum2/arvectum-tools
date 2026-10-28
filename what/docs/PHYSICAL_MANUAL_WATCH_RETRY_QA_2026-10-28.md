# Ухват — физическая приёмка безопасного запроса WatchConnectivity · 28.10.2026

## Границы и оборудование

- Физический iPhone 13, iOS **27.2**, и сопряжённый Apple Watch SE, watchOS **26.6**, Developer Mode включён.
- Использовались только отдельные developer-signed QA bundles `ru.arvectum.tools.what.watchphysqa` и `ru.arvectum.tools.what.watchphysqa.watch`, версия 1.1.0 / build 20, обновлённые in-place без uninstall. Проверено подписью и идентификаторами перед установкой.
- Публичный Ухват 1.1.2, его контейнер, личные записи, параметры радио/сопряжения, системные разрешения, App Store Connect **не изменялись**. Ни одного AAC/MOV/транскрипции не копировали на Mac. Стандартный production Watch UX автоматически начинает запись при foreground; QA-сборка имеет отдельный compile-time guard `WATCH_PHYSICAL_QA`, который **отключает** этот автозапуск. После проверки guard её безопасно запустили в режиме `what-watch-qa-audit`, который читает только служебные метаданные.
- Тестовый Watch `Documents/WhatOutbound/queue.json`: **0** элементов до и после эксперимента. Считаны только QA JSON-журналы и длина очереди.

## 1. Сборка и попытка UI Automation

- QA приложение iPhone + Watch было подписано и собрано из ветки PR #157 (`WhatWatchPhysicalQA.xcodeproj`, Xcode 27.1), `BUILD SUCCEEDED`, `codesign --verify` PASS. Поверх QA установлены только QA bundles; обе установки CoreDevice успешны.
- Запущен XCUITest `SyncDiagnosticsLocalizationUITests.testWatchRetryActionReportsARequestWithoutPromisingInstantDelivery` на реальном iPhone с разблокированным экраном. Runner установился и запустился, но XCTest сообщил **`Timed out while enabling automation mode`** до исполнения UI-шага. Тест не засчитан ни PASS, ни как дефект кода. Этот физический UI gate **OPEN**. Нужна проверка `Settings → Developer → Enable UI Automation` и повтор только после подтверждения доступности automation.
- Локально на iOS Simulator в исходной версии ветки прошли **31 модульный + 4 UI = 35/35**. Отдельная watchOS simulator generic-сборка `BUILD SUCCEEDED`.

## 2. Безопасная проверка реального WCSession без XCUITest

Для независимой проверки метода, который вызывает новая кнопка, добавлена исключительно под `WATCH_ROUTE_QA` одноразовая команда запуска `--what-qa-manual-sync-request` и событие `watch-sync-request-received` на стороне Watch. QA-режим подавляет автоматическую отправку при старте **только в этой QA-сессии**, затем с задержкой 3 с вызывает тот же `PhoneConnectivityManager.requestWatchQueueRecovery()`, что и кнопка. Production не содержит этот режим.

- iPhone QA успешно запущен через CoreDevice с указанным аргументом, **без UI-автоматизации и без записи аудио**.
- Физический журнал iPhone `phone-qa-manual-after.json`: `phone-session-activation state=2,hasError=false`; `backgroundRefreshStatus=available`, `lowPower=false`, `protectedData=true`, `paired=true`, `watchInstalled=true`, `reachable=false`. Последнее означает отсутствие живого foreground канала, **не** физическое выключение Bluetooth/Wi-Fi.
- Физический журнал подтверждает `phone-sync-request note=queued` и `phone-qa-manual-request note=queued`: настоящий `WCSession.transferUserInfo` принял запрос. Это **PASS** для локальной постановки команды в очередь, но не для получения и исполнения на Watch.
- Watch event trace дважды прочитан, пока приложение Watch QA оставалось в фоне: **14 событий, `watch-sync-request-received` ещё отсутствовало**; исходящая очередь AAC — 0.
- Затем проверили `CaptureView.startCaptureOnForeground()`: при `WATCH_PHYSICAL_QA` он возвращается без запуска микрофона. На реальном Watch QA приложение было запущено **с единственным аргументом `what-watch-qa-audit`**, без записи аудио и без изменения радио.
- После явного открытия Watch QA журнал стал содержать **16 событий, включая `watch-sync-request-received` (ровно 1)**. `WCSession.transferUserInfo` принял физический запрос на iPhone и доставил его на Watch. После получения очередь AAC на часах по-прежнему 0. **E2E запрос → Watch foreground PASS; доставка без ручного открытия Watch остаётся OPEN.**

## 3. App Store: закрыт отдельный release gate

- Авторизованный App Store Connect read-only `GET`: версия Ухвата **1.1.2** — `READY_FOR_SALE`, режим `AFTER_APPROVAL`.
- Публичный iTunes Lookup read-only подтвердил **1.1.2 во всех 16 региональных вариантах ASO**: RU, US, GB, AU, CA, ES, MX, FR, DE, IT, JP, KR, BR, PT, CN, TW; один и тот же `currentVersionReleaseDate=2026-10-27T23:29:12Z`.
- Исходный PR #157 и его QA-инструментация **не входят** в опубликованный C17 бинарник.

## Остаточные ворота

1. **OPEN:** повтор физического UI XCTest при доступной iOS UI Automation; ни UI, ни служебные кнопки не трогать обходом системной блокировки.
2. **OPEN:** самостоятельная background-доставка `syncRequest` на Watch **без** открытия приложения; foreground-приём уже физически подтверждён. Никаких гарантий мгновенной доставки.
3. **OPEN:** реальный radio-offline с поздней доставкой при заблокированном iPhone, reboot Watch с pending на текущей сборке, звонок/долгие прерывания. Системные радио/питание/сопряжение без отдельного безопасного сценария не менялись.
4. **OPEN:** полноценная физическая проверка Follow-up → ChickMark, тихих часов и lock-screen privacy. Её нельзя закрыть модульными XCTest.
5. **CI:** первый GitHub `localization` обнаружил жёстко заданный исторический лимит 232 iPhone-строк вместо актуальных 237. Исправлен тестовый контракт и добавлены явные проверки новых строк; локальный `test_localization_portfolio.py` **61/61 PASS**. Проверки GitHub нужно повторно дождаться на новом SHA, protected checks не обходить.

Артефакты: `/Volumes/ArvectumSSD/Arvectum/tmp/uhvat-watch-acceptance-20261028` (только тестовые логи/JSON и DerivedData; личных аудиофайлов там нет).
