# T4/T5 — адаптивный Core в мультимодальном Ухвате 1.1.0 (18.10.2026)

**Source:** feature/what-multimodal-adaptive-20261018 (основана на пилоте feature/core-ipad-duo-pilots-20261018); актуальные аудио/видео/текст/напоминания/Watch/ChickMark взяты из release/what-chickmark-20261018-rc1, не изменяя отправленную Apple сборку.

## Сделано

- Локальный ArvectumCore подключён к iOS-приложению Ухват 1.1.0; два редактора (текстовая заметка с автосохранением и расшифровка с явным сохранением) теперь ограничены общей ArvectumReadableColumn; фон capture-first зависит от ширины окна.
- Существующая поддержка iPad мультимодального release-кандидата сохранена, без повторного переписывания видеокамеры и UIKit/SwiftUI scene lifecycle.
- Новая UI-регрессия для навигации запись/библиотека/текст при portrait/landscape; существующие iPad и video long-press тесты применены к комбинированной сборке.
- Не делались изменения Growth, пользовательских данных, реального iPhone, Apple review или публикации.

## Фактические проверки Mac mini / Xcode 27.1

| Ворота | Результат |
| --- | --- |
| ArvectumCore Swift tests | **13/13 PASS** |
| Architecture / dependency checks | **PASS** |
| xcodegen и What 1.1.0 Simulator Debug build | **PASS** |
| WhatIOSTests на изолированном iPad Air M3 (iOS 27.0) | **104 executed; 3 skipped; 0 failures** |
| UI на iPad: responsive, iPad landscape/rotation, сохранение текста, видеожест | **5/5 PASS** |
| UI на iPhone Duo (iOS 27.1): навигация/текст | **4 executed; 2 skipped; 0 failures** |

Результаты XCResult и логи: ArvectumSSD/Arvectum/tmp/adaptive-multimodal-{ipad,duo}-20261018.

## Решение владельца — физический Duo не обязателен

Физического iPhone Duo нет. Принимаем симуляторные проверки как доступную QA-базу, а реальные несовместимости после релиза исправляем по обратной связи. Это **не доказывает** настоящий hinge fold/unfold или сохранность активной видеозаписи при смене дисплея; такие проверки честно обозначаем неподтверждёнными, но они **не блокируют** техническое продвижение или решение о будущем выпуске.

## Незакрытые независимые ворота

- Проверить Camera/Mic/Watch на физическом обычном iPhone и сохранность старых данных там, где возможно; дополнить iPad Split View/Stage Manager и крайний Dynamic Type.
- Проверить полноценный PDF/Files import/export и ATT/ads второго пилота Фото/PDF; уже прошедшие 31 unit и 2 UI по Фото/PDF сохраняются.
- Выполнить source-version mapping, подписание и согласование release после завершения CI; это **не** означает автоматическую отправку обновления в Apple.

**Состояние:** code + simulator QA ready; не выдавать данный QA за новый App Store релиз.
