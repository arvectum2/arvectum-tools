# Core — 50 языков интерфейса и региональные карточки App Store

Срез: 29.10.2026. Канонический реестр — `core/localization/portfolio-locales.json`; staged-карточки — `core/appstore/staged-2026-10-26/`.

## 29.10.2026 · Третий source-пакет Indonesian (Ухват)

`id` добавлен в 4 комплекта Ухвата, включая системные разрешения iPhone и Watch. Сохранена архитектурная независимость языка интерфейса от выбранной локали распознавания речи; сообщения о Watch ACK/очереди и исходной медиатеке не обещают преждевременного удаления. Source 55/200: Фото/PDF, PUSHKIN и Ухват 14/50, ChickMark 13/50. Indonesia ASO draft для Ухвата пока не сформирован; live ASC неизменён.

## 29.10.2026 · Второй source-пакет Indonesian (PUSHKIN)

PUSHKIN добавил `id` 159 UI строк, безопасные инструкции ручных автоматизаций Shortcuts и локализованное число приложений. Теперь Photo/PDF и PUSHKIN по 14/50 исходных языков, Ухват и ChickMark по 13/50 — всего **54/200** app×locale. В отличие от текста App Store для Фото/PDF, региональный `id` copy draft для PUSHKIN ещё требуется отдельно. Настоящие уведомления и настройки Shortcuts не менялись.

## 29.10.2026 · Первые ASO метаданные Индонезии (только Photo/PDF)

`photo-id.draft.json` — отдельный read-only source/copy draft с метаданными `id` для storefront `ID`. Apple официально разрешает Indonesian как дополнительный язык для Indonesia при базовом English (U.K.). Это не загрузка, не добавленная локаль в пользовательском ASC и не новые региональные скриншоты; `uploadedToASC=false`, `screenshotAssets=[]`, `appleLocaleEnabledForThisAppInASC=null`. Прежние 64 staged и 4 NL drafts не затронуты.

## 29.10.2026 · Indonesian Tier 1: Photo/PDF source 14/50

После полной Dutch source-волны 4×13, начата следующая на `id`: переведён первый продукт Фото/PDF (161 ключ + InfoPlist), структурно **14/50** только у него; PUSHKIN, Ухват и ChickMark остаются **13/50**. Итого **53/200**. Это source-каталог, а не редакторское согласование или App Store публикация. Apple допускает Indonesian для Indonesia как дополнительный язык метаданных, а не системный язык по умолчанию (официальная таблица: https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations).

## 29.10.2026 · Финальный source+copy baseline Netherlands (NL)

Теперь **4/4** приложений имеют `nl` исходные UI каталоги (все 10 доступных iOS/watchOS/widget bundles) — 13/50 языков на каждое, **52/200** пар app×locale. Кроме того **4/4** отдельных нидерландских `nl-NL` черновика metadata в `core/appstore/locale-expansion-2026-10-29/`. Offline validator и 10 тестов региональной карточки блокируют ложные статусы: screenshotAssets пуст, uploads/approvals false, ASC account locale unverified. Реальные переводы/скриншоты требуют редакторского/физического подтверждения; это не выпущенные версии. Исходные **64** staged карточки неизменны, Where? PAUSED.

## 29.10.2026 · Dutch завершён структурно во всех четырёх приложениях

ChickMark добавил `nl` во все свои iPhone/Watch/widget bundles — теперь каждый из четырёх активных iOS продуктов имеет **13/50** source каталога и все **10 соответствующих bundles** имеют полные `nl` ключи. Суммарно **52/200 app×locale source-пар**. Нельзя трактовать machine/source completion как независимую редактуру, доступность на физических устройствах, Apple Health acceptance или публикацию в App Store. Региональный NL ASO для ChickMark остаётся самостоятельной задачей после исходного PR.

## 29.10.2026 · Три черновика NL: Фото/PDF, PUSHKIN, Ухват

Отдельные `nl-NL` draft-карточки теперь существуют для Photo/PDF, PUSHKIN и Ухвата. Их метаданные проверяются offline; список настоящих скриншотов пуст, human/ASC/release approvals отсутствуют, сервер Apple не менялся. Ухват явно раскрывает задержку Watch→iPhone до ACK, приватность оригинальных медиа, доступность распознавания речи и необходимость уведомительных разрешений. Для ChickMark пока нет Dutch source или NL ASO draft.

## 29.10.2026 · Dutch: Ухват добавлен как третий продукт

Ухват получил исходные Dutch переводы во всех своих четырёх iPhone/watchOS/widget bundles и `CaptureBrand` routing с независимой языковой настройкой транскрипции. Структурное покрытие **51/200 app×locale пар**: Фото/PDF 13, Pushkin 13, Ухват 13, ChickMark 12. Региональная App Store карточка Dutch для Ухвата пока отсутствует, существующие два `nl-NL` черновика — только Фото/PDF и PUSHKIN. Готовность source не означает доступности на устройстве или публикации.

## 29.10.2026 · Нидерланды: два из четырёх региональных черновиков

Два независимых `nl-NL` copy draft в `core/appstore/locale-expansion-2026-10-29/`: Фото/PDF и PUSHKIN. У обоих `sourceLocale=nl`, `screenshots=[]`, ASC status не проверен и releaseApproved=false. Для PUSHKIN честно описана ручная настройка Apple Shortcuts и отсутствие универсального доступа к уведомлениям; только iPhone-кадры. Offline validator/tests запрещают подменять неподтверждённые снимки и редактуру фиктивными значениями. Для Ухвата/ChickMark ещё нет полного исходного `nl` и готовых региональных карточек.

## 29.10.2026 · Следующий шаг Dutch source (PUSHKIN)

В PUSHKIN появился `nl` с 159 переведёнными ключами, корректным `PushkinCopy` routing и plural `appCount`. Теперь Фото/PDF **13**, PUSHKIN **13**, Ухват и ChickMark по **12** — всего **50/200** исходных app×locale пар. Не путать это с выпущенными локалями Apple. Отдельная карточка NL для PUSHKIN ещё не подготовлена и не опубликована; для Фото/PDF отдельный copy draft уже лежит в `core/appstore/locale-expansion-2026-10-29/`.

## 29.10.2026 · Промежуточный прогресс (после базовой сверки)

Photo/PDF добавил исходный нидерландский `nl` (161 ключ + InfoPlist): **13/50** только в этом приложении. ChickMark, Pushkin и Ухват остаются **12/50**; итого **49/200 app×locale** source-пар, а **не** 13/50 по всему портфелю. Ниже цифры 12/50 и 48/200 описывают исходную точку до перевода. Для Нидерландов создан отдельный непубликуемый [черновик `nl-NL`](../appstore/locale-expansion-2026-10-29/README.md), без неподтверждённых PNG и без изменений текущих 64 карточек. UI-перевод не создаёт автоматически опубликованную metadata card.

## Базовая точка

- Четыре опубликованных iOS-приложения: ChickMark, Pushkin, Ухват/What?, Фото/PDF. Where? остаётся PAUSED.
- **12 из 50 языков структурно готовы в исходниках** всех четырёх iOS-приложений и их 10 iPhone/watchOS/widget bundles: `en, ru, es, fr, de, pt-BR, pt-PT, it, ja, ko, zh-Hans, zh-Hant` — **48 из 200** будущих app×locale пар. «Готов в исходниках» не равно «вычитан носителем», «прошёл аппаратную проверку» или «опубликован».
- **50 уникальных языковых кодов** из реестра: Tier 1 — 20, Tier 2 — 20, Tier 3 — 10; остаются 38 × 4 = 152 новые iOS app×locale пары. Android Фото/PDF содержит 9 исходных пакетов, расширение 41 отложено после iOS/watchOS.
- **64 staged-карточки = 4 приложения × 16 metadata locale-вариантов**. Это исходные данные и скриншоты в Git, не команда обновления live App Store. Региональная Apple Lookup проверка 16 стран и языковая локализация интерфейса — отдельные показатели.

## Очередь локализации

| Этап | Состояние | Работы |
| --- | --- | --- |
| L0, исходные 12/50 | Структурно готово; редактура открыта | 10 bundles, 48 XCUITest coverage contracts, strings/placeholder audit |
| L1, 13–20/50 | TODO | `hi, ar, id, tr, vi, nl, pl, th` × 4 приложения; RTL для ar |
| L2, 21–40/50 | TODO | `fa, ur, bn, pa, ta, te, mr, gu, kn, ml, uz, ms, fil, sw, ro, hu, cs, sk, el, he` × 4 |
| L3, 41–50/50 | TODO | `ha, am, sv, da, fi, nb, bg, sr, hr, ca` × 4 |
| A0, региональные карточки 16×4 | Staged 64/64 | Индивидуальная редактура, metadata/keywords, реальные кадры iPhone/iPad, approval |
| A1, новые целевые регионы | TODO | Country → поддерживаемый ASC locale, отдельная региональная редактура или документированный fallback |

Для нового языка: перевести не только экраны, но и InfoPlist/permissions, ошибки, уведомления, Shortcuts/Siri, Watch/widgets и доступность; проверить множественные числа, RTL, шрифты, Dynamic Type, placeholders, нативный UI, VoiceOver и формулировки privacy. Машинная проверка не заменяет редактуру носителем. Не создавать каталоги, заполненные английскими заглушками.

## Существующие metadata locale-варианты (каждый из четырёх продуктов)

| Staged locale | Целевой регион / языковая аудитория |
| --- | --- |
| `ru` | Россия / русскоязычные рынки |
| `en-US` | США |
| `en-GB` | Великобритания |
| `en-AU` | Австралия |
| `en-CA` | Канада (английская аудитория) |
| `es-ES` | Испания |
| `es-MX` | Мексика / испаноязычная Латинская Америка |
| `fr-FR` | Франция / франкоязычные рынки |
| `de-DE` | Германия / немецкоязычные рынки |
| `it` | Италия |
| `ja` | Япония |
| `ko` | Республика Корея |
| `pt-BR` | Бразилия |
| `pt-PT` | Португалия |
| `zh-Hans` | регионы упрощённого китайского |
| `zh-Hant` | регионы традиционного китайского |

Это **наши staged-ключи**, а не гарантия, что Apple поддерживает каждый из них как отдельный metadata locale в любой стране. Проверять допустимый Apple locale и доступность storefront в ASC перед расширением. С 31.03.2026 Apple официально поддерживает **50** локализаций метаданных App Store Connect ([новость](https://developer.apple.com/news/?id=97t4mt64), [справочник](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/)). Наши 50 целевых UI языков и Apple 50 metadata-вариантов не тождественны по составу и коротким кодам; не копировать `nl` вместо Apple `nl-NL`, не выдумывать локали для языков, которых нет в списке. Там, где нет локализации, явно фиксировать допустимый fallback.

## 29.10.2026 · A1 — автоматическая сверка 16 существующих стран

- [x] Read-only CLI `python3 core/tools/regional_aso_readiness.py --format table` (или `--format json`) строит **64 пары app×storefront** из C18 country-specific публичного Apple Lookup и 64 staged-карточек. Учитываются версии, количество iPhone/iPad снимков, назначенный черновик регионального текста и реально присутствующий UI source language.
- [x] Fail-closed проверки не допускают отсутствующую страну/черновик карточки, несоответствующий bundle ID и отсутствие обязательных полей карточки. Автоматические тесты `core/tests/test_regional_aso_readiness.py` покрывают корректную матрицу и отказ при расхождениях.
- [ ] Для следующих регионов требуется реальное ASC GET подтверждение допустимых локализаций, витрины, правовых claims и редакторская приёмка. Старые публичные наблюдения не равны сегодняшнему статусу: C18 ChickMark ещё **1.5.2**, более поздний C19 уже подтвердил **1.5.3**. CLI специально оставляет дату `observed_utc` и `apple_metadata_locale_verified_for_country=false`, не делает Apple сетевых запросов или live updates.

## Карточка для каждого целевого региона: обязательный контракт

1. `app`, `storefrontCountry`, `appleSupportedMetadataLocale`, `uiSourceLocale`, `fallback`, `liveVersion` и источник проверки App Store Connect.
2. Региональные Title/Subtitle/Keywords/Description/Promotional Text/What's New. Ограничения продукта нельзя скрывать: Pushkin зависит от Shortcuts, Ухват — от разрешений и Watch, ChickMark — от HealthKit, Фото/PDF — от документа/экспорта и рекламных SDK.
3. Настоящие скриншоты локализованного UI с iPhone и с iPad **только там, где приложение поддерживает iPad**; своя последовательность экранов для рынка, отсутствие фиктивной рекламы/данных, screenshot SHA и визуальная проверка.
4. Проверка лимитов Apple, повторов keywords, claims/privacy, ссылок поддержки, языка и региональных особенностей, человеческая редактура.
5. Статусы: `SOURCE_READY → MACHINE_VALIDATED → NATIVE_UI_QA → HUMAN_REVIEW → OWNER_RELEASE_APPROVAL → ASC_CONFIRMED → PUBLIC_LOOKUP`. Обновлять только достигнутый этап.

Сначала расширять целевые storefronts для языков L1: хинди/Индия, арабоязычные регионы, Индонезия, Турция, Вьетнам, Нидерланды, Польша, Таиланд. Не утверждать, что для каждого из них Apple позволяет соответствующий язык metadata: карту доступных locales проверять непосредственно в ASC. Затем целевые рынки L2/L3 на основании спроса/результатов ASO, без выдуманных региональных карточек.

## Инженерные и релизные гейты Core

- [ ] Жёсткая автоматическая проверка 50 уникальных кодов, 12 комплектов на 10 платформах, 48 app×locale XCUITest contracts и 64 staged metadata карточек одинакового состава.
- [ ] QA каждой волны: translation keys/printf/plurals, native UI и Dynamic Type, VoiceOver, iPad/Watch, permission prompts, privacy/consent, RTL/Indic/CJK и реальный пользовательский сценарий.
- [ ] CI и data safety по конкретным платформам: UUID/ACK, бездеструктивные миграции/backup, HealthKit, Shortcuts, Photos/Files, работа без сети; не удалять личные данные при тестах.
- [ ] Измерять региональную конверсию App Store impression→product view→install→retention по авторизованным данным ASC, доходность рекламы по данным партнёра, не по имитации показов.
- [ ] Никаких новых загрузок binaries/metadata/скриншотов без отдельного точного разрешения владельца, version/build/SHA и релизной приёмки.

Связи: [Core roadmap](../ROADMAP.md), [реестр 50 локалей](../localization/portfolio-locales.json), [инструкция по i18n](../localization/README.md), [staged ASO](../appstore/staged-2026-10-26/README.md).
