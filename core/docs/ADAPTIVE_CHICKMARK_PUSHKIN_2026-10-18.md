# iPad / Duo: ChickMark и Pushkin — 18.10.2026

**Scope:** feature/apps-ipad-duo-20261018, основание — совмещённый Core/UhWhat/Photo PR #90. Это не публичный релиз. Growth, Where?, реальные пользовательские данные не затронуты.

## Изменения

- ChickMark: iPad target, iPad-ориентации (iPhone по-прежнему portrait), читаемая ширина Today/деталей до 840 pt. Sticky native ad остаётся в одном VStack со списком, не накладывается на него. Модели, чек-ины, HealthKit, Watch, CloudKit и алгоритмы привычек не менялись.
- Pushkin: iPad target, iPad-ориентации (iPhone portrait), читаемая ширина History/Search, Apps/Setup, Settings до 960 pt. Native TabView на iPad/Duo адаптирует вкладки в правый sidebar; структура TabView и его state сохранены. Удаление и хранение уведомлений, Shortcuts, разрешения не менялись.
- Оба проекта напрямую включают только один source ArvectumAdaptiveLayout из Core во избежание дублирования существующих импортированных Swift-типа; новых SDK не добавлено.
- AppIcon 152/167 на iPad получены масштабированием существующих оригинальных иконок; никакой новой айдентики.

## Локальные доказательства

Xcode 27.1 / Swift 6.4, Mac mini, изолированные Arvectum-T5-iPad (iOS 27.0) и Arvectum-T4-Duo (iOS 27.1).

| Проверка | Результат |
| --- | --- |
| Debug build ChickMark и Pushkin | **PASS** |
| Core architecture, lockfiles, shared catalogs | **PASS** |
| ChickMark in-memory create habit + rotate, iPad | **1/1 PASS** |
| ChickMark in-memory create habit + rotate, Duo | **1/1 PASS** |
| Pushkin DEBUG fixture history/search/rotate and setup, iPad | **2/2 PASS** |
| Pushkin DEBUG fixture history/search/rotate and setup, Duo | **2/2 PASS** |

**Диагноз первоначальных 2 Pushkin UI FAIL:** тест ошибочно предполагал, что вкладки доступны только в tabBars. iPad/Duo SwiftUI использует адаптивную боковую панель (подтверждено accessibility hierarchy), тест обновлён для native buttons; затем 2/2 PASS на Duo и 2/2 PASS на iPad. Нет доказанного дефекта пользовательского интерфейса, менять TabView не требуется.

## Не утверждать

- Отсутствие настоящего Duo — не блокер; проверка на симуляторе + возможные исправления после обратной связи. Не испытано механическое fold/unfold.
- Не проверены на физическом iPad/Phone реальные iCloud/CloudKit синхронизация, HealthKit, notification permissions, Shortcuts и native ads, full VoiceOver и Split View.
- Не менялись App Store Connect и отправленные в Review версии ChickMark 1.5.0 и Pushkin 1.0. Это feature-пилот, не новая публичная поддержка iPad.

**Релизные ворота:** итоговая матрица CI, UI полного сценария, отдельный signed build и App Review. Log/XCResult на ArvectumSSD/Arvectum/tmp.
