# C16 — публичная сверка Apple App Store, 27 октября 2026

Источник: официальный Apple Lookup API, HTTPS только для чтения. UTC: 2026-10-27T17:39:38+00:00. **Это не App Store Connect**, данные могут кэшироваться, не показывают keywords, ASC status, доступные локали ASC, build номера или App Privacy ответы.

| Приложение | RU версия | US версия | Языки опубликованной RU-сборки | RU iPhone/iPad снимки |
| --- | --- | --- | --- | --- |
| photo | 1.0.3 | 1.0.3 | EN, FR, DE, IT, JA, KO, PT, RU, ZH, ES, ZH | 4/1 |
| pushkin | 1.0.2 | 1.0.2 | EN, FR, RU, ES | 3/0 |
| what | 1.1.1 | 1.1.1 | EN, FR, RU, ES | 3/1 |
| chickmark | 1.5.2 | 1.5.2 | EN, FR, DE, IT, JA, PT, RU, ZH, ES, ZH | 3/1 |

Всего ответов: 16 витрин × 4 Apple ID. Региональный fallback не считается поддержкой исходных языков UI. Черновики C15 **не опубликованы**.

### Проверки и следующий этап

- [x] Достоверные публичные версии, перечни языков и устройства проверены в Apple Lookup read-only.
- [ ] ASC authenticated read-only diff: name/subtitle/keywords/description, локали, статус App Privacy, скриншоты и build для конкретной версии.
- [ ] Release/metadata upload только после приёмки подписанной сборки и согласия владельца.
