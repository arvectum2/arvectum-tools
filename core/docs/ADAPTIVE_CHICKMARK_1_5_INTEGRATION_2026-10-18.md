# ChickMark 1.5.0 (18) + Core AdaptiveLayout — интеграционный QA

**Дата:** 18.10.2026. **Ветка:** feature/chickmark-15-adaptive-20261018, база feature/core-ipad-duo-pilots-20261018 (5ab9c35).

## Причина интеграции

В исходном адаптивном PR #90 (ChickMark 1.4.1, build 15) отсутствовали новые обработчики, контракты и проверки отправленного Apple кандидата ChickMark 1.5.0 (build 18). Выпуск из такой базы мог бы регрессировать интеграцию заметок из Ухвата, восстановление текста и взаимодействие с уведомлениями.

## Реализовано

- Перенесены изменения релизной ветки release/what-chickmark-20261018-rc1 для ChickMark: OneOff-обработчики, локальные вложения, восстановление полных текстов через backup, защищённые URL/nonce, навигация из уведомления, планировщик, регрессии и RU/EN/ES.
- Сохранены все адаптивные изменения: TARGETED_DEVICE_FAMILY=1,2, iPad-only повороты, iPhone portrait-only, центрированный Today вместе с sticky native ad, детальный экран привычки, иконки iPad.
- Версии 1.5.0 (18) во всех четырех targets (Phone, Watch, Watch Widget и Phone Widget) совпадают с отправленным кандидатом **только для компиляционного сравнения**. Это НЕ новый билд для Apple: следующее обновление должно получить новый номер build больше 18 и отдельный review. Отправленная IPA не изменялась.
- Core/ArvectumInterapp/ReviewNoteHandoff.swift остаётся прямым исходником приложений; путь исключён из SwiftPM Core, чтобы не создавать предупреждения и дубли типов.
- Не переносились из релизной ветки отдельные ReviewQA project и его гигантский сгенерированный Info.plist. Они доступны в исходной релизной ветке.

## Проверки Mac mini

Xcode 27.1 / Swift 6.4, 18.10.2026. Отдельная QA-ветка, симуляторы и бинарные отчёты только на ArvectumSSD.

| Проверка | Результат |
| --- | --- |
| Core Swift tests | **13/13 PASS**, unhandled warning устранён |
| Architecture / lockfile / shared catalogs | **PASS** |
| XcodeGen, ChickMark 1.5.0 Debug Simulator build | **PASS** |
| ChickMark full unit на iPad | **245/245 PASS** |
| ChickMark iPad UI (адаптация и create/check/history) | **2/2 PASS** |
| iPhone 17 Pro UI smoke | **1/1 PASS** |
| iPhone Duo UI smoke | **1/1 PASS** |

Изоляция: XCTest --ui-testing использует in-memory SwiftData и отключает CloudKit. Пользовательские привычки, HealthKit, действующие Apple Review binaries и Watch-данные не менялись.

## Незакрытые ворота

1. Дополнительный QA на обычном iPhone + Duo и полный Github CI для новой ветки. Физический Duo не требуется по решению владельца, но настоящий hinge не проверен.
2. Перед выпуском выбрать новый номер сборки: НЕ переиспользовать build 18. Проверить Apple Review исходного кандидата 1.5.0.
3. Privacy/Shortcuts/Watch/CloudKit/HealthKit product-release QA независимо от этих симуляторных тестов.
4. Интегрировать после основной ветки PR #90 без смешивания с уже отправленной Apple 1.5.0.

**Source of truth:** исходная release-ветка 1.5.0 осталась нетронутой. Эта ветка — будущий исходный код, а не автоматическая публикация.
