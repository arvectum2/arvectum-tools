# Arvectum Tools — публичный ASO-аудит App Store, 26.10.2026

**Исправления подготовлены в ветке C10:** [64 draft ASO-пакета](../appstore/staged-2026-10-26/README.md), [3 исправленных настоящих RU кадра Pushkin](../../pushkin/store-assets/appstore/editorial-20261026/ru/iphone-6.9/), [редакторская матрица](EDITORIAL_ASO_C10_2026-10-26.md). Публичный App Store не изменялся.

**Проверено непосредственно, read-only:** 4 Apple ID × 12 витрин (RU/US/GB/DE/FR/ES/BR/JP/KR/CN/TR/TH) = **48 карточек**. Данные о версии/названии/описании/языках/скриншотах/рейтингах из официального [Apple Lookup](https://itunes.apple.com/lookup?id=6816346084,6817847111,6822476399,6818711298&country=ru&entity=software); **подзаголовки** извлечены из публичных страниц apps.apple.com как текст \`p.subtitle\`. Все 48 HTML страниц отвечали HTTP 200. Отчёт не использует App Store Connect, не меняет живые метаданные.

## Реальные версии и карточки RU / US / DE / FR

| Продукт | RU: название — подзаголовок | US: название — подзаголовок | DE: название — подзаголовок | FR: название — подзаголовок |
| --- | --- | --- | --- | --- |
| Фото/PDF | Фото и PDF под размер — Сжать фото и PDF по КБ | Photo & PDF Resize: KB — Compress photos & PDFs | Фото и PDF под размер — Dienst­programme | Фото и PDF под размер — Utilitaires |
| Pushkin | PUSHKIN by Arvectum — История уведомлений | PUSHKIN by Arvectum — Notification History | PUSHKIN by Arvectum — Dienst­programme | PUSHKIN by Arvectum — Notification History |
| Ухват | Ухват: голосовые заметки — Запись мыслей в одно касание | UhWhat? Voice Notes — Capture thoughts in one tap | UhWhat? Voice Notes — Produktivität | UhWhat? Voice Notes — Capture thoughts in one tap |
| ChickMark | ChickMark: трекер привычек — Цели, серии и напоминания | ChickMark: Habit Tracker — Goals, streaks & reminders | ChickMark: трекер привычек — Produktivität | ChickMark: трекер привычек — Цели, серии и напоминания |

Примечание: \`p.subtitle\` в неподдерживаемых локалях иногда заполняется **названием категории** («Dienstprogramme», «Utilitaires»), а не вашим собственным ASO-подзаголовком. Такие значения не трактуются как полноценная локализация.

## Все 12 витрин: язык представления карточки

| Витрина | Фото/PDF | Pushkin | Ухват | ChickMark |
| --- | --- | --- | --- | --- |
| RU | RU / RU | LAT / RU | RU / RU | RU / RU |
| US | LAT / LAT | LAT / LAT | LAT / LAT | LAT / LAT |
| GB | LAT / LAT | LAT / LAT | LAT / LAT | LAT / LAT |
| DE | RU / LAT | LAT / LAT | LAT / LAT | RU / LAT |
| FR | RU / LAT | LAT / LAT | LAT / LAT | RU / RU |
| ES | RU / LAT | LAT / LAT | LAT / LAT | LAT / LAT |
| BR | RU / LAT | LAT / LAT | LAT / LAT | RU / LAT |
| JP | RU / JA | LAT / JA | LAT / ZH | RU / ZH |
| KR | RU / KO | LAT / KO | LAT / KO | RU / KO |
| CN | RU / ZH | LAT / ZH | LAT / ZH | RU / ZH |
| TR | LAT / LAT | LAT / LAT | LAT / LAT | LAT / LAT |
| TH | LAT / LAT | LAT / LAT | LAT / LAT | LAT / LAT |

Эта таблица фиксирует **скрипт текста**, не качество перевода и не региональное SEO. В ряде витрин заголовки латиницей — английский fallback, а не язык страны.

## Главные находки и действия

- [x] **Проверен реальный публичный бинарник:** Фото/PDF 1.0.2 сообщает \`EN/RU\`, остальные (Pushkin 1.0.2, Ухват 1.1.1, ChickMark 1.5.1) — \`EN/FR/RU/ES\`. Это языки уже **опубликованных** сборок, не новые source-каталоги 12/20.
- [x] **P0 — Фото/PDF:** DE, FR, ES, BR, JP, KR, CN в Lookup показывают русское название и описание; в DE/FR скриншоты совпадают с RU. Перенос исходных 12 локалей в следующий релиз + локальные ASO metadata/визуал для выбранных регионов — приоритетнее расширения черновых 50 языков.
- [x] **P0 — Pushkin:** RU первый реальный App Store скриншот показывает английский интерфейс («Search notifications», «Messages», «History», «Settings»). Приготовить RU скриншоты с реальным интерфейсом; показать автоматизацию через Shortcuts, а не создавать впечатление универсального перехвата iOS уведомлений.
- [x] **P0 — ChickMark:** DE/FR/BR/JP/KR/CN витрины часто отображают русское название; FR описание локализовано, но заголовок русский. Первый RU скриншот — пустой контекстный список, почти без объясняющего value proposition; стоит начать с 1) быстрый check-in, 2) прогресс/серии, 3) напоминания.
- [x] **P1 — Ухват:** RU/EN первые скриншоты хорошо показывают кнопку быстрого захвата. На DE/BR/JP/KR пока англоязычная карточка. Показать вторым экраном формат аудио+транскрипция/сохранность, Watch-связку — только с реальными UI-снимками.
- [x] **Категория:** ChickMark публично Productivity — менять больше не нужно. Фото/PDF и Pushkin — Utilities, Ухват — Productivity.
- [x] **Мало оценок:** в RU Фото/PDF — 2, ChickMark — 2; Pushkin и Ухват — 0 (публичное Lookup наблюдение 26.10). Не выводить показатель по всем странам из RU и не использовать обмен/покупку фиктивных отзывов.
- [x] **Скриншоты:** Фото/PDF 4 iPhone / 0 iPad, Pushkin 3/0, Ухват 3/1, ChickMark 3/1 (RU Lookup). Это не рекомендация добавлять iPad поддержку ради картинки.

## Приоритет реализации (без Apple upload)

- [ ] **ASO-A0:** подготовить под следующий RC честные локализованные названия/подзаголовки/keywords/описания на языке iOS интерфейса. Проверить 30 символов title/subtitle и 100 UTF-8 байт keywords; не выдавать ASO-язык без native UI за готовый.
- [ ] **ASO-A1 Фото/PDF:** 20 draft ASO метаданных уже есть (\`photo-pdf-to-size/docs/aso/metadata-2026-10-26-review.json\`), \`th\` — ASO-черновик без локализованного тайского UI. Выбрать фактически поддерживаемые регионы, перепроверить паспортные/визовые требования и рекламный consent; переснять 4 экрана на новом подписанном RC.
- [ ] **ASO-A2 Pushkin:** заново снять все 3 RU скриншота на свежем билде: настоящие русские подписи, поиск, выбор источников, объяснение Shortcuts. Отдельный US/FR/ES набор с реальным UI соответствующей локали.
- [ ] **ASO-A3 ChickMark:** заменить первый скриншот с пустым списком на понятное УТП, добавить ход проверки привычки и серии; сделать RU/EN/ES/FR и при выпуске новых языков DE/PT-BR/KO/JA с реальным UI.
- [ ] **ASO-A4 Ухват:** добавить скриншот «запись → аудио и текст → поиск» и отдельно Apple Watch, когда сценарии прошли физическую QA; не обещать транскрипцию на каждом новом языке интерфейса.
- [ ] **ASO-A5:** проверить App Store Connect read-only по назначению метаданных и доступным локалям/территориям, приложениям и возрастным рейтингам; внешнюю публикацию/изменение live карточек делать только после нового точечного согласования владельца.

**Ограничения:** Apple Lookup не раскрывает **keywords**, App Store search rankings, impressions, conversion, удержание или точные build номера. Публичная HTML-страница позволяет проверить видимый subtitle, но может использовать fallback/категорию. Анализ 48 карточек — не обещание органического роста и не доступ в App Store Connect. Скриншоты проверялись по фактическим файлам первых экранов в RU/US; другие рынки дополнительно сверены по опубликованным screenshot URL.

## Прямые карточки (публичные)

- [Фото и PDF под размер](https://apps.apple.com/ru/app/id6816346084)
- [PUSHKIN by Arvectum](https://apps.apple.com/ru/app/id6817847111)
- [Ухват](https://apps.apple.com/ru/app/id6822476399)
- [ChickMark](https://apps.apple.com/ru/app/id6818711298)
