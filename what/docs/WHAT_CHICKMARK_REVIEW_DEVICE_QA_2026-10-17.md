# Изолированная приёмка «Ухват → ChickMark» — 17.10.2026

## Статус: simulator PASS; actual iPhone UX/UI/notification gate OPEN

QA-ветка `qa/what-chickmark-review-device-20261017` основана на `feature/what-chickmark-note-handoff-20261017` (`3962376`). Из неё **не выпускать** App Store архив, не сливать в main без отдельного решения. Всё лежит на `/Volumes/ArvectumSSD/Arvectum`.

### Изоляция на реальном iPhone 13

Для физической QA создана пара отдельных подписанных iPhone-only приложений:

| Сборка | Bundle ID | Источник обратной ссылки | URL приёмника |
|---|---|---|---|
| Ухват Review QA | `ru.arvectum.tools.what.reviewqa` | `whatreviewqa://note/<UUID>` | открывает `chickmark-review-qa://review-import/<nonce>` |
| ChickMark Review QA | `ru.arvectum.tools.chickmark.reviewqa` | принимает текст через системную SwiftUI `PasteButton` | `chickmark-review-qa` |

Идентификаторы приложения, контейнеры, URL-схемы и подписи отличны от **ранее существующих** `ru.arvectum.tools.what.qa`, `ru.arvectum.tools.what.p2aqa`, `ru.arvectum.tools.habits` и их Watch/Widget-компонентов. ChickMark Review QA **не включает Watch и Widget в графе встраивания**, не имеет подписанных iCloud/HealthKit/App Group/APS entitlement; в app bootstrap дополнительно отключены CloudKit, WatchConnectivity, HealthKit/widget coordinator и реклама (компиляционный флаг `REVIEW_HANDOFF_QA`). Ухват Review QA не активирует WatchConnectivity. Приложения не видят пользовательские контейнеры исходных iOS bundle IDs. `InfoPlist.strings` в QA-ветке переименованы для явного отличия тестового Ухвата.

**Физическая установка первой подписанной пары:** обе v101 успешно установлены на `iPhone 13 / 00008110-001C51810A12401E`, проверены подписи, собственные bundle IDs и успешный запуск через `devicectl`. Production/существующие QA/Watch не удалялись и не обновлялись. Этот ранний вариант на физическом iPhone использовал первоначальную целевую URL-схему `chickmark-review`; при обнаружении конфликта аналогичных приложений в симуляторе заменили её на **отдельную `chickmark-review-qa`**. **Новые подписанные бинарники с исправленным уникальным URL и читаемыми QA-названиями готовы, но НЕ установлены на физический iPhone**: на момент завершения Xcode показывает iPhone `unavailable`. Не путать успешный результат симулятора с физическим.

**Физический XCTest UI runner:** `physical-ui-review1.log` → `Failed to initialize for UI testing: Timed out while enabling automation mode` (XCTest future code 1000). Не было ни полного E2E, ни тестовой доставки уведомления. Раннер остановлен после превышения ожидаемого времени, не затронув приложения пользователя.

### Simulator QA, native authorization + saved data (iPhone Duo iOS 27.1)

- `sim-allow-notifications-save3.log`: **`TEST SUCCEEDED`**. Уточнённый XCTest выбирает системную кнопку **`Allow`**, а не `Don't Allow` (первоначальный `CONTAINS Allow` ошибочно принимал отказ). После `PasteButton` и явного `Создать` ChickMark Review QA сохранил импортированную разовую задачу и отдельное локальное вложение с текстом, датой, типом, UUID и `whatreviewqa://`-ссылкой. QA-данные после проверки находились в `Library/Application Support/ChickMark/note-review-attachments.json`, не в исходном ChickMark.
- `sim-final-save-qa-ui.log`: **`TEST SUCCEEDED`** (самая новая UI-разметка и кнопка «Открыть заметку из Ухвата»). Проверена повторная синтетическая передача и сохранение при уже разрешённых уведомлениях; после теста обнаружено **3 локальных QA-вложения**, без копирования их содержимого в отчёт.
- `sim-final-linkback3.log`: **`TEST SUCCEEDED`**. Реальный системный переход по пользовательской кнопке из ChickMark Review QA → `Открыть оригинал в Ухвате` → отдельное приложение Ухват Review QA → библиотека с подсвеченной исходной заметкой. Кнопка открытия заметки доступна прямо в карточке и в меню.
- `chick-full-regression-review.log`: **14 XCTest (импорт + backup), 0 failures, `TEST SUCCEEDED`**. Дополнительная проверка не раскрывает транскрипцию в тексте push **даже если локальный файл вложения отсутствует**; обычные one-off напоминания не изменяются.
- Передача по nonce/TTL, локальный буфер, отдельно подтверждаемое сохранение и идемпотентный UUID протестированы в исходной feature-ветке. Несколько совмещённых прогонов на iOS 27.1 Simulator прерывались из-за нестабильного XCTest runner/Xcode build `invalidDigitCount(94232)`; независимые сценарии запускали **по одному** и фиксировали чистые `TEST SUCCEEDED`.

### Готовые обновлённые подписанные бинарники (ТОЛЬКО на ArvectumSSD)

- Ухват: `/Volumes/ArvectumSSD/Arvectum/builds/review-device-qa-20261017/WhatDerived/Build/Products/Debug-iphoneos/WhatIOS.app`
- ChickMark: `/Volumes/ArvectumSSD/Arvectum/builds/review-device-qa-20261017/ChickDerived/Build/Products/Debug-iphoneos/HabitsByArvectum.app`

Оба: `xcodebuild -destination generic/platform=iOS`, automatic signing `VML75VY94V`, `codesign --verify --strict --deep PASS`. Убедились, что ChickMark не содержит встроенных Watch/widget и не имеет опасных/shared entitlements; приложения имеют схемы `whatreviewqa` и `chickmark-review-qa` соответственно. **Не отправлялись в ASC/TestFlight**.

### Оставшиеся реальные блокеры/acceptance

1. Пользователь подключает/разблокирует iPhone 13 и оставляет его активным для XCTest UI automation; в `devicectl list devices` требуется `connected/available`, не `unavailable`. Проверить, что USB-кабель и Developer Mode активны. Ранний runner `Timed out while enabling automation mode` может потребовать отдельно доверить Mac/Xcode или перезапустить устройство, но не сбрасывать данные и не переставлять старые приложения.
2. Перед установкой последних `.app` сверить точные bundle IDs и активные app URLs; обновить **только две reviewqa-копии** in-place. Повторно убедиться, что старый `ru.arvectum.tools.what.p2aqa` и ChickMark остались без изменений.
3. На физическом iPhone пройти: создание синтетической текстовой заметки → системный PasteButton → разрешить локальные уведомления → подтвердить разовое напоминание → полный текст → источник в Ухвате → повторить отправку без дубликата.
4. Отдельно дождаться *реального* локального уведомления в ChickMark Review QA и проверить переход по тапу, включая заблокированный экран, отсутствие транскрипции в title/body, фоновые состояния и часовой пояс. Текущие simulator acceptance и unit tests **не означают физической доставки**.
5. Только после физической приёмки решать, как переносить функциональность в общую релизную ветку и как обновлять disclosure о локальной передаче через pasteboard.

### Финальный offline-чекпоинт после дополнительных исправлений (22:08 MSK)

- **Обратный переход по UUID:** `sim-linkback-return-modal-fix.log` — `TEST SUCCEEDED`. Исправлено не самó открытие исходного UUID (оно уже работало), а то, что старое окно подтверждения отправки оставалось поверх возвращённой заметки. Теперь при успешном `UIApplication.open` окно закрывается.
- **Повторный импорт одного UUID:** `sim-linkback-resend-inline-e2e.log` — `TEST SUCCEEDED`. Один интегрированный сценарий проверяет создание заметки, системную вставку, разрешённые уведомления, создание разового напоминания, исходный full-text link и повторную отправку **той же** заметки. ChickMark показывает постоянный предупреждающий блок «Заметка уже передана» и отключает «Создать», вместо ненадёжного раннего модального предупреждения. Несколько повторных передач не создают новые задачи для исходного UUID.
- **Единый последовательный UI-поток:** `ReviewNoteTransferFlowSheet` переключает представление из системной вставки в предпросмотр **внутри одного sheet**, устраняя гонку анимации между двумя разными sheet при повторном запуске.
- **Полная iOS-регрессия Ухвата:** `what-full-unit-regression.log` — **104 теста, 3 environment skips, 0 failures, `TEST SUCCEEDED`**. Отдельно `chick-review-backup-privacy-regression.log` — **14 tests, 0 failures, `TEST SUCCEEDED`**, включая *полный JSON backup roundtrip reviewNotes + merge/replace + старый backup без reviewNotes + corrupt source URL*, все с тестовыми отдельными файловыми каталогами.
- **Конфиденциальность при нарушении целостности:** общий безопасный заголовок push выбирается даже при отсутствующем вложении, если название создано по зарезервированному правилу импорта. Текст не должен утечь на экран блокировки после неполного восстановления.
- **Сборки последнего кода без физического iPhone:** `what-latest-offline-signed.log` и `chick-latest-offline-signed.log` — **`BUILD SUCCEEDED`** для `generic/platform=iOS` с automatic signing; обе `.app` прошли `codesign --verify --strict --deep` с независимыми bundle IDs `ru.arvectum.tools.what.reviewqa` и `ru.arvectum.tools.chickmark.reviewqa`. Обновлены **только файлы на ArvectumSSD**, на физический iPhone после его отключения ничего не устанавливали.
- QA-вариант Ухвата использует собственные `ReviewQA/{en,ru}.lproj/InfoPlist.strings`, а **основные** `WhatIOS/{en,ru}.lproj/InfoPlist.strings` не изменены. Вторичные симуляторы iPad и Watch выключены, их runtime и данные сохранены.

**Физический блокер остаётся открытым:** когда владелец снова подключит iPhone, установить только эти две **обновлённые** QA-копии in-place, проверить реальное появление локального уведомления/переход по нему и privacy разрешения на телефоне. Более ранние QA-копии v101 на телефоне не соответствуют финальным исправлениям этого checkpoint. Публичные приложения, основные QA и Watch не заменять. Этот checkpoint **не разрешение на релиз**.

### Физический iPhone после повторного подключения — 22:22 MSK

- `xcrun devicectl list devices`: **iPhone 13 connected** и paired. Без удаления приложений поставлены **in-place** две уже подготовленные отдельно подписанные QA-сборки: `ru.arvectum.tools.what.reviewqa` и `ru.arvectum.tools.chickmark.reviewqa`. Обе успешно запускаются через `devicectl device process launch`. На экране имя источника теперь «Ухват Review QA», схема получателя — `chickmark-review-qa`, а source deep link — `whatreviewqa`.
- **Хранилище ChickMark Review QA не повреждено**: до обновления скопировали `Library/Application Support` в `.../device-backup-before-20261017-2218/chickmark-reviewqa-before`, после — в `.../chickmark-reviewqa-after`. **6 из 6 файлов идентичны по SHA-256**. Отдельный бэкап пустого Application Support источника также сохранён. Основной Ухват QA (13), P2a QA (1), рабочие ChickMark и Apple Watch не обновлялись.
- **Физическое XCTest всё ещё заблокировано авторизацией хоста:** `physical-sanity-qa-20261017.log` и повторный `physical-sanity-after-auth-request.log` показывают запуск подписанного `WhatIOSUITests-Runner`, после чего `Failed to initialize for UI testing: Timed out while enabling automation mode` **до первого теста**. `/usr/bin/automationmodetool` на Mac mini сообщает `Automation Mode is disabled. This device requires user authentication to enable Automation Mode.` Автоматическую настройку, снимающую запрос авторизации на всем Mac, **не включали**.
- Для продолжения нужен ввод пароля Mac/iPhone при системном запросе XCTest, а также разблокированный бодрствующий iPhone. Это не подтверждение неправильной работы интеграции. Физический пользовательский E2E и реальная доставка уведомления остаются **ОТКРЫТЫМИ**. Запуск тестов из симулятора ранее полностью прошёл, но **не заменяет физическую приёмку**.

### Физическая приёмка после повторной авторизации — 22:49 MSK, PASS

- По просьбе владельца повторно запущен физический `xcodebuild` UI automation на iPhone 13; ранее Xcode зависал на `Timed out while enabling automation mode`, но **22:47:28 тестовая среда начала выполнять реальные XCTest-команды**.
- `builds/review-device-qa-20261017/physical-automation-request-2246.log`: **`testCaptureFirstHomeAndLibraryBackNavigation` — PASS 10.331 s; `TEST SUCCEEDED`**.
- `builds/review-device-qa-20261017/physical-crossapp-linkback-duplicate-2248.log`: **`testSavedChickMarkReviewOpensOriginalSourceNote` — PASS 32.634 s; `TEST SUCCEEDED`**. Реальный iPhone QA поток создал синтетическую текстовую заметку, передал её через системный `PasteButton` в изолированный ChickMark Review QA, нажал «Создать», нашёл вложение у разового напоминания, открыл оригинал по source URL и повторно отправил тот же UUID; получатель показал недублируемую заметку с неактивным «Создать».
- Дополнительная независимая проверка содержимого **реального** QA-контейнера с `devicectl device copy from` в `builds/review-device-qa-20261017/device-physical-e2e-2249/chickmark-support`: `note-review-attachments.json` содержит **1 импорт**, sourceURL только `whatreviewqa://note/<UUID>`, UUID уникален, полный текст присутствует. Содержимое текста не распечатывалось в отчёте. Основные приложения и Watch не затронуты.
- **Состояние после успешного теста:** ранее открытый блокер Xcode Automation Mode для физического E2E **ЗАКРЫТ**. **ОСТАЛОСЬ** проверить фактическую доставку запланированного local notification на экран iPhone и нажатие на уведомление. Данный E2E подтверждает создание напоминания и сохранение, но не факт физической доставки через 1–3 часа. Никакого App Store-релиза не делали.
