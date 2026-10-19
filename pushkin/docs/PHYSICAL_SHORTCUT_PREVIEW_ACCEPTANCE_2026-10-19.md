# PUSHKIN — физическое открытие signed 1000-app Shortcut, iPhone 13 (19.10.2026)

## Изоляция

- iPhone 13, iOS 27.0.1, Mac mini / Xcode 27.1.
- Исходники исправляющего кандидата 1.0.1(4) на ветке [PR #126](https://github.com/arvectum2/arvectum-tools/pull/126).
- Сборка отдельного `ru.arvectum.tools.notify.physicalqa`, **не публичное приложение**; её SwiftData контейнер изолирован.
- В `PushkinPhysicalQAUITests/ShortcutPreviewSafetyUITests.swift` отсутствуют действия по установке, замене, включению или удалению каких-либо существующих автоматизаций Apple Shortcuts.

## Результаты

1. Signed QA `build-for-testing` на реальном iPhone: **TEST BUILD SUCCEEDED**.
2. 17 unit (включая поиск ресурсов 1001 signed .shortcut и удаление) + 3 безопасных UI теста с синтетической историей: **20/20 PASS**, 0 failed, 0 skipped. XCResult: `/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-physical-rc4-20261019/Pushkin-physical-RC4-GUI.xcresult`.
3. Дополнительный строго ограниченный native handoff test: открыть пункт **Open base shortcut in Shortcuts** в QA app; убедиться, что Apple Shortcuts запускается и показывает нативную предпросмотрную кнопку **Add Shortcut / Добавить**; **не нажимать** Add, Replace, Automation Enable; вернуть на передний план QA приложение. На реальном iPhone: **1/1 PASS**, 0 failed, 0 skipped. XCResult: `.../Pushkin-ShortcutsPreview-Physical.xcresult`.

Таким образом, физическое открытие **нативного preview подписанного базового пакета** доказано. Это не означает, что 1000 приложений реально настроены/доставляют уведомления: экосистема Shortcuts остаётся под управлением пользователя.

## Открыто

- [x] QA native preview подписанного базового пакета; возврат без импорта
- [x] Физические QA unit / search / delete / clear тестовых уведомлений
- [ ] Включение новой тестовой автоматизации и доставка **настоящего уведомления**, без вмешательства в имеющиеся личные Shortcut automation — отдельная процедура с безопасным созданием и удалением тестового сценария
- [ ] Проверка **обновления установленной публичной сборки** без удаления пользовательской истории (здесь проверялся лишь независимый QA-контейнер)
- [ ] Отдельное решение о загрузке подписанной IPA в ASC и App Review после завершения gate

Оригинальная signed 1.0.1(4) IPA и её source SHA 5876711 не пересобирались и не изменялись этим UI-тестом.
