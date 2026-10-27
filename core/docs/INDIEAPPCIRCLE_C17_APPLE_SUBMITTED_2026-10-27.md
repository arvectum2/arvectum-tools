# C17 — App Store Connect: отправлено на проверку (27.10.2026)

Авторизованная read-only проверка ASC после приёмки 448 снимков подтверждает для всех четырёх версий WAITING_FOR_REVIEW и AFTER_APPROVAL. Это означает отправку на App Review, а не фактическую публикацию.

| Приложение | Версия | Apple ID | Статус | После одобрения | Регионов | Скриншотов |
|---|---|---|---|---|---:|---:|
| Фото/PDF | 1.0.4 (16) | 6816346084 | WAITING_FOR_REVIEW | AFTER_APPROVAL | 16 | 128 |
| Pushkin | 1.0.3 (7) | 6817847111 | WAITING_FOR_REVIEW | AFTER_APPROVAL | 16 | 64 |
| Ухват | 1.1.2 (10) | 6822476399 | WAITING_FOR_REVIEW | AFTER_APPROVAL | 16 | 128 |
| ChickMark | 1.5.3 (21) | 6818711298 | WAITING_FOR_REVIEW | AFTER_APPROVAL | 16 | 128 |

Все 64 набора метаданных и 448 фотографий подтверждены Apple как COMPLETE. IPA подписаны Apple Distribution и отправлены. Их SHA-256 зафиксированы в INDIEAPPCIRCLE_C17_SIGNED_RELEASE_MANIFEST.json.

## Открытые условия

- [x] 4 IPA привязаны и отправлены на Apple Review.
- [x] Все 16 локализаций / продукт и снимки прошли ASC preflight.
- [x] Выбрано автоматическое опубликование AFTER_APPROVAL.
- [ ] Apple ещё не одобрил версии и не опубликовал их в магазине.
- [ ] В PR #155 остается ошибочный GitHub ChickMark accessibility UI тест; повторный локальный тест запущен отдельно.
- [ ] Hardware QA и дополнительное подтверждение рекламы / App Privacy в Фото/PDF остаются самостоятельными задачами.

Официальный App Store Connect: https://appstoreconnect.apple.com/apps
