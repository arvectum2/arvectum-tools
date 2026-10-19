# QA: потерянный Watch ACK + повторная доставка того же UUID (19.10.2026)

## Задача

Проверить, что iPhone не создаёт вторую заметку, когда получил AAC, но Watch *не смог принять ACK*, поэтому повторно отправил оригинал. Запись должна оставаться в долговременной очереди на часах вплоть до второго подтверждения iPhone. Настоящий радиоканал не выключаем и сопряжение не меняем.

## Реализация QA-only

`WatchCaptureController` **только под `WATCH_PHYSICAL_QA`** реализует локальный фильтр `qaHoldAcknowledgements(for:)` для конкретного UUID и счётчик `qaDroppedAcknowledgements(for:)`. Он перехватывает оба пути: fast reply и background UserInfo, которые вызывают единый `acknowledge`. Исходная очередь и AAC остаются нетронутыми. После хотя бы одного ACK пробник проверяет наличие источника и `pendingCount>0`, затем `qaResendAfterDroppedACK` снимает фильтр и вызывает штатный `WCSession.transferFile` с **исходными метаданными UUID, createdAt, duration**. iPhone повторно проверяет валидность AAC и через `RecordingRepository.acceptTemporaryFile` дедуплицирует UUID; второй ACK завершает удаление Watch оригинала. Не используем синтетический ACK, не вызываем cleanup напрямую, не подменяем имя файла.

Режим запуска `what-watch-qa-drop-ack` активен только в отдельной Watch QA-сборке `ru.arvectum.tools.what.watchphysqa.watch` и только по явному параметру приложения. Watch timeline, status.json содержат лишь UUID и этапы: `ack-suppressed`, `ack-dropped`, `duplicate-in-flight`, `ack-observed`. Время ожидания первого ACK до 60 секунд; при отсутствии ACK спустя 60 секунд тестовый фильтр автоматически снимается, штатный `pumpTransfers` разрешён, а исходный файл остаётся на устройстве до подлинного ACK. Production-сборки и Apple App Store Connect не изменяются.

## Проверки и ограничения

- На Mac mini/Xcode 27.1 Watch QA target собран через `generic/platform=watchOS` (**BUILD SUCCEEDED**), поскольку физический Watch destination временно не доступен.
- Unit test `testLostACKRealisticAACResendPreservesSameUUIDAndDeletesOnlyAfterACK`: создаёт настоящий воспроизводимый AAC через `MicrophoneCapturePipeline`, проверяет `WatchDeliveredAudioValidation`, индекс `WatchDurableQueue`, два подряд импорта одного UUID в iPhone `RecordingRepository`, одинаковые файлы/одну заметку, удаление исходника **только после** `WatchAcknowledgementJournal.acknowledge`. Детерминированная проверка логики, а не физическая передача через WCSession.
- На раннем этапе в 09:09 МСК iPhone QA не удалось запустить из-за `FBSOpenApplicationServiceErrorDomain: Locked`, поэтому тогда физическая проверка **не проводилась**. В 09:49 МСК iPhone был разблокирован, оба CoreDevice-туннеля восстановились, штатный iPhone QA-приёмник открыт и тест **проведён**. См. подтверждённый результат ниже.

## Физический итог — PASS, 19.10.2026 09:49–09:51 МСК

**Оборудование:** физические Apple Watch SE watchOS 26.6 и iPhone 13 iOS 27.0.1, отдельные установленные QA-бандлы `ru.arvectum.tools.what.watchphysqa.watch` и `ru.arvectum.tools.what.watchphysqa`. Пользователь разрешил применить iPhone для физического теста. Транспорт использовал настоящий WatchConnectivity; никаких вмешательств в сопряжение или системные радиомодули.

1. Базовая проверка: Watch `Documents/WhatOutbound/queue.json` содержит **0 ожидающих элементов**; iPhone `recordings.json` содержит **4 уникальных UUID**, QA-приёмник запущен. Предыдущий короткий файл `E048D504-A943-49B8-AAA4-BBDEA76A0048.m4a` остался в отдельном Watch QA контейнере и **не удалён**.
2. На физическом Watch запущено **одно** QA-задание `what-watch-qa-drop-ack`, реальная новая аудиозапись UUID `63BEBAD8-68A7-4DC7-9005-07941EE3E8EE`. Watch `timeline.json`: `qa-start` +0, `recording-observed` +0.68 с, `ack-filter-armed` +0.69 с (тот же UUID), `stop-timer-fired` +8.03 с (7.35 с с момента наблюдения записи), `watch-saved` +8.12 с.
3. Watch timeline: **`ack-suppressed` +9.67 с, `count=1, sourceKept=true`** — на Watch оригинал сохранён после первого настоящего подтверждения от приёмника. Затем **`same-uuid-retransmission` +9.69 с** — тот же UUID и AAC передан повторно штатным `WCSession.transferFile` после снятия QA-фильтра.
4. После второго настоящего подтверждения Watch `status.json`: `ack-observed`, `pending=0`, оригинал отсутствует; `WhatOutbound/queue.json = []` и каталог содержит лишь старый исходник и служебный журнал.
5. Phone QA `recordings.json` после двух фактических доставок содержит **5 записей — по одному экземпляру каждого UUID**. Новый UUID встречается ровно один раз, длительность **7.612 с**, имя `Audio/63BEBAD8-68A7-4DC7-9005-07941EE3E8EE.m4a`.
6. Дополнительная проверка после `--terminate-existing` **только QA приложений**, без аргументов начала записи: iPhone по-прежнему имеет ровно **один** новый UUID, суммарно 5 уникальных записей; Watch по-прежнему `pending=0`. Никого из production bundle не запускали/переустанавливали и пользовательские записи не удаляли.

**Вывод:** реальный Watch capture, реальная доставка, искусственная потеря **первого подтверждения**, повтор того же UUID и дедупликация на iPhone физически проверены. Это **не** доказательство работы при выключенном Bluetooth/Wi-Fi или после аппаратной перезагрузки часов; эти сценарии остаются открытыми. Материалы диагностики — только JSON с UUID/метками, никакого аудио на Mac.

## Как провести физическую проверку после возврата пары

1. Подтвердить `devicectl list devices` с доступными iPhone 13 и Apple Watch SE, ранее установленные отдельные QA bundle IDs. Не переустанавливать production и не удалять Watch очередь.
2. Открыть на iPhone `ru.arvectum.tools.what.watchphysqa` для активации WCSession. Затем установить обновлённый QA Watch target, запустить `what-watch-qa-drop-ack`. Пробник начнёт одну ~7-секундную запись.
3. Прочитать *только* `WatchPhysicalQA/status.json` и `Documents/WhatOutbound/queue.json`. На этапе `ack-dropped` ожидаются `pending=1`, оригинал на Watch; после `duplicate-in-flight` и `ack-observed` ожидается пустая очередь. Из iPhone QA `recordings.json` требуется ровно одна запись с тем же UUID, не две.
4. После завершения без параметра записи безопасно перезапустить только QA-приложения и ещё раз проверить индекс/очередь. Не передавать сырое аудио на Mac и не удалять оставшийся 0,124-секундный QA-фрагмент с предыдущих тестов.
