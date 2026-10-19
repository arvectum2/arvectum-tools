# Ухват · iPad максимальный Dynamic Type, 19.10.2026

На отдельном симуляторе `Arvectum-T5-iPad-20261018`, Xcode 27.1, iPadOS 27.0, до теста установлен `xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large`. Тест из `WhatIOSUITests/AdaptiveLayoutUITests.swift` запускает тот же iOS target с поддержкой iPad `TARGETED_DEVICE_FAMILY=1,2`.

Проверки: большая кнопка записи доступна; отдельная кнопка «+» доступна и нажимаема; пустой текстовый редактор открывается и закрывается без создания заметки; библиотека открывается, кнопка фильтра `what.filter.all` доступна; возврат на быстрый захват работает. **1 UI PASS, 0 failures**. До этого обычный iPad rotation/navigation UI тест также **1 PASS** в данном source.

Первая версия теста проверяла весь SwiftUI `ScrollView` как `XCUIElementType.other` и дала **ошибку идентификации элемента XCTest**, а не установленный дефект интерфейса. Итоговая версия проверяет конкретную кнопку `what.filter.all` и проходит.

После повторного теста системный размер текста отдельного iPad-симулятора восстановлен до исходного `large`. Реальные VoiceOver, Split View/Stage Manager, поведение физического iPad и аппаратные разрешения Camera/Mic не проверены; эти ворота остаются открытыми. Production IPA/App Store и данные личного iPhone не изменялись.

Лог: `/Volumes/ArvectumSSD/Arvectum/tmp/what-ipad-large-type-ui-v2-20261019.log`, результат: `what-ipad-large-type-ui-v2-20261019.xcresult` (оба на ArvectumSSD).
