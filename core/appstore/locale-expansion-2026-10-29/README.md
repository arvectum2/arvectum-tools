# Новые региональные App Store-карточки — отдельные черновики

Дата: 29.10.2026. Сохраняем прежний 16×4 staged-базис без изменений: новое расширение не должно переименовать уже подготовленные карточки или подменить отснятые PNG.

## Нидерланды, Фото/PDF

- Файл: `photo-nl-NL.draft.json`, страна `NL`, исходная локализация iOS `nl` и metadata locale App Store Connect `nl-NL`.
- Apple официально включает Dutch в список 50 поддерживаемых локализаций метаданных, а Нидерланды имеют Dutch как основной язык App Store. Однако поддержка языка Apple не подтверждает, что новая локализация уже добавлена в конкретную учётную запись и версию приложения.
- Сейчас готовы только черновые нидерландские имя, подзаголовок, ключевые слова, промотекст, описание с PDF/рекламными оговорками, What's New, URL privacy и четыре подписи/сценария будущих скриншотов.
- Блокеры: независимая редактура, настоящие локализованные iPhone 6.9″ / iPad 13″ изображения и их визуальная QA, проверка наличия `nl-NL` непосредственно в ASC, требования к редактируемому состоянию версии, отдельное согласование публикации.
- `screenshotAssets=[]`, `appleLocaleEnabledForThisAppInASC=null`, `releaseApproved=false` и `uploadedToASC=false` намеренно: нет ложных файлов, живых запросов или состояний.

Проверка: `python3 core/tools/validate_appstore_locale_expansion.py`, `python3 -m pytest -q core/tests/test_appstore_locale_expansion.py`. Никаких API-вызовов Apple и локальных фото пользователя.

Источники Apple:

- https://developer.apple.com/news/?id=97t4mt64 — 31.03.2026: 50 поддерживаемых metadata localizations.
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/ — официальный список и таблица стран, NL = Dutch, дополнительный English (UK).
- https://developer.apple.com/documentation/appstoreconnectapi/betabuildlocalization/attributes-data.dictionary — официальный короткий код `nl-NL`.

Важно: наши 50 языков интерфейса и 50 Apple metadata localizations — разные множества: есть отличия по языкам, региональным вариантам и форматам кодов. Для каждого языка требуется отдельное сопоставление, не простой перенос ISO-кода из SwiftUI.
