# Ухват · Watch ACK race / orphan audio regression · 18.10.2026

## Цель и границы

Проверить гонку между двумя каналами ACK (live message и `transferUserInfo`), асинхронным `WCSession.didFinish`, атомарной перезаписью Watch `queue.json` и физической очисткой исходного `.m4a`. Выполнено на Xcode 27.1 (iOS 27.0 Simulator), без использования личных данных и подключения физического Watch. Сборка, отправленная на App Review, не менялась.

## Код

- `Shared/WatchAcknowledgementJournal.swift`: короткоживущий атомарный маркер `WhatOutbound/Acknowledged/<UUID>.ack` пишется **после фактического подтверждения приёмником** и **до** удаления записи из очереди. После успешной атомарной записи `queue.json` удаляется исходный `.m4a`, а маркер удаляется последним. Уникальный UUID и канонический путь не принимаются из непроверенного произвольного имени файла.
- При прерывании после маркера, но до queue commit: Watch сохраняет оригинал, при следующем доступном диске завершает ACK и удаляет его. При прерывании после queue commit, но до удаления файла: orphan scanning игнорирует UUID из ACK-маркеров; после рестарта выполняется безопасная очистка. Дубликат ACK для отсутствующей записи ничего не удаляет.
- `WhatWatch/WatchCaptureController.swift`: ACK recovery выполняется перед поиском неиндексированных записей; восстановление при недоступном на locked boot `queue.json` отложено до unlock, чтобы избежать записи поверх недоступного индекса. Поздний `didFinish` после ACK не изменяет retry/backoff удалённого UUID.

## Проверки

- `testImmediateAndBackgroundACKOrderLeavesExactlyOnePendingNote`: последовательность live/background ACK для одного UUID при другой ожидающей заметке; второй источник и индекс остаются неизменными.
- `testCrashAfterACKQueueCommitBeforeAudioDeletionNeverResurrectsOrphan`: внедрённая ошибка удаления сохраняет оригинал/маркер, Watch orphan recovery не поднимает этот UUID, следующая загрузка очищает оригинал и маркер.
- `testACKIndexWriteFailurePreservesOriginalAndReconcilesAfterUnlock`: блокировка индекса после успешного ACK-маркера не позволяет удалить исходник и изменить очередь; после восстановления доступа безопасная очистка завершает операцию.
- Ранее существующие unit-кейсы офлайн-пакета, повреждённого AAC, дубликатов и недоступного индекса повторены.
- Фактически: `WatchA2ReliabilityTests` — **12 executed / 0 failures**; `WhatIOSTests` — **110 executed / 3 expected skips / 0 failures**, `TEST SUCCEEDED`.
- Локальные доказательства: `/Volumes/ArvectumSSD/Arvectum/tmp/what-ack-races-focus-20261018.{log,xcresult}` и `what-ack-races-full-units-20261018.{log,xcresult}`; в репозиторий исходные файлы AAC, бинарные записи и `.xcresult` не включаются.

## Честные ограничения

Это программные симуляции с реальными файловыми операциями в тестовом контейнере. Реальный радиоразрыв, тайминг `WCSession` во время сна, загрузка зашифрованного Watch file protection до unlock и стабильность в многодневном фоне физически не доказаны. Следующий physical QA — отдельное разрешённое тестовое устройство, без удаления пользовательских записей или перепривязки часов. Никаких утверждений о выпуске новых App Store бинарников.
