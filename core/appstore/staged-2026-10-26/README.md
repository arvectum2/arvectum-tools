# App Store ASO — пакет C10, 26 октября 2026

**Только черновики в Git. Ничего не загружено в App Store Connect и не изменено в публичных карточках.** Файлы не являются готовой отправкой в App Review. Для новой версии требуется явное согласие владельца на точные version/build/hash и отдельно на изменение live metadata по правилам `AGENTS.md`.

## Покрытие

| Продукт | Apple ID | Локалей метаданных | Языков исходного UI | Что подготовлено |
| --- | --- | ---: | ---: | --- |
| Фото/PDF | 6816346084 | 16 | 12 | photo.json; плюс китайские zh-Hans/Hant черновики к существующим 14 региональным записям |
| Pushkin | 6817847111 | 16 | 12 | pushkin.json; исправлены RU маркетинговые демоданные и 3 настоящих RU Simulator-кадра |
| Ухват | 6822476399 | 16 | 12 | what.json; сохранён бренд UhWhat?, оговорки по Watch и языку распознавания |
| ChickMark | 6818711298 | 16 | 12 | chickmark.json; HealthKit и рекламная оговорка, без ложного обещания синхронизации |

Подготовлены **64 полных пакета текстовых метаданных**: name, subtitle, UTF-8 keywords, promotional text, description, What's New, четыре локализованные подписи к будущим screenshot. Используются языки App Store Connect: `ru`, `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `fr-FR`, `de-DE`, `it`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hans`, `zh-Hant`. Региональные версии EN и ES опираются на **те же языки UI**: это не новые бинарные языки. Тайский/хинди/арабский и остальные будущие Tier 1 сюда не включены: их UI ещё нет.

## Проверки и качество

- [x] Все 64 записи прошли лимиты App Store: name/subtitle ≤30 символов, keywords ≤100 UTF-8 байт, promo ≤170, description ≤4000, What's New ≤4000; 4 заголовка screenshot/локаль. См. `python3 core/tools/validate_appstore_staging.py`.
- [x] Проверено, что metadata не меняет имена брендов (`UhWhat?`, `PUSHKIN`, `ChickMark`), ссылки на privacy 200, критические ограничители интерфейса сформулированы корректно в источниках; выполнен выборочный back-translation семантических оговорок для 44 неанглоязычных карточек (`editorial/marketing_backtranslation.json`). Три итальянских/японских/pt-PT предупреждения из back-translation проверены по тексту: это отсутствие буквального слова «file», но упоминание локальной обработки и рекламы сохранено.
- [x] Машинный аудит 197 каталогов и 10 237 строк: 0 ошибок по формату/разрешениям/брендам, 32 допустимых английских совпадения классифицированы. 4 155 риск-чувствительных строк экспортированы в двуязычную редакторскую таблицу `editorial/critical_source_target_review.csv`.
- [x] Исправлены явные смысловые ошибки KO (UhWhat?, расшифровка, «табель успеваемости», разрешения).
- [x] Внутри Debug Pushkin добавлена настоящая RU фикстура и native XCUITest 3/3 PASS; 3 скриншота на реальном iOS 27 Simulator iPhone 18 Pro Max, **1320×2868**, в `pushkin/store-assets/appstore/editorial-20261026/ru/iphone-6.9/`. Это не финальные картинки для новой подписанной RC.
- [ ] Профессиональная построчная проверка носителями 11 переводных языков и юридически значимых разрешений/рекламы/Health/автоматизаций. Это **не** заменяется нейросетевым переводом, Core lint или back-translation.
- [ ] Скриншоты: `screenshot_manifest.json` содержит **448 необходимых image slots** (16 регионов, 4 позиции, iPhone и для поддерживающих iPad — отдельная 13-inch серия). Сейчас **15 доступных черновых файлов** (12 Photo ранее + 3 RU Pushkin) и **433 незакрытых slots**. Никаких выдуманных экранов и интерфейсов на несоответствующем языке.
- [ ] Финальная визуальная и аппаратная QA каждого выбранного выпуска: iPhone/iPad/Watch, VoiceOver/Dynamic Type, согласия, сохранность пользовательских данных.
- [ ] Подписанные архивы с версиями выше публичных, SHA-256, App Store Connect read-only сверка действующих языков, отдельное разрешение на любую загрузку/публикацию.

## Воспроизводимая работа

`prepare_appstore_localizations.py` создаёт машинные черновики и кеширует одинаковые переводы; `finalize_appstore_drafts.py` восстанавливает защищённые имена продуктов и терминологию; `plan_appstore_screenshots.py` строит slots из фактических 64 карточек; `validate_appstore_staging.py` проверяет метаданные и SHA-256 существующих изображений; `audit_editorial_all_locales.py` проверяет source-key/format/permission и формирует файл для редакторов. CI запускает проверки offline — обращение к сторонней переводческой службе в CI не требуется.

**ASO исходно:** [публичные 48 карточек 12 рынков](../../docs/ASO_PUBLIC_AUDIT_2026-10-26.md). **Apple Docs:** https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/ и https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications.
