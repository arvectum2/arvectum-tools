# Ухват: реальный Watch → iPhone cold-background WCSession, 22.10.2026

## Аппаратура, безопасность, тестовый режим
- iPhone 13 iOS 27.0.1, Apple Watch SE watchOS 26.6, Xcode 27.1, Mac mini.
- Только отдельные подписанные QA бандлы ru.arvectum.tools.what.watchphysqa (iPhone) и ru.arvectum.tools.what.watchphysqa.watch (Watch), без установки поверх публичного Ухвата и без личных записей.
- Новый Watch QA-only режим запуска what-watch-qa-synthetic-background создаёт декодируемый AAC длительностью 3,84 с на часах из PCM, без микрофона и камеры; штатно добавляет его в WatchDurableQueue. На 10 с удерживает только QA transport (радио, системное сопряжение и WCSession не отключаются), затем запускает обычный pumpTransfers, background transferFile и ждёт настоящий ACK. Исходные M4A никогда не копируются на Mac.
- QA-only обработчик параметра запуска теперь вызывается и из WhatWatchApp.init, чтобы не зависеть от физического появления CaptureView. Production без WATCH_PHYSICAL_QA эти ветки не компилирует.
- Подписанная отдельная пара QA приложений собрана (BUILD SUCCEEDED), codesign --verify успешен и обе QA установки подтверждены devicectl.

## Базовая точка
- Реальный Watch audit: pending=0, изолированная очередь пуста; Phone QA library ещё без индекса.
- iPhone QA стартовал один раз, чтобы активировать WCSession. Далее процесс PID 45813 остановлен, отдельно подтверждено QA_PHONE_NOT_RUNNING до запуска Watch.

## Прогон 1: настоящий холодный фоновый приём — PASS
- Watch AAC UUID F76FDCAE-FAB0-4534-ABBD-E8BFDE5C481E, длительность 3,84 с.
- Watch timeline: synthetic-background-start; synthetic-watch-queued; synthetic-queue-preserved. Исходник гарантированно был на часах после 10-секундного QA удержания транспорта.
- Watch status: ack-observed, pending=0, original absent. Watch queue.json = [] (2 байта).
- iPhone QA recordings.json без ручного открытия содержит ровно один новый UUID с тем же значением и длительностью 3.84. После доставки автоматически появился QA iPhone процесс с новым PID 45822, хотя прежний был завершён.
- Результат: доказана одна сквозная передача через настоящий WCSession в первоначально незапущенный iPhone QA приёмник и подлинный ACK Watch.

## Прогон 2: фоновая доставка задержалась — НЕ второй background PASS
- Процесс iPhone QA PID 45822 остановлен; отсутствие процесса подтверждено.
- Новый Watch AAC UUID 1BC5A744-8943-4E05-ADAF-05CA9DAEFABD, duration 3.84.
- Watch status: synthetic-queued-10s, pending=1. iPhone index содержал лишь UUID первого прогона. После перезапуска только QA Watch без новой записи queue.json всё ещё содержал тот же старый UUID: оригинал не пропал.
- За время наблюдения второй фоновый приём не завершился. После явного открытия ТОЛЬКО QA iPhone приложения его index увеличился до двух разных UUID с duration 3.84 у каждого, без повторов.
- После этого диагностический Bluetooth-туннель CoreDevice к часам снова стал тайм-аутиться. Финальную очистку Watch очереди после второго ACK НЕ подтверждали; никаких исходников не удаляли вручную.

## Итог, оставшиеся проверки
- Подтверждён один реальный cold-background PASS и сохранность очереди в повторном delayed сценарии. Нельзя обещать немедленную фоновую доставку при каждом запуске: второй прогоны дошёл до iPhone только в foreground.
- Реальный радиовыключатель, перезагрузка Watch/iPhone и before-first-unlock, фоновая доставка в повторных случаях, аппаратный ENOSPC, VoiceOver rotor и полное резервное восстановление остаются OPEN.
- Диагностика включает лишь JSON UUID/статус и Xcode логи в ArvectumSSD/Arvectum/tmp/what-watch-background-20261022. Никаких пользовательских медиа на Mac не копировали.
