# Ухват 1.1 — физический iPhone QA · 18 октября 2026

## Изоляция и состав

- Mac mini Xcode 27.1, физический iPhone 13 на iOS 27.0.1, физическая USB-пара; iOS UI Automation разрешена.
- Сборка из стабильной main (после адаптивного PR #90). Отдельный XcodeGen конфиг what/ios/project.physical-qa.yml, целевое приложение WhatMultimodalPhysicalQA.
- Bundle: ru.arvectum.tools.what.multimodalqa; версия кода 1.1.0(8), локализованное имя «Ухват 1.1 QA» / «UhWhat 1.1 QA». Apple Development signature PASS. Уникальный приватный контейнер, без Watch/Widget extensions, App Groups, iCloud, HealthKit и иных пользовательских контейнеров. Существующие UhWhat QA, ChickMark, Pushkin и личные заметки пользователя не изменялись.
- DEBUG REVIEW_HANDOFF_QA отключает связь с настоящей Apple Watch в QA-контуре. Переходы на пользовательские URL-схемы, cross-app handoff, физические камера/микрофон и синхронизация с Watch **не испытывались** в этом прогоне.
- В QA-приложении созданы только текстовые заметки со синтетическим содержимым (UI markers); они сохраняются исключительно в собственном QA-контейнере.

## На физическом iPhone

| Проверка | Итог |
| --- | --- |
| Сборка/подпись ARM64, установка уникальной QA-версии | BUILD SUCCEEDED / PASS |
| Навигация запись ↔ библиотека | PASS |
| Видимость управления после смены ориентации | PASS |
| Создание текстовой заметки через плюс и сохранение в библиотеке | PASS |
| Фильтры библиотеки текст/аудио/видео не удаляют заметку | PASS |
| Меню отложенного напоминания открывается без запроса уведомлений | PASS |
| Итого применимые UI-тесты | **5/5 PASS**, 0 ошибок |
| Применимые iOS-модульные тесты | **102 выполнены, 3 skip, 0 failures** |

**Прозрачность unit-отбора:** полный QA unit прогон включил 104 теста, 3 skip, 5 failed assertion из двух производственных тест-кейсов:
- ReviewNoteHandoffTests.testPrivateTranscriptNeverAppearsInURLAndPayloadRoundTrips требует публичную URL-схему, а REVIEW_HANDOFF_QA меняет её на тестовую.
- WatchPackagingIsolationTests.testEmbeddedWatchAndComplicationUseProductionIdentity требует публичный bundle ID и Watch/Widget внутри production IPA, которые в изолированном QA пакете намеренно отсутствуют.

Это несовместимость production release-gates с уникальными QA идентификаторами, а не подтверждённый дефект приложения. Оба этих тест-кейса явно исключены при повторном физическом QA прогоне. **Повтор: 102/102 выполненных, 3 ожидаемых skip, ошибок 0, TEST SUCCEEDED.** Production release-gates остаются в основном CI, не считаются проверенными QA вариантом.

## Локальные доказательства на ArvectumSSD

- what-1-1-physical-build-20261018.log
- what-1-1-physical-ui-20261018.log + xcresult
- what-1-1-physical-units-20261018.log + xcresult (исходный production identity mismatch)
- what-1-1-physical-applicable-units-20261018.log + xcresult (применимый unit набор)
- what-physical-qa-localized-build-20261018.log (верификация EN/RU системного названия)

## Дополнение: реальные аудио и видео на iPhone 13 — 18.10.2026

После предыдущего тестирования текстовых заметок и после отдельного согласия пользователя проверены физические микрофон и камеры в том же QA-приложении с собственным контейнером:

| Физический сценарий | Результат |
| --- | --- |
| Одно короткое нажатие запускает аудио; запись длится примерно 3 секунды; Stop and save закрывает рекордер | PASS, 1/1 UI на физическом iPhone |
| Длинное нажатие запускает видео; 2 секунды, смена камеры, ещё 2 секунды; MOV сохраняется и рекордер закрывается | PASS, 1/1 UI на физическом iPhone |
| Воспроизведение сохранённого MOV после нового запуска | **PASS: 1/1 физический XCTest после переподключения iPhone**, открытие локального плеера и возврат к библиотеке |
| Последующее подключение iPhone к Xcode | БЛОКЕР: CoreDevice перешёл в unavailable, macOS больше не видит iPhone через USB |

Первый запуск теста аудио остановился до assertions на тайм-ауте XCTest UI Automation. После удаления только disposable QA Runner повторный тест прошёл. Видео прошло с первой успешной UI-сессией. Первый playback-тест нельзя считать успешным из-за потери CoreDevice, однако после переподключения физический повтор **PASSED** (11.400 с).

Частные логи и xcresult на ArvectumSSD (не коммитить медиа):
- what-physical-real-audio-20261018.log — XCTest Runner timeout
- what-physical-real-audio-retry-20261018.log и xcresult — PASS
- what-physical-real-video-20261018.log и xcresult — PASS
- what-physical-video-playback-20261018.log и xcresult — первоначальная ошибка CoreDevice
- what-physical-video-playback-after-reconnect-20261018.log и xcresult — физический playback **1/1 PASS**

Файлы аудио/MOV не выгружались с телефона, остались только в собственном QA-контейнере. Существующие пользовательские заметки, основная версия Ухвата и Watch не изменялись.

## Что не закрыто

- [x] Короткие физические сценарии записи аудио и видео с переключением камеры прошли в QA-контейнере после разрешения пользователя. Файлы не экспортировались.
- [ ] Проверка на реальной Apple Watch (Watch queue/ACK/reconnect) только в отдельной паре с непроизводственной сборкой, без сброса личных заметок.
- [ ] Cross-app handoff с ChickMark на отдельном QA контуре, корректные return URL/deeplink, разрешения уведомлений.
- [x] Воспроизведение MOV после повторного открытия библиотеки: физический iPhone, 1/1 PASS после восстановления USB.
- [ ] Стресс 90 секунд/длинные видео, фон, восстановление очереди, физические Watch ACK и публичный App Store билд — пока открыты.

Публикация в App Store не выполнялась. Growth и Where? остаются на паузе.

## Дополнение: физические 90-секундное видео и отмена, 18.10.2026

- Отдельное UhWhat 1.1 QA (ru.arvectum.tools.what.multimodalqa), iPhone 13 iOS 27.0.1. Видео и аудио оставались в локальном QA-контейнере, без отправки на Mac или GitHub.
- testNinetySecondContinuousPhysicalVideoSaves: 1/1 PASS, 102.699 с общего времени теста. 90 секунд камера работала непрерывно, Stop and save оставалась доступна, ролик сохранился, экран записи закрылся, основная кнопка Home снова была доступна.
- testDiscardPhysicalVideoDoesNotSave: 1/1 PASS, 18.041 с. Короткая запись отменена, возврат на Home без зависания. Это проверка UX-отмены, а не независимый файловый аудит всех временных сегментов.
- Приватные логи на ArvectumSSD/Arvectum/tmp/what-physical-90s-video-20261018.log + xcresult, what-physical-discard-video-20261018.log + xcresult.
- Не трогали личные заметки, Watch-сопряжение, production-сборку и App Store Connect.
- OPEN: аварийное завершение во время смены камеры с безопасным аудитом только журнала, длительная запись несколько часов / нехватка места, Watch ACK и реальный релизный бинарник.
