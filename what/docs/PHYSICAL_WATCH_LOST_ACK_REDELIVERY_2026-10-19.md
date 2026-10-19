# QA: потерянный Watch ACK + повторная доставка того же UUID (19.10.2026)

## Задача

Проверить, что iPhone не создаёт вторую заметку, когда получил AAC, но Watch *не смог принять ACK*, поэтому повторно отправил оригинал. Запись должна оставаться в долговременной очереди на часах вплоть до второго подтверждения iPhone. Настоящий радиоканал не выключаем и сопряжение не меняем.

## Реализация QA-only

`WatchCaptureController` **только под `WATCH_PHYSICAL_QA`** реализует локальный фильтр `qaHoldAcknowledgements(for:)` для конкретного UUID и счётчик `qaDroppedAcknowledgements(for:)`. Он перехватывает оба пути: fast reply и background UserInfo, которые вызывают единый `acknowledge`. Исходная очередь и AAC остаются нетронутыми. После хотя бы одного ACK пробник проверяет наличие источника и `pendingCount>0`, затем `qaResendAfterDroppedACK` снимает фильтр и вызывает штатный `WCSession.transferFile` с **исходными метаданными UUID, createdAt, duration**. iPhone повторно проверяет валидность AAC и через `RecordingRepository.acceptTemporaryFile` дедуплицирует UUID; второй ACK завершает удаление Watch оригинала. Не используем синтетический ACK, не вызываем cleanup напрямую, не подменяем имя файла.

Режим запуска `what-watch-qa-drop-ack` активен только в отдельной Watch QA-сборке `ru.arvectum.tools.what.watchphysqa.watch` и только по явному параметру приложения. Watch timeline, status.json содержат лишь UUID и этапы: `ack-suppressed`, `ack-dropped`, `duplicate-in-flight`, `ack-observed`. Время ожидания первого ACK до 60 секунд; при отсутствии ACK спустя 60 секунд тестовый фильтр автоматически снимается, штатный `pumpTransfers` разрешён, а исходный файл остаётся на устройстве до подлинного ACK. Production-сборки и Apple App Store Connect не изменяются.

## Проверки и ограничения

- На Mac mini/Xcode 27.1 Watch QA target собран через `generic/platform=watchOS` (**BUILD SUCCEEDED**), поскольку физический Watch destination временно не доступен.
- Unit test `testLostACKRealisticAACResendPreservesSameUUIDAndDeletesOnlyAfterACK`: создаёт настоящий воспроизводимый AAC через `MicrophoneCapturePipeline`, проверяет `WatchDeliveredAudioValidation`, индекс `WatchDurableQueue`, два подряд импорта одного UUID в iPhone `RecordingRepository`, одинаковые файлы/одну заметку, удаление исходника **только после** `WatchAcknowledgementJournal.acknowledge`. Детерминированная проверка логики, а не физическая передача через WCSession.
- **Физическая проверка не проведена**: первоначально `devicectl list devices` показывал `iPhone Nikita unavailable`, а watchOS destination не находился. Оба устройства затем восстановили связь и физическая Watch QA сборка заново успешно собрана. В 09:09 МСК на Watch получено `queue.json=[]`; исходный проблемный 0,124-секундный AAC сохранён. Запуск iPhone QA-приёмника затем был отклонён системой с `FBSOpenApplicationServiceErrorDomain: Locked (Unable to launch ... because the device was not, or could not be, unlocked)`. Не утверждать PASS реальной повторной доставки и **не начинать новый capture до разблокировки телефона**. Ни один новый AAC не создавался.

## Как провести физическую проверку после возврата пары

1. Подтвердить `devicectl list devices` с доступными iPhone 13 и Apple Watch SE, ранее установленные отдельные QA bundle IDs. Не переустанавливать production и не удалять Watch очередь.
2. Открыть на iPhone `ru.arvectum.tools.what.watchphysqa` для активации WCSession. Затем установить обновлённый QA Watch target, запустить `what-watch-qa-drop-ack`. Пробник начнёт одну ~7-секундную запись.
3. Прочитать *только* `WatchPhysicalQA/status.json` и `Documents/WhatOutbound/queue.json`. На этапе `ack-dropped` ожидаются `pending=1`, оригинал на Watch; после `duplicate-in-flight` и `ack-observed` ожидается пустая очередь. Из iPhone QA `recordings.json` требуется ровно одна запись с тем же UUID, не две.
4. После завершения без параметра записи безопасно перезапустить только QA-приложения и ещё раз проверить индекс/очередь. Не передавать сырое аудио на Mac и не удалять оставшийся 0,124-секундный QA-фрагмент с предыдущих тестов.
