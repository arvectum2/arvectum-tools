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

## Что не закрыто

- [ ] Физическая запись аудио/видео требует отдельного разрешения камеры/микрофона и тестов по заранее выбранному безопасному сценарию, без записи окружения пользователя без согласия.
- [ ] Проверка на реальной Apple Watch (Watch queue/ACK/reconnect) только в отдельной паре с непроизводственной сборкой, без сброса личных заметок.
- [ ] Cross-app handoff с ChickMark на отдельном QA контуре, корректные return URL/deeplink, разрешения уведомлений.
- [ ] Стресс 90 секунд/длинные видео, фон, переустановка, восстановление очереди и публичный App Store билд.

Публикация в App Store не выполнялась. Growth и Where? остаются на паузе.
