# Pushkin — безопасное удаление уведомлений, A1 (2026-10-15)

## Симптом и анализ

Пользователь сообщил о вылете при удалении уведомления 2026-10-04. Исходная реализация передавала живой SwiftData `@Model CapturedNotification` в `NavigationLink`, строки истории и `NotificationDetailView`, после чего вызывала `modelContext.delete(item)`, оставляя SwiftUI-дерево и обработчики с потенциально уже инвалидированным объектом. Это **вероятный источник** вылета, но оригинальный физический stacktrace ещё не предоставлен; факт точного воспроизведения исходного краша **не заявляется**.

## Исправление (source-level)

- Значения `NotificationHistoryItem` копируются из @Query модели для списка, поиска, строки, копирования, обмена и detail.
- `NotificationDetailView` владеет только независимым снимком; удержание `@Model` после удаления исключено. Удаляем запись по стабильному UUID, с idempotent обработкой повторного вызова.
- `NotificationHistoryDeletion` вызывает fetch по идентификатору, delete и синхронный save; ошибка больше не замалчивается, показывается alert.
- `deleteAll` использует явное удаление записей из fetch (без SwiftData batch delete), а не случайное изменение схемы. Удаление истории не затрагивает Shortcuts, настройки охвата, разрешения или схему хранения.
- Никакой сброс, очистка или переустановка пользовательского приложения на iPhone не выполнялись; для UI создан отдельный пустой симулятор.

## Проверка

- [x] Xcode 27, isolated `Pushkin-Delete-A1-20261015`, iPhone 17 / iOS 27.
- [x] `NotificationHistoryDeletionTests`: 3/3; удалить одну запись, сохранить другую и проверить через новый ModelContext; повторный/stale UUID no-op; удалить всё и снова сохранить запись.
- [x] `NotificationDeletionUITests`: 3/3; удалить из карточки и вернуться в историю, удалить свайпом и сохранить другую запись; удалить всю историю из настроек и остаться в работающем приложении.
- [x] Локальный полный selective xcodebuild run: **TEST SUCCEEDED**, 6/6, ноль ошибок, исходные тестовые данные disposable.
- [x] GitHub [PR #68](https://github.com/arvectum2/arvectum-tools/pull/68) merged at `6a6c206`; both push and PR CI runs passed build-for-testing and the new delete-regression job (3 unit + 3 UI).
- [x] After merging [PR #69](https://github.com/arvectum2/arvectum-tools/pull/69), combined `main` at `7d2e5b4` passed the **entire 12/12-unit suite** on isolated iOS 27 simulator.
- [ ] Реальный iPhone: воспроизведение/сравнение с исходным crash report при наличии; сохранить неприкосновенной реальную историю и провести безопасную проверку на специально созданном disposable уведомлении, только с разрешения владельца.
- [ ] Не менять уже отправленную Apple первую 1.0. Подготовить отдельный patch release после решения Apple и физического QA.

**Тестовая фикстура:** `--store-screenshot-fixture` — существующая DEBUG-фикстура, **удаляющая историю** в тестовом контейнере. Запускалась только на специально созданном симуляторе. **Никогда** не использовать этот аргумент на iPhone с реальными данными.
