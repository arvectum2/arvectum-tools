# Новые региональные App Store-карточки — отдельные черновики

Дата: 29.10.2026. Сохраняем прежний 16×4 staged-базис без изменений: новое расширение не должно переименовать уже подготовленные карточки или подменить отснятые PNG.

## 29.10.2026 · Indonesia: все 4 региональных copy drafts

- [x] Добавлены `photo-id.draft.json`, `pushkin-id.draft.json`, `what-id.draft.json` и `chickmark-id.draft.json`. Для каждого — Bahasa Indonesia name/subtitle/keywords/promotional/description/WhatsNew, настоящий URL privacy и план четырёх будущих экранов.
- [x] Честные юридические и продуктовые оговорки: PDF rasterization и реклама; ручные Shortcuts без универсального доступа к уведомлениям; очередь Watch до iPhone ACK и сохранение аудио; HealthKit/водные права, iCloud backup и объявления.
- [x] Всего 8 новых черновиков: NL×4 и ID×4. Все проходят offline validator с `screenshotAssets=[]`, `releaseApproved=false`, `uploadedToASC=false`, `appleLocaleEnabledForThisAppInASC=null`. Прежние 64 staged варианта не затронуты.
- [ ] Независимая языковая редактура, настоящие screenshots, live ASC проверка нужной версии и per-release approval. Для Indonesia Apple указывает основной English UK и дополнительный Indonesian.

## Индонезия (`ID`), Фото/PDF — новый язык метаданных `id`

- Файл: `photo-id.draft.json`, storefront Indonesia (`ID`), бинарный язык `id`, короткий metadata locale `id`. По [официальной таблице Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/) язык по умолчанию для Indonesia — English (U.K.), Indonesian — дополнительно доступная локализация; её существование в нашей текущей версии ASC НЕ проверено.
- Локализованы маркетинговые name/subtitle/keywords/promo/description/WhatsNew и четыре подписи для будущих реальных экранов; откровенно описаны пиксели, PDF rasterization, реклама и исключительно локальная обработка фото/PDF. Все поля в лимитах, без настоящих PNG, без fake upload/approval.
- [ ] Носитель Bahasa Indonesia, реальные iPhone 6.9″ и iPad 13″ screenshots, проверка в ASC и независимый release approval. Раздел `core/tools/validate_appstore_locale_expansion.py` теперь различает `NL/nl-NL/nl` и `ID/id/id` и fail-closed отклоняет чужой код/country/фиктивные файлы.

## Нидерланды, Фото/PDF

- Файл: `photo-nl-NL.draft.json`, страна `NL`, исходная локализация iOS `nl` и metadata locale App Store Connect `nl-NL`.
- Apple официально включает Dutch в список 50 поддерживаемых локализаций метаданных, а Нидерланды имеют Dutch как основной язык App Store. Однако поддержка языка Apple не подтверждает, что новая локализация уже добавлена в конкретную учётную запись и версию приложения.
- Сейчас готовы только черновые нидерландские имя, подзаголовок, ключевые слова, промотекст, описание с PDF/рекламными оговорками, What's New, URL privacy и четыре подписи/сценария будущих скриншотов.
- Блокеры: независимая редактура, настоящие локализованные iPhone 6.9″ / iPad 13″ изображения и их визуальная QA, проверка наличия `nl-NL` непосредственно в ASC, требования к редактируемому состоянию версии, отдельное согласование публикации.
- `screenshotAssets=[]`, `appleLocaleEnabledForThisAppInASC=null`, `releaseApproved=false` и `uploadedToASC=false` намеренно: нет ложных файлов, живых запросов или состояний.

## Нидерланды, PUSHKIN

- Файл: `pushkin-nl-NL.draft.json`, страна `NL`, исходная iOS локаль `nl`, metadata локаль Apple `nl-NL`. Нидерландский UI-каталог PUSHKIN добавлен отдельно; физический триггер Apple Opdrachten не тестировался.
- Черновики name/subtitle/keywords/promo/description/What's New и четыре сценария будущих настоящих iPhone-скриншотов. iPad не заявлен как поддерживаемый маркетинговый форм-фактор PUSHKIN.
- Оговорки обязательны: PUSHKIN **не может автоматически читать все уведомления**, не может включать автоматизации Shortcuts за пользователя или проверять состояние системного переключателя. Импортированная автоматизация первоначально отключена; пользователь вручную включает её и подтверждает по фактической полученной записи. Данные локальны на iPhone.
- Нет файлов screenshot (`screenshotAssets=[]`), независимой редакторской вычитки, реального ASC GET и согласованного релиза. Флаги `releaseApproved=false` и `uploadedToASC=false` защищены автоматическим validator gate. 64 действующих staged черновика не затронуты.

## Нидерланды, Ухват / UhWhat?

- Файл: `what-nl-NL.draft.json`, `NL/nl-NL`, исходный язык `nl` теперь охватывает iPhone, Watch, виджет и complication. Официальный нидерландский metadata shortcode Apple уже подтверждён; наличие локали именно в текущей ASC версии Ухвата ещё **не** подтверждено.
- В тексте достоверно отражено, что исходная запись сохраняется, Watch держит аудио до подтверждения от iPhone и передача на фоне может задерживаться. Локальное распознавание речи зависит от поддерживаемого языка/устройства и независимо от языка интерфейса. Напоминания требуют согласия на уведомления.
- Четыре будущих iPhone/iPad сценария скриншотов отмечены только как plan; screenshotAssets пуст, approvals ложны и Apple uploads не производились. Для реального NL запуска нужны независимая редактура, native capture/screenshots, ASC проверка/доступность и отдельное распоряжение на релиз.

## Нидерланды, ChickMark

- Файл: `chickmark-nl-NL.draft.json`, страна NL, метаданные Apple `nl-NL`, iOS source `nl` существует во всех четырёх ChickMark iPhone/Watch/widgets bundles. Новый текст отделён от прежних 16×4 staged локализаций.
- Отдельно раскрыты ограничения HealthKit: подключение целей активности добровольное, измерения остаются локальными; запись количества воды в Apple Gezondheid требует явного включения и прав, прошлые дни не экспортируются автоматически. Ручные привычки могут синхронизироваться по прежним настройкам iCloud; при замене резервной копии удаление может синхронизироваться через iCloud. Указаны реклама, privacy URL, Watch и ограничения синхронизации.
- Четыре идеи iPhone/iPad screenshots только в `screenshotPlan`: настоящих изображений нет (`screenshotAssets=[]`). Нет редакторского согласования и реальной ASC проверки, `releaseApproved=false`, `uploadedToASC=false`. Никаких HealthKit/CloudKit/Apple mutations.

## Статус всей NL волны (29.10.2026)

- [x] **4/4 исходных iOS source packages nl**: по 13/50 пакетов UI на приложение, 52/200 пар app×locale; полный ключевой набор во всех десяти iPhone/Watch/widget bundles, где применимо.
- [x] **4/4 черновика nl-NL metadata**: Фото/PDF, PUSHKIN, Ухват и ChickMark. В Git 64 старых staged карточки не затронуты.
- [ ] Независимая редактура носителем, настоящие screenshots под устройство, физическая QA разрешений/Watch, подтверждение доступности nl-NL в ASC, поштучное согласование релизов. Никаких live storefront или бинарных изменений не сделано.

## Турция, Фото/PDF — новая волна `tr`

- Файл `photo-tr.draft.json`: UI locale `tr`, metadata Apple locale **`tr`** (не `tr-TR`), страна `TR` (Türkiye); согласно Apple Turkish указан дополнительным языком storefront к English (UK). Источники: [официальная таблица](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/) и [официальная документация кодов](https://developer.apple.com/documentation/appstoreconnectapi/managing-metadata-in-your-app-by-using-locale-shortcodes).
- Поля name/subtitle/keywords/promotionalText/description/whatsNew и privacy URL подготовлены, в тексте сохранены caveats о PDF-растрировании, требованиях документов и рекламной SDK. Четыре будущих iPhone/iPad снимка только в плане; файл не отправлялся в App Store Connect.
- `appleLocaleEnabledForThisAppInASC=null`, `screenshotAssets=[]`, `uploadedToASC=false`, `releaseApproved=false`. Перевод редактором-носителем, реальные screenshots/ASC GET, права/ATT и отдельное согласование релиза ещё открыты.

Проверка: `python3 core/tools/validate_appstore_locale_expansion.py`, `python3 -m pytest -q core/tests/test_appstore_locale_expansion.py`. Никаких API-вызовов Apple и локальных фото пользователя.

Источники Apple:

- https://developer.apple.com/news/?id=97t4mt64 — 31.03.2026: 50 поддерживаемых metadata localizations.
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/ — официальный список и таблица стран, NL = Dutch, дополнительный English (UK).
- https://developer.apple.com/documentation/appstoreconnectapi/betabuildlocalization/attributes-data.dictionary — официальный короткий код `nl-NL`.

Важно: наши 50 языков интерфейса и 50 Apple metadata localizations — разные множества: есть отличия по языкам, региональным вариантам и форматам кодов. Для каждого языка требуется отдельное сопоставление, не простой перенос ISO-кода из SwiftUI.
