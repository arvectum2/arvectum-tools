# Ухват: физическая трассировка задержанной доставки WatchConnectivity — 22.10.2026

## Цель и изоляция

Проверялся ещё не закрытый в матрице приёмки вопрос: каким каналом Watch → iPhone передаётся AAC и на какой стадии возникает задержка без открытого UI на iPhone. Прежние offline-батчи, потерю ACK и тесты с искусственной 10-секундной паузой не повторяли.

Физические устройства: Apple Watch SE (watchOS 26.6), iPhone 13 (iOS 27.0.1), Xcode 27.1 на Mac mini. Установлены исключительно подписанные QA-приложения ru.arvectum.tools.what.watchphysqa и ru.arvectum.tools.what.watchphysqa.watch; пользовательские приложения, записи, сопряжение и Bluetooth/Wi-Fi не затронуты.

Добавлен QA-only флаг WATCH_ROUTE_QA и файл Shared/WatchRouteQATrace.swift. Журнал Documents/WatchRouteQA/events.json содержит только время, uptime, event kind, UUID и короткое описание статуса, не аудио, payload, транскрипцию или другую пользовательскую информацию. Размер журнала ограничен 350 событиями. Обычные production target эти инструкции не исполняют: все вызовы находятся под условием компиляции QA.

Новый явный QA режим what-watch-qa-route-immediate создаёт короткий синтетический декодируемый AAC из PCM прямо на часах, без микрофона и без дополнительной задержки передачи; используется настоящая постоянная Watch очередь и штатный WCSession.

## Один инструментированный аппаратный прогон

UUID: FC72ADC2-1C5C-42C7-B1C9-C0900284C2A9.

| Источник | Unix seconds | Событие |
|---|---:|---|
| iPhone | 1792677909.225 | phone-session-activation, activated |
| iPhone | 1792677910.641 | phone-phase background |
| Watch | 1792677917.991 | watch-session-activation, activated |
| Watch | 1792677918.170 | watch-queue-committed |
| Watch | 1792677918.178 | watch-file-scheduled, reachable=false, outstanding=false |
| Watch | 1792677918.506 | watch-file-transfer-completion success |
| iPhone | 1792678089.361 | phone-phase inactive, возврат из background |
| iPhone | 1792678089.389 | phone-file-received, тот же UUID |
| iPhone | 1792678089.459 | phone-file-committed |
| iPhone | 1792678089.464 | phone-file-ack-queued |
| Watch | 1792678089.773 | watch-userinfo-ack-received |
| Watch | 1792678089.789 | watch-ack-index-committed |
| iPhone | 1792678089.816 | phone-phase active |

## Подтверждённый результат

- Watch видел isReachable=false, поэтому не пытался вызвать быстрый sendMessageData. Он поставил AAC в фоновую очередь WCSession.transferFile. Это записано в новом журнале Watch, а не предположено по исходникам.
- От вызова transferFile до успешного didFinish fileTransfer на Watch прошло **0,328 секунды**. Важно: успех этого callback не является доказательством того, что iPhone уже выполнил didReceive и сохранил файл.
- Следующее наблюдаемое событие приёмника — iPhone didReceive(file:) через **170,883 секунды после watch-side completion**. Это произошло через 0,028 секунды после перехода iPhone scenePhase в inactive при возврате из background, за 0,427 секунды до scenePhase active.
- iPhone сохранил аудио за 0,070 секунды, отправил ACK за следующие 0,005 секунды; Watch получил его за 0,384 секунды от момента iPhone didReceive.
- Фоновой вызов PhoneConnectivityManager.requestWatchQueueRecovery на событии scenePhase active НЕ инициировал исходный didReceive: callback пришёл до active.
- Индекс iPhone QA вырос с 3 до **4 уникальных UUID**. На Watch после ACK queue.json = [], и не обнаружено новой дублирующей заметки. Исходное аудио не экспортировалось на Mac.
- Задержка в этом опыте лежит **между watch-side didFinish transferFile(success) и запуском обработчика didReceive(file:) на iPhone**, при этом фактический callback начался при возврате приложения из фона. Часы и телефон журналируют собственные системные часы, их абсолютная синхронизация отдельно не калибровалась: межустройственные интервалы приблизительные; более надёжный факт — iPhone обработал файл спустя 0,028 с после собственного события выхода из background. По одному прогону нельзя утверждать ни дефект ОС, ни гарантированный SLA фоновой доставки.

## Диагностика и оставшиеся вопросы

QA JSON и логи сборок расположены только на Mac mini: /Volumes/ArvectumSSD/Arvectum/tmp/what-watch-route-trace-20261022. Главные файлы: watch-events-after-control.json, phone-events-after-control.json, phone-index-background.json, phone-index-after-control.json, watch-queue-after-control.json.

Дальнейшая предметная задача — проверить системные условия, при которых iOS запускает didReceive в фоне без ручного возврата UI, и возможное влияние режима энергосбережения/фоновой политики. Не повторять basic ACK/offline-батч. Не выключать реальные Bluetooth/Wi-Fi, не перезапускать личные устройства и не заполнять их память ради новых тестов без безопасной отдельной процедуры.

## Сборки и ограничения подписывания

- Отдельная подписанная QA-сборка iPhone + Watch: WhatWatchPhysicalQA.xcodeproj, обе установки и реальная передача PASS.
- Производственная iOS + watchOS конфигурация What.xcodeproj с CODE_SIGNING_ALLOWED=NO: **BUILD SUCCEEDED**, включая WhatWatch и extension targets; production-compile-nosign-retry.log.
- В другом контрольном прогоне с подписыванием код полностью собрался, но codesign упал на расширении WhatPhoneWidget с errSecInternalComponent. Это локальная проблема keychain/signing на Mac mini; **подписанную production-сборку в этом проходе не подтвердили**. Пользовательские ключи, profiles и настройки подписи не меняли, выпуск не делали.
- Генерируемый XcodeGen файл what/ios/What.xcodeproj/project.pbxproj после проверки возвращён к состоянию main, не входит в коммит. Трассировка доступна только через QA spec project.watch-physical-qa.yml.
