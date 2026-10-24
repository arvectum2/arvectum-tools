# ChickMark 1.5.1 (19) — четыре языка

Релизный кандидат после публичной версии 1.5.0(18):
RU / EN / ES / FR — iPhone, Apple Watch, оба виджета.
Версии iPhone + Watch + Widgets одинаковые: 1.5.1(19).

- [x] Четыре полных исходных каталога во всех четырёх продуктах.
- [x] Французский App Shortcuts набор из 4 команд, с неизменными именами placeholder.
- [x] Французские системные HealthKit usage descriptions уже были в исходниках.
- [x] Источники App Store категории переведены с Health & Fitness на Productivity.
- [x] Source portfolio audit, 33 Python tests и release hygiene PASS.
- [ ] CI сборки iPhone/Watch, регрессия локализации, проверка реального IPA.
- [ ] Проверить in-place upgrade с пользовательскими привычками и CloudKit,
  не затрагивая чужие записи HealthKit. Реальный сценарий revoke/regrant открыт.
- [ ] Создать metadata RU, EN, ES и FR в ASC; category Productivity требует
  установки в редактируемом новом App Store AppInfo.
- [ ] Отдельное разрешение на конкретный App Store upload/review
  и точное соответствие собранному подписанному IPA.

Смена версии не равна выпуску в Store.
