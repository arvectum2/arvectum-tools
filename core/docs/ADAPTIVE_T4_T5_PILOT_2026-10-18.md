# T4/T5 — адаптивный Core, Ухват и Фото/PDF (18.10.2026)

**База:** origin/main 66d6f07, feature/core-ipad-duo-pilots-20261018. **Статус:** проверенный локальный пилот, НЕ в main и НЕ опубликован. Growth, Where?, пользовательские данные и отправленные Apple билды не затронуты.

## Выполнено

- Shared ArvectumAdaptiveLayout: метрики ширины, ограничение читаемой колонки, AnyLayout-компоновка с условным вторым столбцом. Исправлены SwiftUI test warnings раннего прототипа.
- Ухват: импорт ArvectumCore только в iOS target, адаптивная библиотека/редактор и capture-first на узком экране; iPad family включена только в пилоте. **Мультимодальная 1.1.0 находится в отдельной ветке и не включена в этот QA.**
- Фото/PDF: responsive два столбца «задача + исходный предпросмотр» при ширине около 616pt, без второго столбца в компактном режиме; добавлены iPad AppIcon 152/167 из существующей иконки. Работа модели, файлов, импорта и рекламы не менялась.

## Проверено: Xcode 27.1 / Swift 6.4

| Проверка | Результат |
| --- | --- |
| Core tests | **13/13 PASS** |
| Architecture, dependency catalog, lockfiles | **PASS** |
| What / Photo Debug iOS Simulator builds | **оба PASS** |
| WhatIOSTests (iPad) | **61 тест, 0 failures, 3 skipped** |
| PhotoPodRazmerTests (Duo) | **31/31 PASS** |
| What UI — iPad и Duo | **2/2 PASS** |
| Photo/PDF UI — iPad и Duo | **2/2 PASS** |

**Изоляция:** новые Arvectum-T4-Duo-20261018 (iOS 27.1; UUID 5B0D50EA-50BB-4F0E-B577-4970EFFCF286) и Arvectum-T5-iPad-20261018 (iPad Air M3, iOS 27.0; UUID 3484211E-7501-4BF0-9F19-BC933521F024). На iOS 27.1 выбранный iPad M4 оказался несовместим с runtime, поэтому использован iOS 27.0.

**T4:** simctl io перечислил LCD 1398x2034 и LCD-1 2007x2853; сняты скриншоты. На запущенном Фото/PDF выполнен power off/on внутреннего экрана с восстановлением и повторным запуском. Dynamic Type переключён в accessibility-medium и возвращён в large. Артефакты находятся на ArvectumSSD/Arvectum/tmp, не коммитятся в Git.

**Ограничение:** power off/on отдельного виртуального дисплея **не равен реальному hinge fold/unfold** и не подтверждает сохранность ввода/видео/активного экспорта. UI-тесты проверяют ориентацию и доступность элементов, но не воспроизводят физическое складывание.

## Гейты перед объединением с main

1. Реальный Duo fold/unfold со state continuity, сценами и активными операциями; iPad Split View/Stage Manager и VoiceOver.
2. Ухват: перенести пилот в актуальные мультимодальные исходники 1.1.0 и проверить текст/видео/камеру/микрофон/Watch ACK, восстановление и данные.
3. Фото/PDF: физический Files/Photos import/export, PDF, реальные consent/ATT/ads, недеструктивный upgrade и крупный Dynamic Type.
4. Независимая release acceptance продуктов. Включённая в ветке target-family iPad 1,2 не означает публичную поддержку устройств.

**Решение:** предоставить пилот в draft PR и не вливать в main, пока эти ворота не закрыты.
