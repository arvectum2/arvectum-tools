# Arvectum Tools Core — дорожная карта

## 29.10.2026 · Core — единая инженерная дорожная карта (актуальный срез)

### C0 / P0 — целостность репозитория и релизная дисциплина

- [x] Закрыты рабочие PR #164 (Pushkin), #165 (Ухват), #167 (ChickMark); основной `main` сохраняет нормальную историю и проверяется `git status`, Core pytest и GitHub CI. Две независимые задачи с физическими/старыми runtime условиями отдельно от готового `main`: PR #160 iOS17 (DRAFT) и PR #108 HealthKit QA (DRAFT / требуется решение о переносе тестового патча).
- [ ] После каждого нового изменения: объединять зелёные PR; fail/skip/pending не приравнивать к PASS; чистить только доказанно слитые, неиспользуемые ветки, не уничтожая worktrees, release refs или физические QA-артефакты.
- [ ] Единый fail-closed gate для схем хранения, миграций, backup/restore и UUID/ACK, включая cross-app deep links. Никакого сброса личных SwiftData, HealthKit, CloudKit, аудио или Shortcuts.
- [ ] Поддерживать CI по целевым платформам iOS/watchOS/Android, accessibility/Dynamic Type, iPad и локализации; не распространять iPad/Watch-тесты на приложения, не имеющие соответствующего клиента.
- [ ] Повторять App Privacy/SDK/ATT/permissions аудит для каждого изменения зависимостей и рекламы; не менять live декларации без отдельного поручения.

### C1 / P1 — локализация 12 → 50 пакетов интерфейса

- [x] Цель **50** зафиксирована в `core/localization/portfolio-locales.json`: Tier 1 = 20, Tier 2 = 20, Tier 3 = 10 (50 уникальных кодов, без дубликатов). Переводы не были объявлены завершёнными на все 50.
- [x] На 29.10 в исходниках всех четырёх активных приложений есть **12/50** полных по ключам языковых пакетов (48 пар app × locale): `en, ru, es, fr, de, pt-BR, pt-PT, it, ja, ko, zh-Hans, zh-Hant`. Они присутствуют во всех **10 iPhone/Watch/widget bundles**, где применимо. Core registry и UI smoke contracts синхронизированы с этим фактом; готовность означает структурную полноту, а не вычитку носителем или публикацию.
- [x] 29.10 · Начат Tier 1 на уровне одного продукта: `nl` для «Фото и PDF под размер» — полный каталог 161 UI строк + 2 InfoPlist разрешения, нативный XcodeGen bundle и отдельная Dutch XCUITest. Source coverage **49/200 app×locale пар**: Фото/PDF **13/50**, ChickMark/Pushkin/Ухват по **12/50**. Не считать `nl` завершённым по всему портфелю; будущая карточка Нидерландов и независимая языковая/физическая QA остаются открыты.
- [x] 29.10 · Dutch `nl` дополнительно подготовлен в PUSHKIN: 159 source-строк, `PushkinCopy` routing и множественное число, iPhone UI smoke. Срез **50/200 app×locale**, по 13 языков в Фото/PDF и Pushkin, по 12 в Ухвате/ChickMark. Физические Shortcuts и редактура носителем не пройдены; существующие публичные сборки не менялись.
- [x] 29.10 · Ухват/What? добавил `nl` во все **4 iOS/watchOS/widget bundles**, 246+6+6+5 строк и соответствующие InfoPlist; локаль интерфейса независима от языка распознавания речи. Матрица: Фото/PDF, PUSHKIN и Ухват по **13/50**, ChickMark **12/50**; всего **51/200** структурных app×locale source-пар. Нативный Watch/VoiceOver, независимая редактура и карточка `nl-NL` пока отдельно.
- [x] 29.10 · Dutch `nl` добавлен в ChickMark во все **4** bundles: iPhone 315 ключей, Watch 22, iPhone widget 16, Watch widget 5 + HealthKit usage strings; Core source coverage теперь **52/200 app×locale пар** — по **13/50** во всех четырёх активных iOS-приложениях. Это структурная готовность источников, не редакторский sign-off и не новый App Store релиз.
- [x] 29.10 · Начало индонезийской волны `id` в Фото/PDF: 161 UI ключ + 2 InfoPlist строки (включая ATT/ads), `id.lproj` включён через XcodeGen, отдельные iPhone photo/PDF/AXXXL smoke tests и содержательные тесты отказов/данных. Source-покрытие после этого изменения: Фото/PDF **14/50**, остальные по **13/50**, всего **53/200 app×locale**. Apple для Indonesia поддерживает Indonesian как дополнительный язык к основному English UK; отдельный metadata locale надо сверить в ASC, не заявлять загруженный релиз.
- [x] 29.10 · Индонезийский `id` теперь и в PUSHKIN: 159 строк, полный Shortcuts/privacy contract, `PushkinCopy` locale routing и множественное число. Source-матрица **54/200**: Фото/PDF и PUSHKIN по **14/50**, Ухват и ChickMark по **13/50**. Изменений пользовательских уведомлений нет; отдельная редактура и физическая приёмка остаются открытыми.
- [x] 29.10 · `id` добавлен в Ухват (iPhone/Watch/Phone Widget/Watch complication) с 246+6+6+5 строками и локальными permission strings. Тесты проверяют независимый язык транскрипции, media/ACK copy. Матрица: Фото/PDF, PUSHKIN, Ухват по **14/50**, ChickMark **13/50**, всего **55/200** source app×locale пар. Watch/physical/editorial/ASO release gates пока отдельно.
- [x] 29.10 · Индонезийский `id` готов как полный source package во всех **4** активных iOS приложениях и **10** соответствующих iPhone/Watch/widget bundles: ChickMark 315+22+16+5 ключей + HealthKit usage strings завершает волну. **14/50** языков у каждого, **56/200 app×locale** source-пар. Машинные и нативные тесты не заменяют редактуру носителем, физическую QA и отдельные Apple approvals.
- [x] 29.10 · Turkish `tr` source начат в Фото/PDF: полный iOS каталог 161 строк + 2 InfoPlist ключа, новый XCUITest для фото/PDF/Dynamic Type и machine audit. Фото/PDF 15/50; остальные 3 приложения 14/50: **57/200** app×locale source пар. Установлен только исходный draft; редактура носителем, физическая QA и региональная ASC карточка ещё открыты.
- [x] 29.10 · PUSHKIN добавлен Turkish `tr`: 159 source UI ключей, безопасность Kestirmeler/Shortcuts, routing, нативные тесты. Source coverage Фото/PDF и PUSHKIN **15/50**, Ухват и ChickMark **14/50**; 58/200 пар. Отдельные турецкие ASO/физические гейты открыты.
- [ ] **Волна 13–20 (Tier 1):** `hi, ar, id, tr, vi, nl, pl, th`; добавлять на каждом из четырёх iOS-приложений вместе с Watch/widgets, разрешениями, Siri/Shortcuts, уведомлениями и VoiceOver. Отдельно RTL для `ar` и множественные числа/шрифты для Indic.
- [ ] **Волна 21–40 (Tier 2):** `fa, ur, bn, pa, ta, te, mr, gu, kn, ml, uz, ms, fil, sw, ro, hu, cs, sk, el, he`; RTL, алфавиты, форматирование, локальные размеры/единицы и RTL-layout проверять на симуляторе и устройстве.
- [ ] **Волна 41–50 (Tier 3):** `ha, am, sv, da, fi, nb, bg, sr, hr, ca`.
- [ ] Для каждого нового языка: без английских заглушек, полный набор strings/InfoPlist/permissions/ошибки/Shortcuts/Watch/widgets, форматные ключи и plural tests, экранные XCUITest и accessibility, независимая редакторская проверка чувствительного текста, затем точечный релизный approval.
- [ ] Android Фото/PDF: существующие 9 source-языков поддерживать; расширение оставшихся 41 до 50 — после iOS/watchOS в соответствии с `deliveryPriority` реестра. Where? остаётся PAUSED.

### C2 / P1 — региональные карточки App Store и ASO

- [x] Baseline **64/64 карточки** в `core/appstore/staged-2026-10-26/{photo,pushkin,what,chickmark}.json`: по **16 locale-вариантов × 4 приложения**; подготовлены тексты, keywords, What's New и скриншоты. Публичные версии четырёх приложений уже подтверждены 28.10 (отдельная Apple read-only QA). Локализации metadata и языки интерфейса — разные счётчики.
- [x] A1 baseline: `core/tools/regional_aso_readiness.py` автоматически сверяет **4×16 = 64** country-specific C18 Apple Lookup наблюдения с отдельными staged-карточками/действительными source locales, выводит таблицу/JSON с обязательным `observed_utc`. Нет ложных выводов про live metadata и допустимые ASC локали; 3 структурных теста fail-closed. Более новый C19 ChickMark 1.5.3 не подменяется устаревшим наблюдением C18 1.5.2.
- [x] 29.10 · `nl-NL` Netherlands: второй отдельный source-only ASO draft добавлен для PUSHKIN; обе черновые карточки Фото/PDF и PUSHKIN проходят общий offline validator с закрытием upload gate. PUSHKIN description прямо раскрывает ограничения Apple Shortcuts, а iPad-снимки для неподдерживаемого iPad не заявляются. Реальные PNG и независимая вычитка ещё открыты.
- [x] 29.10 · Третий `nl-NL` App Store черновик добавлен для Ухвата/What? с ограничениями Watch ACK, обработкой медиа на устройстве и раздельным языком распознавания речи. Подготовлены только copy и план реальных iPhone/iPad снимков; validator запрещает fake screenshots/approval. Два прежних NL черновика и 64 существующих staged карточки не менялись.
- [x] 29.10 · Четвёртый отдельный `nl-NL` черновик готов для ChickMark: реальные HealthKit/водные разрешения, CloudKit/iCloud caveat, backup/delete, возможные объявления и 4 будущих экрана; validator контролирует 4 приложения, не позволяет пометить фиктивные PNG/APPROVED/ASC. Итого 4 NL copy drafts и 64 исходных staged карточки, но 0 новых live NL релизов.
- [x] 29.10 · Добавлен пятый locale expansion draft: Foto/PDF `ID → id` (Indonesia, дополнительный к English UK язык metadata); copy и 4 плана экранов, без изображений и публикации. Offline validator теперь контролирует и NL `nl-NL`, и Indonesia `id`; исходные 64 staged и 4 NL drafts не менялись.
- [x] 29.10 · Все индонезийские региональные copy drafts **4/4** подготовлены. Всего 8 новых metadata drafts (NL×4 и ID×4), без изображений, ASC upload и approval; offline validator блокирует фиктивные статусы, 64 исходных staged карточки сохранены.
- [x] 29.10 · Turkish Türkiye: отдельный `photo-tr.draft.json` для Фото/PDF, App Store locale **`tr`** подтверждён по официальному справочнику Apple. Offline validator/тесты требуют отсутствия фиктивных screenshots, ASC account state и approvals. Прежние 64 staged карточки, 4 NL и 4 ID черновика не затронуты.
- [ ] Установить целевую матрицу **регион/страна × поддерживаемый Apple metadata locale × приложение**. Для каждого целевого storefront — свой проверенный язык карточки и региональные title/subtitle/keywords/description/promotional text/What's New, три ключевых экрана, допустимые форматы устройств, языковые скриншоты с фактическим UI, юридические/документные ограничения, корректные ссылки на сайт/поддержку/privacy.
- [x] Проверен официальный список Apple: с **31.03.2026 App Store Connect поддерживает 50 metadata localizations**, однако это не тот же список, что наши 50 UI языков: различаются языки, региональные варианты и locale shortcodes. Первая новая страна NL → `nl-NL` подтверждена в справочнике Apple; подготовлен отдельный непубликуемый текстовый черновик Фото/PDF без скриншотов ([план](appstore/locale-expansion-2026-10-29/README.md)).
- [ ] Следующая волна регионов — после проверки перечня поддерживаемых App Store Connect metadata locales и mapping стран; **наши 50 UI языков не равны 50 локализациям Apple один-к-одному**. Не заводить фиктивные Apple-языки и не объявлять fallback региональным переводом. Там, где Apple не поддерживает отдельную локализацию карточки, документировать выбранный допустимый fallback и страны покрытия.
- [ ] Для каждой пары `app × locale × storefront`: машинные лимиты Apple и дедупликация keywords, редактура носителем, скриншоты iPhone/iPad только реально поддерживаемых устройств, ручная визуальная QA, audit URL/SDK/privacy, SHA и preflight. Отдельно замерять ASO impressions → product page views → first-time downloads → retention по данным ASC, не по предположениям.
- [ ] Новые binary/metadata/screenshot uploads, Store API mutations и review submission — только после отдельного согласия владельца на exact app/version/build/SHA. План и карточки в Git не являются разрешением на публикацию.

### C3 / P2 — общая адаптивность, интеграции и мониторинг

- [ ] Поддержка iPad/Split View/Stage Manager и современных форм-факторов там, где есть native-клиент; не считать симулятор физической приёмкой.
- [ ] Унифицированные безопасные локальные события «заметка Ухвата → разовое напоминание ChickMark» и совместимость deep links при отсутствии приложения.
- [ ] Логи/диагностика и backup только без приватного содержимого заметок, уведомлений, HealthKit и рекламных идентификаторов.
- [ ] Core и Growth: пер-региональная воронка Apple Analytics/ASO, отзывы и рекламные показатели — строго по проверенным аккаунтным данным.

[Оперативный подробный план языков и регионов](docs/CORE_50_LOCALES_AND_REGIONAL_ASO_2026-10-29.md) · [Единый реестр языков](localization/portfolio-locales.json) · [Матрица Source UI](localization/README.md).

---

**Актуальная сводка · 27.10.2026:** [портфельная дорожная карта — C17 отправлен в Apple, C18 остаётся после отправки](docs/ROADMAP_PORTFOLIO_2026-10-27.md). Все 4 C17 версии WAITING_FOR_REVIEW, AFTER_APPROVAL; это не публикация. Ниже — исторические контрольные точки.


C17 (27.10): получены 7 практических отзывов IndieAppCircle (4 в Arvectum/ceo + 3 в других ярлыках). Исправлены ChickMark custom groups, подсказка Uhvat transcription, international Pushkin starter apps, back-кнопка Фото/PDF. Проверены 64 локализованных release notes, кандидатные версии 1.0.4/1.0.3/1.1.2/1.5.3. Privacy рекламы проверена по встроенным manifest; ASC release gate остаётся.

C16 (27.10): публичный Apple Lookup для 16 стран × 4 приложений, live-версии Photo/PDF 1.0.3, Pushkin 1.0.2, Uhvat 1.1.1, ChickMark 1.5.2. App Store Connect read-only ещё не проверен. [C16](docs/ASO_C16_PUBLIC_STORE_QA_2026-10-27.md).

C15 (27.10): внутренняя языковая редактура 64/64 ASO-карточек, 24 переводные строки Photo/PDF и KO-формулировка Ухвата; 144 настоящих iPad маркетинговых композиций на 12 языках (192 региональных слота). Подтверждения физических устройств и публикации остаются открыты. [C15](docs/ASO_C15_EDITORIAL_ACCEPTANCE_2026-10-27.md).

C14 (27.10): в 45/64 ASO-карточках устранены точные повторы keywords из title/subtitle; зафиксированы P0 проблемы маркетинговой композиции iPad Фото/PDF и ChickMark. Релизный gate отклоняет публикацию до шести независимых приёмок. [C14](docs/ASO_C14_KEYWORDS_VISUAL_GATE_2026-10-27.md).

C13: [редактура 35 переводных ASO-карточек и проверка всех 64](docs/ASO_C13_LINGUISTIC_EDITORIAL_2026-10-27.md). Не является независимой вычиткой носителем.

[C12 — локализованная библиотека Ухвата, раскрытые напоминания ChickMark, исправление корейских ASO-текстов и локальная review-галерея](docs/ASO_C12_EDITORIAL_2026-10-27.md). 448/448 исходных региональных слотов покрыты, native-speaker/подписанные релизы остаются открытыми.

**C11 (27.10.2026):** подготовлена автоматическая нативная съемка iPhone и 13″ iPad для всех 12 языков UI, 64 ASO-комплекта; текущие проверки и фактическое покрытие — [C11](docs/ASO_NATIVE_CAPTURE_C11_2026-10-27.md). Новые живые App Store карточки не публиковались; физическая/редакторская QA всё ещё нужна.


## C10 — 26.10.2026 · редактура + все ASO-карточки

- [x] 64 полноформатных текстовых App Store черновика для 4 приложений × 16 поддерживаемых региональных локалей; 12 языков UI, 4 EN/2 ES региональных варианта. Проверки Apple metadata PASS.
- [x] Аудит 197 каталогов / 10 237 строк, 0 машинных ошибок; 4 155 риск-строк собраны в двуязычную редакторскую таблицу; исправлены KO смысловые ошибки.
- [x] Pushkin RU: 3 новых настоящих Simulator screenshot 1320×2868, 3/3 native UI PASS. Это пока не live App Store.
- [ ] Native-speaker и физическая QA, 433 отсутствующих native screenshot slots, новые IPA + точечное разрешение на ASC. [C10 акт](docs/EDITORIAL_ASO_C10_2026-10-26.md).

## C9 — 26.10.2026 · KO 4/4 и Apple ASO

- [x] 12/20 Tier 1 source-пакетов в четырёх iOS-приложениях; KO добавлен в Ухват и ChickMark (iPhone/Watch/widgets).
- [x] Core 57/57 PASS; native KO Ухват 15/15 и ChickMark 11/11 PASS. Корейский остаётся машинным черновиком.
- [x] Проверены 48 App Store карточек (4 приложения × 12 стран), реальный subtitle и скриншоты. [ASO-аудит](docs/ASO_PUBLIC_AUDIT_2026-10-26.md).
- [ ] Native-speaker и физическая QA; доработать метаданные и скриншоты до новых подписанных RC, затем отдельный per-release approval.

[Срез C9](docs/LOCALIZATION_C9_2026-10-26.md).


## 26.10.2026 · C8 — проверенный статус локализаций и релизов

- [x] 11/20 полных source-пакетов Tier 1 во всех 4 продуктах (pt-PT — draft); KO только Фото/PDF и Pushkin, итого 2/4.
- [x] Аудит ключей/placeholders PASS; 56/56 профильных тестов PASS; ранее зелёный CI PR #151 и кодового commit PR #152, **оба PR OPEN**.
- [ ] Дождаться итогового CI на самом новом commit PR #152: после документационного обновления часть jobs ещё выполнялась.
- [ ] Native-speaker/physical iPhone+Watch QA, новые подписанные IPA/SHA-256, отдельный Apple approval.
- [ ] После KO в Ухвате/ChickMark — следующие Tier 1 языки по очереди.

[Полная актуальная матрица](docs/LOCALIZATION_STATUS_2026-10-26.md).

## Release RC 26.10.2026

- [x] Restore Photo/PDF advertising consent, IDFA ATT prompt and analytics as previously deployed; no change to the live Apple privacy label.
- [x] Prepare versions Photo/PDF 1.0.3 (15) and ChickMark 1.5.2 (20).
- [ ] Test fresh binary, archive/sign/export and collect exact SHA-256. Owner per-build approval required for Apple uploads.


- [x] **26.10.2026 Фото/PDF системный AX 2/2 PASS** (фото + PDF, включая `textClipped`), плюс VoiceOver 2/2 PASS; финальный XCResult на Mac mini: `/Volumes/ArvectumSSD/Arvectum/qa/photo-a11y-icons-final-20261026/photo.xcresult`.

[**Оперативная дорожная карта 26.10.2026 — P0/P1 и блокеры**](docs/ROADMAP_LIVE_2026-10-26.md). Документы ниже сохраняют хронологию, но не всегда содержат финальный результат сегодняшних тестов.


## 26.10.2026 · C7 — Photo/PDF отзыв + ChickMark UX
- [x] VoiceOver 26.10 на Mac mini: Photo/PDF 2/2 + ChickMark 3/3 PASS; системный VoiceOver после тестов **выключен** и подтверждён через AppKit/Settings.

- [x] Отдельная ветка `feature/review-ux-photo-chickmark-20261026`: Photo/PDF (консервативная реклама/privacy disclosure, 3 новых visa/passport-пресета) и ChickMark (native ad в конце прокручиваемого списка, 3-экранный первый запуск).
- [x] Native targeted UI: Photo 3/3, ChickMark 5/5 PASS; Core 63/63, locale audit PASS; 20 ASO draft locales VALID, 12 новых screenshot-композиций RU/en-US/en-GB без Demo Ad.
- [x] Предыдущая 11-locale iOS GitHub UI matrix: 4/4 jobs SUCCESS.
- [ ] Перечитать настоящие SDK privacy manifests: AppMetrica AdSupport всё ещё declares tracking=true; нельзя объявлять app tracking-free, несмотря на отказ от ATT. Нужен отдельный SDK/legal review.
- [ ] Физические устройства offline; native VoiceOver/a11y дополнительный прогон ещё в процессе, App Store metadata/публикация не тронуты.

[Подробный QA](docs/PHOTO_CHICKMARK_REVIEW_QA_2026-10-26.md).


## 26.10.2026 · C6.4 — signing/preflight QA

- [x] Все четыре Release builds, подписанные iOS device xcarchive **4/4 PASS**, App Store IPA exports **4/4 PASS**; каждый IPA `codesign --verify --deep --strict` **PASS**, SHA-256 зафиксированы.
- [x] Локальные Store provisioning profiles для Main/Watch/Widget найдены; прежний blocker missing provisioning снят для offline-экспорта, без Apple Developer Portal изменений.
- [ ] **Не upload-ready**: Фото/PDF IPA `1.0.1 (13)` при публичной `1.0.2`, остальные версии/билды совпадают с текущими; нужны новые version/build и повторная подпись после редакторской/физической QA.
- [ ] GitHub full 11-language UI matrix запущен (run 40278441525), завершение не подтверждено. Apple upload/Review только с отдельным согласием на exact version/build/hash.

[Signed artifact report](docs/IOS_SIGNED_IPA_GATE_2026-10-26.md).


## 26.10.2026 · C6.3 — подтверждённая PT-PT/KO приёмка

- [x] Native iPhone UI: **10/10 PASS** — PT-PT 6/6 (4 apps), KO 4/4 (Фото/PDF и Pushkin).
- [x] Исправлена настоящая ошибка KO языка Pushkin (`PushkinCopy.text`): повторный KO UI 1/1 + Swift unit 1/1 PASS.
- [x] Core 63/63 PASS, 31 совпадение EN лексически классифицировано в явном allowlist, 0 новых необъяснённых совпадений.
- [ ] KO отсутствует для Ухвата/ChickMark, human editorial / физическая QA / Watch / VoiceOver / signing и полный CI остаются release gates.

[Акт native QA](docs/IOS_PTPT_KO_NATIVE_QA_2026-10-26.md).


## 26.10.2026 · KO — два частичных iOS-каталога

- [x] Для корейских исходных каталогов Фото/PDF и Pushkin добавлены независимые KoreanLocalizationUITests: синтетические экраны, без пользовательских данных/автоматизаций.
- [x] Ручная GitHub locale UI матрица обнаруживает корейские классы только там, где они существуют.
- [ ] Исполнить native UI Korean QA; What/Ухват и ChickMark ещё не переведены на KO. Для release нужны перевод, human proofreading и физический VoiceOver/Watch.


## 26.10.2026 · C6.2 — pt-PT Core registry и UI coverage

- [x] 11-й исходный пакет pt-PT добавлен в Core registry всех четырёх приложений, отдельные EuropeanPortuguese native UI smoke tests включены в ручную 11-язычную GitHub матрицу.
- [x] Исправлены дополнительные европейские португальские формулировки Pushkin/Ухвата/ChickMark.
- [ ] Новые pt-PT XCUITest ещё не выполнены; native speaker/VoiceOver/Watch и физическая приёмка открыты. Apple release только по отдельному согласованию.


## 26.10.2026 · Публичный RU Apple Lookup подтверждён

- [x] **Все четыре версии публичны**: Фото/PDF 1.0.2, Pushkin 1.0.2, Ухват 1.1.1, ChickMark 1.5.1.
- [x] **ChickMark категория Productivity** подтверждена Apple Lookup; прежняя задача на изменение категории закрыта.
- [ ] **Это старые уже опубликованные версии**: новые исходные zh-Hant/pt-PT/KO и исправления 26.10 в них не попали; для будущих версий отдельный release gate.
- [ ] Проверить отдельными способами установки/метрики/другие страны; Lookup не показывает количество скачиваний, build и аудит App Review.

[Apple RU Lookup](docs/APPLE_PUBLIC_LOOKUP_2026-10-26.md).


## 26.10.2026 · C6.1: QA и редактура портфеля

- [x] Zh-Hant XCUITest **6/6 PASS** (Фото/PDF 3; Pushkin 1; Ухват 1; ChickMark 1); все XCResult сохранены.
- [x] PT-PT редактура в 4 приложениях и Watch, структурный аудит PASS, Core **62/62 PASS**; детерминированный редакторский отчёт и регрессионные тесты.
- [x] **11/20 Tier 1 source packs** полные по ключам во всех 10 bundles (11-я pt-PT — черновик); KO только 2/4 приложений.
- [ ] Native-speaker review, физический VoiceOver/Watch/consent/upgrade; GitHub manual 10-language CI; provisioning и новые подписанные архивы.
- [ ] Apple read-only актуализация (предыдущие review сведения 24.10), отдельный release approval для каждого IPA. Прежний подписанный Фото/PDF IPA уже не содержит последние pt-PT изменения.

[Протокол QA](docs/IOS_ZH_HANT_NATIVE_QA_2026-10-26.md).


## 25.10.2026 · C6 — zh-Hant, первый пакет после девяти языков

- [x] Источники zh-Hant (Taiwan-oriented OpenCC s2twp draft) подготовлены для всех четырёх iOS-приложений, десяти bundles iPhone/Watch/widgets; ключи, placeholders, Siri и системные разрешения сохранены.
- [x] Разделены маршруты zh-Hans/zh-CN и zh-Hant/zh-TW/HK/MO в Pushkin, Ухвате, ChickMark; добавлены unit и XCUITest sources.
- [x] На этапе генерации Core localization audit и 46/46 unit PASS. [Протокол](docs/IOS_ZH_HANT_TIER1_DRAFT_2026-10-25.md).
- [ ] Native iOS/watchOS builds, Simulator UI, GitHub manual ten-language matrix, редактура носителем, физический VoiceOver/Watch/consent QA.
- [ ] Tier 1 сейчас **10/20 исходных пакетов**, включая zh-Hant draft; остальные hi, ar, pt-PT, ko, id, tr, vi, nl, pl, th. Android остаётся 9 исходных языков и 41 отложенным.
- [ ] Никаких Apple uploads/TestFlight/live metadata без явного отдельного согласия.



## 25.10.2026 - Pushkin CI simulator launch

- [x] Original GitHub red job traced to 129-second Xcode simulator app-launch timeout; other deletion UI and Swift unit tests passed.
- [x] Isolated prebooted CI Simulator, bounded retry and cleanup.
- [x] Mac mini independent 12/12 deletion regression PASS, exit 0.
- [ ] Confirm new CI on real GitHub xcode-27 runner before merging.
- [Evidence](docs/PUSHKIN_CI_SIMULATOR_LAUNCH_FIX_2026-10-25.md).

## 25.10.2026 - C5.8: ручной GitHub CI для 36 языковых UI-пар

- [x] Добавлен workflow_dispatch для 4 iOS-приложений, 30 XCUITest-классов, 36 app-locale сочетаний.
- [x] Отдельные iPhone-симуляторы в GitHub, Core-аудит, ограниченный retry и XCResult-артефакты без живых пользовательских данных.
- [x] YAML, 4 job entries, shell syntax и все test-class пути проверены; Core 46/46 PASS.
- [ ] Запустить один полноценный GitHub Actions manual run после объединения PR и проверить 4/4 jobs.
- [ ] Физические устройства/Watch/VoiceOver и языковая вычитка до релизов.
- [Акт](docs/IOS_NINE_LANGUAGE_MANUAL_CI_2026-10-25.md).


## 25.10.2026 - C5.7: 36/36 iOS language UI coverage
- [x] Main CI after #141-147: 8/8 PASS.
- [x] RU/EN baseline for four apps, FR Uhvat, ES ChickMark: 10/10 new XCUITest PASS.
- [x] All 36 app x 9 locale source UI smoke pairs now covered and Python-gated.
- [ ] Physical Apple Watch/VoiceOver/permissions/upgrade and native editorial QA.
- [ ] App Store upload only with per-version owner approval.
- [Evidence](docs/IOS_NINE_LANGUAGE_UI_MATRIX_2026-10-25.md).


## 25.10.2026 - C5: единая приёмка 9 языков

- [x] Сводный аудит девяти исходных языков, четыре iOS-приложения и 10 iPhone/Watch/Widget bundles.
- [x] 52/52 Core + 68/68 Swift unit + 60/60 translated UI = **180/180 PASS** на отдельном iPhone Simulator.
- [x] [Финальный C5 QA-протокол](docs/IOS_NINE_LANGUAGE_INTEGRATION_2026-10-25.md).
- [ ] Физический iPhone/Watch и VoiceOver, редактура носителями, GitHub main CI и отдельное App Store согласование.


## 24.10.2026 · C5.6 — упрощённый китайский ZH-Hans, язык №9 для iOS

- [x] Все 4 iOS-приложения и 10 iOS/Watch/Widget targets: **899 строк zh-Hans** в исходниках.
- [x] Системные InfoPlist, рекламные согласия, HealthKit и Siri; выбор zh-Hans/zh-CN в Pushkin, Ухвате и ChickMark с защитой zh-Hant.
- [x] Core девятиязычный аудит ключей и форматных параметров: **45/45 PASS**.
- [x] 6/6 iOS/watchOS сборок PASS; китайские ресурсы есть в собранных приложениях и расширениях.
- [x] Китайский UI 6/6 PASS (Фото/PDF 3, Pushkin 1, Ухват 1, ChickMark 1).
- [x] Swift unit 35/35 PASS: Pushkin 14, Ухват 12 после полного повторного прогона, ChickMark 9.
- [ ] Нативная китайская вычитка, физическая VoiceOver/Watch/consent QA перед релизом.
- [ ] iOS-first сохраняется; Android не расширять до приёмки.
- [ ] Ни один App Store upload не разрешён автоматически.

[Отчёт](docs/IOS_ZH_HANS_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · Core C5.5 — японский JA, восьмой язык в исходниках

- [x] Все 4 iOS-приложения и 10 iOS/Watch/Widget bundles: 899 японских строк.
- [x] Японские InfoPlist, реклама, HealthKit, Siri, разрешения; реальная JA-маршрутизация Pushkin/Ухвата/ChickMark.
- [x] Обязательный восьмиязычный Core gate 43/43 PASS.
- [x] **6/6 iOS/watchOS сборок PASS**, ресурсы JA проверены в реальных собранных приложениях и расширениях.
- [x] **6/6 японских UI PASS**, **32/32 Swift unit PASS** (Pushkin 13, Ухват 11, ChickMark 8).
- [ ] Профессиональная японская вычитка, физические Watch/VoiceOver/permission QA.
- [ ] Далее iOS-first: упрощённый китайский zh-Hans. Android без расширения.
- [ ] Никаких загрузок App Store без отдельного согласования.

[QA](docs/IOS_JA_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · C5.4 — итальянский (IT) для iOS/watchOS

- [x] Все 4 iOS-приложения и Watch/Widget bundles имеют исходные каталоги IT: 899 переведённых строк / 10 targets.
- [x] Итальянские InfoPlist, HealthKit, реклама/приватность, Siri AppShortcuts, выбор it/it-IT у Pushkin/Ухвата/ChickMark.
- [x] Core 7-язычный аудит ключей, подстановок и разрешений: **41/41 PASS**.
- [x] 6/6 iOS/watchOS Simulator unsigned builds PASS; реально собранные IT-ресурсы есть во всех 10 целях.
- [x] Итальянский iOS Simulator UI **6/6 PASS** (Фото/PDF 3/3, Pushkin 1/1, Ухват 1/1, ChickMark 1/1).
- [x] Native Swift XCTest **29/29 PASS**: Pushkin 12, Ухват 10, ChickMark 7.
- [ ] Профессиональная вычитка итальянского, физическая Watch/VoiceOver/permissions QA, отдельное согласование релизов.
- [ ] Следующая очередь iOS: JA и ZH-Hans. Android без новых языков.

[Акт проверки](docs/IOS_IT_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · C5.3 — pt-BR во всех iOS и watchOS

- [x] RU/EN/ES/FR/DE/PT-BR в исходниках всех 4 iOS-продуктов: 899 португальских строк, 10 bundles.
- [x] Системные InfoPlist, реклама/приватность, HealthKit и Siri AppShortcuts; региональное разрешение pt-BR в Pushkin, Ухвате и ChickMark.
- [x] Core 6-язычный аудит и подстановки 39/39 PASS.
- [x] Все 6 unsigned iOS/watchOS сборок PASS, pt-BR.lproj проверен внутри всех 10 продуктов/расширений.
- [x] pt-BR iPhone Simulator UI **6/6 PASS**: Фото/PDF 3/3, Pushkin 1/1, Ухват 1/1, ChickMark 1/1.
- [x] Swift XCTest pt-BR: Pushkin 11/11, Ухват 9/9, ChickMark 6/6 PASS.
- [ ] Профессиональная вычитка, физический VoiceOver/Watch/consent QA перед релизом.
- [ ] Следующая iOS-волна IT, JA, ZH-Hans; Android пока не расширять.
- [ ] Никаких новых App Store загрузок без отдельного подтверждения владельца.

[QA](docs/IOS_PTBR_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · C5.2 — DE для всех iOS и watchOS: исходники

- [x] У всех 4 активных iOS-приложений полные RU/EN/ES/FR/DE исходные каталоги: 10 bundles, 899 немецких строк в портфеле.
- [x] Pushkin 151, Ухват 248 и ChickMark 345 строк DE: добавлено 744 строки, включая Watch, iPhone widgets и watch complications.
- [x] Системные InfoPlist и Siri AppShortcuts; исправлены разрешение немецкого в PushkinCopy и CaptureBrand Ухвата.
- [x] Core unit 37/37 и locale/printf проверки PASS; unsigned сборки iOS всех трёх и watchOS Ухвата/ChickMark PASS.
- [x] Немецкие iOS Simulator smoke для Pushkin, Ухвата и ChickMark: **3/3 PASS**, Pushkin XCTest 10/10 и Ухват XCTest 8/8 PASS.
- [ ] Реальные Apple Watch/Widget UI, VoiceOver на устройстве, проверка длинных DE инструкций и редакторская вычитка.
- [ ] Следующая iOS волна: PT-BR, IT, JA, ZH-Hans. Android без дополнительных языков.
- [ ] Это НЕ App Store выпуск. Любая загрузка — только по отдельному подтверждению.

[Акт](docs/IOS_DE_PORTFOLIO_QA_2026-10-24.md).


## 24.10.2026 · C5.1 — немецкий iOS пилот

- [x] Фото/PDF iOS: DE как пятый реальный исходный язык (155 строк + InfoPlist); для остальных iOS-продуктов DE ещё не готов.
- [x] В Core добавлен регрессионный тест на полный немецкий каталог Фото/PDF и форматные параметры.
- [x] Немецкий de_DE Simulator UX: фото, PDF, AXXXL и кнопки согласия 3/3 PASS; Core unit 35/35 PASS. После скриншот-аудита сокращена обрезанная надпись Benutzerdefiniert до Eigene. [Акт](docs/IOS_GERMAN_PHOTO_QA_2026-10-24.md).
- [ ] Перенести немецкую локаль в Pushkin/Ухват/ChickMark с независимыми соответствующими UI/Watch/Widget переводами.
- [ ] Редакторская проверка DE, дальнейшая PT-BR/IT/JA/ZH-Hans волна, релизы по отдельному разрешению.


## 24.10.2026 · Приоритет C5: iOS-first

- [x] Машинный реестр локалей и unit-test фиксируют порядок iOS → watchOS → Android.
- [x] Исходная первая волна RU/EN/ES/FR подготовлена для всех четырех активных iOS-приложений (10 bundles).
- [x] Подготовлены fr_FR XCUITests для Фото/PDF: photo, PDF, accessibility AXXXL и consent.
- [x] Физически выполнен iOS 27.0 Simulator E2E: FR 3/3 и ES 3/3 PASS, Core 34/34 Python PASS. [Акт](docs/IOS_FIRST_FR_ES_UI_QA_2026-10-24.md).
- [ ] P0: UI/редакторская и физическая приемка французского языка; сохранить независимые release gates и безопасность.
- [ ] P1: DE, PT-BR, IT, JA, ZH-Hans для каждого из четырех iOS-продуктов (переход 4 → 9 языков, без фиктивных переводов).
- [ ] P2: довести iOS до Tier 1 (20), затем Tier 2 (20) и Tier 3 (10).
- [ ] Android: 41 новая локаль отложена; продолжать исправления и CI девяти действующих исходных пакетов.

## 24.10.2026 · C5 — четыре общих каталожных языка iOS

- [x] У всех четырёх активных iOS-приложений есть RU/EN/ES/FR на уровне исходников (всего 10 bundles).
- [x] Photo/PDF FR: 155 интерфейсных переводов и InfoPlist; структура/placeholder проходят локализационный аудит.
- [x] Добавлен unit-test на присутствие базовых языков во всех iOS bundles.
- [ ] Photo/PDF FR требует редакторской проверки, fr_FR UI, VoiceOver и физической приёмки. Не опубликован.
- [ ] Android Фото/PDF: 9 из 50 плановых пакетов в исходниках, ещё 41 и редактура/физическая QA открыты.
- [ ] Остальные iOS-языки по плану 20/20/10 после стабилизации первой волны.

Детали: localization/README.md. Новая работа в feature/photo-fr-localization-20261024, публичная Фото/PDF — 1.0.2.


## 24.10.2026 · Консолидированный статус (последнее уточнение)

- [x] **Pushkin 1.0.2 (6)** — отправлена на App Review; WAITING_FOR_REVIEW, автоматическая публикация AFTER_APPROVAL. [Акт](../pushkin/docs/PUSHKIN_1_0_2_APP_REVIEW_SUBMISSION_2026-10-24.md).
- [x] **Фото/PDF 1.0.2** — **уже одобрена и опубликована**, по подтверждению владельца 24.10; старую задачу «дождаться App Review» считать закрытой. Внешнюю датированную проверку витрины ведёт Growth.
- [x] **Ухват 1.1.1 (9) и ChickMark 1.5.1 (19)** — App Review WAITING_FOR_REVIEW, AFTER_APPROVAL; не считать публичными до READY_FOR_SALE. [Акт](docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md).
- [x] Общая архитектура, адаптивная вёрстка, не блокирующий App Store update prompt, дизайн-токены и 4-язычная база интегрированы в код; опубликованная версия каждого приложения проверяется отдельно.
- [ ] **Core P0:** проверить независимый статус Apple после review, version/update prompt в физическом обновлении и сохранность личных данных, с отдельным разрешением на *каждый следующий* upload/metadata.
- [ ] **Core P1:** app-specific physical VoiceOver, iPad/Duo, Watch/HealthKit/Files/Photos/РСЯ gates остаются у продуктовых владельцев; общий Core не подменяет эти проверки.
- [ ] **Core P2:** Android: 41/50 языков ещё требуют работы; Where?, SmartSearch и Growth Agent не активированы.

[Единая матрица статусов](PORTFOLIO.md) · [Актуальная очередь](EXECUTION_PLAN.md). Следующие датированные блоки сохраняются как история; в частности прежний пункт о Фото/PDF «WAITING_FOR_REVIEW» ниже **устарел**.


- [x] 24.10.2026: PUSHKIN 1.0.2(6) four locales RU/EN/ES/FR, signed IPA and Apple review WAITING_FOR_REVIEW, AFTER_APPROVAL. [Record](../pushkin/docs/PUSHKIN_1_0_2_APP_REVIEW_SUBMISSION_2026-10-24.md).


- [x] 24.10.2026: Ухват 1.1.1(9) и ChickMark 1.5.1(19) отправлены в App Review; оба WAITING_FOR_REVIEW и AFTER_APPROVAL. [Акт](docs/FOUR_LANG_APP_REVIEW_SUBMITTED_2026-10-24.md).


- [x] **24.10.2026: два 4-язычных IPA подписаны.** Ухват 1.1.1(9), ChickMark 1.5.1(19), RU/EN/ES/FR в 8/8 bundle, PR #138/139 merged. [Акт](docs/FOUR_LANGUAGE_RELEASE_CANDIDATES_2026-10-24.md). До загрузки требуется явное разрешение на конкретные версии.


## 24.10.2026 — актуализированная очередь


- [x] Фото/PDF 1.0.2(14) в Apple App Review: WAITING_FOR_REVIEW, AUTO AFTER_APPROVAL. [Акт](../photo-pdf-to-size/docs/appstore/RELEASE_1_0_2_SUBMITTED_2026-10-24.md).
- [x] Ухват PR #137 слит после 20/20 CI PASS: 32f13ad.

- [x] **Ухват, T24-02:** реализован честный поясняющий статус асинхронной доставки Watch в диагностике iPhone (RU/EN/ES, 1/1 unit PASS). Отдельные CI и физический UI QA — открыты. [Акт](../what/docs/WATCH_BACKGROUND_DELIVERY_UX_2026-10-24.md).

- [x] `main` / CI на HEAD `319bca9` проверены; ранее выполненные hardware regression тесты и XcodeGen guard остаются закрытыми.
- [x] **24.10 физический замер:** цикл iPhone QA active → background → active прошёл, 38 событий; Background Refresh=available, Low Power=true, protectedData=true, WCSession activated. Следующий этап — анализ задержанной доставки Ухвата.
- [ ] **Затем:** не закрытые физические UI/доступность/HealthKit/Photos/РСЯ по четырём приложениям; сайт PR #15 готов по CI, но не опубликован.
- [ ] **Отложено:** 41 Android язык, Where?, SmartSearch и Growth Agent. Новые App Store релизы и сайт — только по отдельному разрешению.

[Исполнимая дорожная карта на 24 октября](docs/DAILY_EXECUTION_2026-10-24.md).

## 22.10.2026 — дизайн, локализации и защита транскрипций объединены в main

- [x] **Интеграция завершена:** merge `f4f02d1` объединил D0–D4.6, выполненные локализации L0–L4 и защиту транскрипций Ухвата. Первая синхронизация GitHub/GitVerse — `8603c8d`. Это исходники, не публичные App Store версии.
- [x] **Контрольная проверка:** архитектура/lockfiles/dependencies PASS, Core SwiftPM 21/21, Python 40/40 и локализации PASS; CI GitHub проверяется отдельно. [Акт и следующие блокеры](docs/PORTFOLIO_MAIN_HANDOFF_2026-10-22.md).
- [ ] **Следующая очередь:** P0 физическая приёмка и защита данных Ухвата (L4.17b–L4.19b), затем оставшиеся app-specific UX/доступность и переводы 41/50 Android локалей. Where? остаётся на паузе. Релизы — только после отдельного согласования.

## 21.10.2026 — Актуальный остаток работ (без релиза)

- [x] **22.10 · Физический QA:** отдельный iPhone 13 QA app, 18/18 PASS (3 FileProtection, 5 recovery UI, 5 fault checkpoints, 5 AXXXL UI), 0 FAIL. Аппаратные reboot/ENOSPC/Watch offline/VoiceOver открыты. [Акт](../what/docs/PHYSICAL_FILE_PROTECTION_RECOVERY_2026-10-22.md).

- [x] **22.10 · Физический AXXXL:** iPhone 13, заполненная синтетическая библиотека; исходный аудит 3/4 PASS с 5 clipping, после правки RU/ES audit **2/2 PASS**, обычный UI 4/4 PASS, последовательный AX editor+RU+ES 3/3 PASS. [Акт](../what/docs/PHYSICAL_AXXXL_IPHONE_LIBRARY_2026-10-22.md).

- [x] **22.10 · Watch file-receive storage gate на физическом iPhone:** 15/15 XCTest PASS (первый адресный 3/3); неверный AAC/metadata без ACK, replay/deleted UUID безопасны, 24 UUID после relaunch. **Реальный Watch background WCSession OPEN** из-за тайм-аута CoreDevice. [Протокол](../what/docs/PHYSICAL_WATCH_INBOUND_GATE_2026-10-22.md).

- [x] **22.10 · iPhone AAC FileProtection FIX:** на физическом iPhone доказан баг наследования NSFileProtectionNone из WCSession temp в долгоживущий AAC; установлена защита staging перед commit, index protected, legacy index migration без изменения байтов. **95 XCTest, 0 FAIL, 3 expected SKIP** после исправления. Старые AAC/MOV и reboot-unlock OPEN. [Протокол](../what/docs/PHYSICAL_WATCH_AUDIO_FILE_PROTECTION_2026-10-22.md).

- [x] **22.10 · Legacy media protection / backup policy:** физический iPhone 13: миграция прежних AAC/MOV без переписывания контента, защита нового видео и незавершённых VideoCaptures; 125 regression PASS (3 skips) плюс recovery 18/18 PASS. Пользовательский backup сохраняется через iOS Application Support; reboot/PhoneCaptures/реальный Restore остаются OPEN. [Протокол](../what/docs/PHYSICAL_LEGACY_MEDIA_BACKUP_2026-10-22.md).

- [x] **22.10 · PhoneCaptures защищены:** физический iPhone 13, **132 XCTest, 0 FAIL, 3 expected SKIP**; аварийные AAC+JSON защищаются до микрофона, прежние копии мигрируют метаданными без потери. [Протокол](../what/docs/PHYSICAL_PHONECAPTURES_PROTECTION_2026-10-22.md).

- [x] **22.10 · Watch → iPhone cold-background физически PASS:** 1 QA AAC доставлен через реальный WCSession при остановленном iPhone QA; Watch исходник удалён после ACK. Второй прогон задержан до foreground — **повторяемость background OPEN**. [Протокол](../what/docs/PHYSICAL_WATCH_BACKGROUND_WCSESSION_2026-10-22.md).

- [x] **22.10 · Аудит уже выполненных Watch тестов:** реальные radio-offline 3 записи, частичный reboot и два коротких без iPhone UI были ещё 13.10; физический lost ACK закрыт 19.10. Обычный iPhone background при неизменном PID задерживает доставку до foreground; Watch AAC и .ack очищены штатным journal reconcile после перезапуска QA. [Актуальная матрица](../what/docs/PHYSICAL_WATCH_ACCEPTANCE_DEDUP_2026-10-22.md).

- [x] **22.10 · WatchConnectivity delivery latency измерена:** физический iPhone 13/Watch SE, маршрут transferFile (Watch reachable=false), watch-side completion 0.328 с; iPhone didReceive спустя 170.883 с при foreground, commit и ACK быстрые. [Протокол](../what/docs/PHYSICAL_WATCH_WCSESSION_ROUTE_TIMING_2026-10-22.md).

- [ ] **24.10 · Условия фона iPhone:** QA-only лог Background Refresh/Low Power/protected data/scene phase/WCSession собран и установлен, но запуск отказал из-за блокировки iPhone (RequestDenied: Locked). После обычной разблокировки нужен один замер без записи аудио. [Протокол](../what/docs/WATCH_BACKGROUND_WAKE_POLICY_QA_2026-10-24.md).

- [x] **24.10 · What.xcodeproj синхронизирован с XcodeGen:** после добавления пропущенных исходников обычная iPhone/watchOS сборка без подписи PASS; в CI добавлен контроль Swift source membership в project.pbxproj, устойчивый к разным форматам XcodeGen. [Протокол](../what/docs/WATCH_BACKGROUND_WAKE_POLICY_QA_2026-10-24.md).

### P0 · Ухват — доведение до физической приёмки
- [x] **L4.17a · Пользовательский экран восстановления:** в настройках библиотеки появился отдельный экран с предпросмотром состояния хранилища и числа расшифровок в последней пригодной резервной копии. Восстановление только по отдельному подтверждению; здоровый/отсутствующий основной каталог не заменяется, пустая или повреждённая копия недоступна, удалённые UUID не возвращаются. RU/EN/ES iPhone 228 ключей, тестовая синтетическая фикстура не касается реальных файлов. Xcode iPhone Simulator 67 PASS, 3 SKIP, 0 FAIL (23:01), Python 38/38 PASS.
- [x] **L4.17b, simulator subset:** отдельный Debug synthetic XCUITest прошёл Cancel → explicit Restore → healthy status → success alert на iPhone 17 Pro; AXXXL-кнопка и системное предупреждение исправлены. [Акт владельца](../what/ROADMAP.md). Дополнительно 22.10: пять XCUITest на синтетических данных **5/5 PASS** — Cancel/confirm, missing/corrupt/empty backup и исправный основной каталог; в небезопасных состояниях CTA восстановления не показывается. **Физический iPhone/iPad/VoiceOver и реальная пользовательская файловая система остаются OPEN**; не считать L4.17b полностью закрытым.
- [x] **L4.18a · FileProtection в коде Ухвата:** добавлены защищённые атомарные записи transcripts.json, transcripts.backup.json и deleted-recordings.json; старые файлы мигрируются без перезаписи содержимого, ошибка миграции блокирует запись. iOS Debug build PASS; Python 39/39 PASS; iPhone Simulator XCTest **67 PASS, 6 SKIP, 0 FAIL** (23:24). Три аппаратных проверки защиты пропущены, поскольку симулятор не возвращает NSFileProtectionKey.
- [ ] **L4.18b · Физический iPhone, частично 22.10:** отдельно установленный QA-бандл: 3/3 аппаратных XCTest PASS (NSFileProtectionKey transcript/backup/tombstone, миграция synthetic legacy-файлов без изменения байтов). Первая разблокировка после reboot, старые личные файлы, Watch background, AAC/MOV и остальные индексы OPEN. [Акт](../what/docs/PHYSICAL_FILE_PROTECTION_RECOVERY_2026-10-22.md).
- [x] **L4.19a · Тестирование прерываний записи расшифровок:** добавлены три контрольные точки только в Debug (перед сохранением резервной копии, после неё и после записи основного JSON). Пять новых XCTest на синтетических временных репозиториях проверяют старое состояние до записи копии, доступность основного файла после остановки между копией и основным JSON, повторное успешное сохранение, автоматическую расшифровку с повторной доставкой и удаление без восстановления через поздний Watch UUID. После основной записи текст сохраняется даже при ошибке на возврате. Xcode Simulator: **72 PASS / 6 SKIP / 0 FAIL**, Test-WhatIOS-2026.10.21_23-56-45-+0300.xcresult; Python **40/40 PASS**, i18n audit PASS. Оригинальное аудио остаётся неизменным.
- [ ] **L4.19b · Аппаратные сбои, частично 22.10:** 5/5 XCTest PASS на физическом iPhone с Debug checkpoint-исключениями, без потери тестовых аудио/текста. Реальный OS kill/power-loss, ENOSPC, locked-device availability и восстановление после аппаратной ошибки OPEN; не заполнять личный iPhone.
- [ ] **P0 · Хранилище:** проверить файлы медиа и индексов, полное удаление, решение о системных резервных копиях и испытания на сбой между атомарными записями.
- [ ] **P0 · Реальные устройства:** iPhone/Watch запись и подтверждение доставки/ACK, сохранение и повторное открытие аудио/видео, переключение камер, системные разрешения, синхронизация и фон.
- [ ] **P0 · Accessibility:** VoiceOver на настоящих iPhone/Watch, Switch Control/AXXXL на оставшихся модальных экранах, iPad multitasking, пользовательское восстановление.

### P1 · Остальные приложения и единый Core
- [ ] Android Фото/PDF: режимы Pixels/Passport/PDF, неподготовленные входные файлы, экспорт с физического устройства, 200% шрифты, TalkBack и маленькие экраны.
- [ ] iOS Фото/PDF, Pushkin, ChickMark: независимая приёмка целевых устройств, системных разрешений, уведомлений/Shortcuts, real-media и accessibility.
- [ ] iPad Split View/Stage Manager, iPhone Duo lifecycle и приёмка AdaptiveLayout; остальные дизайн-токены перенести после review.
- [ ] Независимый UX/code review и релизная матрица для каждого приложения.

### P2 · Языки, экспериментальные функции, решения владельца
- [ ] Android Фото/PDF: ещё 41 из 50 запланированных языков; остальные iOS-языки по уровням 20/20/10 и редакторская проверка, включая RTL/CJK/числительные.
- [ ] Runtime-локализация динамических ошибок, permission dialogs, Shortcuts и системных строк всех продуктов.
- [ ] Экспериментальный SmartSearch не включать в навигацию до продуктового решения, RU/ES перевода и QA модели.
- [ ] Where? оставлен на паузе.
- [ ] Реальные TestFlight/App Store/Google Play релизы, merge в main, storefront metadata — только по отдельному явному разрешению владельца.

## 20.10.2026 — Последовательность «сначала дизайн, потом локализации»

**Рабочая feature-ветка:** feature/portfolio-design-i18n-20261020 на ArvectumSSD (не main). [Протокол](docs/PORTFOLIO_DESIGN_I18N_2026-10-20.md).

- [x] **D4.6 → i18n:** объединены принятые изменения дизайна D0–D4.6 с веткой реестра 50 локалей, без обновлений публичных сборок; Xcode-проект Пушкина регенерирован из project.yml для разрешения конфликта.
- [x] **L0:** манифест 50 локалей, английский fallback, экспорт исходных строк, проверки ключей/placeholder и CI-гейт; английские базовые каталоги Pushkin/Ухват. Это не 50 выполненных переводов.
- [x] **L1/Android Photo:** английский каталог по умолчанию + русский; 93 ключа и Compose UI, размеры и ошибки через ресурсы. assembleDebug + testDebugUnitTest PASS, Python audit PASS.
- [x] **L2.1 / локализация исходников:** инструмент теперь извлекает прямые ключи pc(...) Пушкина; его английский базовый каталог увеличен с 81 до 151 ключа (+70), включая форматируемое название группы. Python-тесты проверяют реестр, placeholders, devRegion и обнаружение динамических строк.
- [x] **L2.2 / корректные числа:** Ухват теперь различает 0/1/2/5/11/21 заметку в RU и singular/plural в EN; Пушкин форматирует «Группа %d» как единый локализуемый шаблон, вместо конкатенации английского/русского заголовка с числом.
- [x] **L2.3 / реестр рисков:** инвентаризация динамических SwiftUI строк сокращена с 17 до **5** выражений — это простые числовые показатели ChickMark. Остальные вычисляемые строки требуют дополнительной UX/QA проверки.
- [x] **L2.4 / RU-каталоги iOS:** Pushkin получил ru.lproj на 151 строку; Ухват — четыре RU-каталога: iPhone 204, Watch 6, виджет 6, complication 5. XcodeGen обновил проекты; ресурсы подтверждены внутри собранных артефактов. Это не означает редакторскую и физическую приёмку.
- [x] **L2.5 / динамические строки:** форматы RU/EN с параметрами для ошибок видео и транскрипции, поиска, Watch и VoiceOver Ухвата; аудит синхронизации RU каталогов и встроенных переводов. Фото/PDF: исправлены склонения страниц и четыре составные подписи. После интеграции iOS сборки 4/4 PASS, направленные XCTest Фото 1/1 и Ухват 4/4; Python 8/8.
- [x] **L2.6 / ChickMark auto-languages:** вместо жёсткого RU/EN/ES список языков в настройках формируется по полным каталогам iOS bundle (паритет ключей с EN). Fallback EN для неподдерживаемого системного языка FR/JA/HI, автовыбор ES/RU; новые готовые языки появляются без правки Swift. iOS build и LocalizationTests 4/4 PASS. Новых переводов ChickMark нет.
- [x] **L2.7 / инвентаризация direct RU/EN bypass:** обнаруживаются прямые тернарные условия isRussian / language == ru, которые раньше обходили испанский каталог Ухвата. Исключение — сознательно двуязычный бренд Ухват/UhWhat?. Регрессионный тест и аудит: Python 16/16 PASS; текущих дополнительных веток не выявлено.
- [ ] **L2:** дополнить реальные динамические шаблоны, разрешения, уведомления/Shortcuts и источники каждого iOS-продукта; конвертировать инвентаризацию в проверенные runtime translations, а не только каталог ключей.
- [x] **L3.1 / первая рабочая локаль:** Android Фото/PDF получил черновой испанский каталог на все 93 ключа (UI, ошибки, переменные размеры файлов). Структурная проверка RU/EN/ES и Gradle assembleDebug + testDebugUnitTest PASS; для длинных переводов режимы и CTA адаптированы под перенос строк, повторная сборка PASS; физическая UX QA и языковая вычитка открыты.
- [x] **L3.2 / iOS Фото/PDF ES:** 155 испанских строк интерфейса и 2 InfoPlist-разрешения; XcodeGen собрал их в iOS bundle, Simulator build PASS, живой экран согласия на рекламу визуально проверен (все действия доступны). Два E2E UI-теста (обработка фото и PDF на es_ES) PASS 2/2; длинные строки и правовые тексты требуют редакторской проверки.
- [x] **L3.3 / Android Foto pt-BR:** добавлены 93 перевода для бразильского португальского, включая ошибки и параметры форматов. Пакет присутствует в собранном APK (aapt2), Gradle assembleDebug + testDebugUnitTest PASS, форматный аудит PASS. Языковая вычитка/реальные устройства остаются на очереди.
- [x] **L3.4 / Android FR:** добавлен французский каталог на 93 строки, ошибки, соглашения единиц и форматируемые параметры. Проверена сборка APK и ресурсы через aapt2; Gradle assembleDebug и testDebugUnitTest (6/6) PASS, структурные Python-тесты 11/11 PASS. Французская редакторская/UX вычитка на реальном Android пока открыта.
- [x] **L3.5 / Pushkin ES iOS:** 151 испанская строка и runtime-подключение настоящего каталога ES к PushkinCopy, RU/EN без изменения; 1/2 aplicaciones; неизвестный язык → EN. XcodeGen, Simulator build, plutil и unit-тесты 2/2 PASS; скриншот подтверждает испанскую навигацию. первоначально прерванный UI-тест позже исправлен и пройден 1/1 (L4.3). Редакторская и физическая приёмка открыты.
- [x] **L3.6 / Ухват ES, вся линейка:** 213 строк iPhone, 6 Watch, 6 iPhone widget, 5 watch complication — всего 230 ES ключей. Настоящий runtime CaptureBrand (ES Speech → UI, шаблоны и 0–2 notas, неизвестные системные языки → EN). На реальном симуляторе найдены и исправлены 9 прежде не извлекавшихся исходных RU/EN фраз главного экрана/VoiceOver. Удалена надпись о прежнем английском интерфейсе. Все 4 ES bundles в сборке; iOS build PASS, Swift XCTest 5/5, Python 14/14, XCUITest ES home + AXXXL 2/2 PASS, скриншоты до/после.
- [x] **L3.7 / Android Фото/PDF DE:** 93 немецких перевода (UI, ошибки, размеры, Gosuslugi и placeholders), EN fallback сохранён. Android Gradle assembleDebug и testDebugUnitTest PASS (6/6 JVM, выполнено из кеша), AAPT2 подтверждает настоящие DE ресурсы в APK; Python audit 16/16 PASS. Вычитка, Android device QA остаются открытыми.
- [x] **L3.8 / Android Фото/PDF IT:** добавлены 93 реальные итальянские строки (форматы, файлы, размеры, сообщения ошибок, Gosuslugi); Android Gradle assembleDebug + testDebugUnitTest PASS (6/6 JVM), AAPT2 подтвердил IT-ресурсы внутри APK. Проверки локализации 17/17 PASS. Редакторская вычитка и Android-device QA открыты.
- [x] **L3.9 / Android Фото/PDF NL+PL:** подготовлены по 93 нидерландские и польские строки с нативными ресурсами и форматами; offline Gradle assembleDebug + testDebugUnitTest PASS (6/6 JVM), AAPT2 подтвердил NL и PL внутри собранного APK; общий локализационный аудит Python 19/19 PASS. Нативная редактура и визуальная проверка Android остаются открытыми.
- [x] **L3.10 / Pushkin FR iOS:** дополнен четвёртый каталог EN/RU/ES/FR: 151 реально переведённая французская строка; PushkinCopy подключает fr.lproj по системному языку, количество приложений 1 application / 2 applications. XcodeGen проект обновлён, iOS build и целевой Swift test PASS, французский UI XCUITest навигации 1/1 PASS (15:15, подтверждено xcresult), Python-проверки локализаций 20/20 PASS. Редакторская вычитка FR, другие экраны и физическая доступность ещё открыты.
- [x] **L3.11 / ChickMark FR iOS/watchOS:** 345 французских строк во всех четырёх компонентах — iPhone 302, Watch 22, виджет iPhone 16, виджет Watch 5; отдельно FR InfoPlist-разрешения Santé d’Apple на iPhone и Watch. Язык автоматически появляется в настройках только при комплектном каталоге. Исправлены потенциально неверные формы «1 jours / 1 semaines» через нейтральные шаблоны. iOS Simulator build PASS, Swift LocalizationTests 5/5 PASS, UI XCUITest создания привычки FR 1/1 PASS, Python localization 21/21 PASS, ресурсы всех четырёх targets реально внутри сборки. Перевод — черновой; носитель языка, watchOS на устройстве, физический VoiceOver и весь device matrix остаются открытыми.
- [x] **L3.12 / Android экспорт — имя файла по языку:** реальный E2E выявил русское имя на английской UI. Убраны 3 захардкоженных русских суффикса из MainViewModel; для EN/RU/ES/PT-BR/FR/DE/IT/NL/PL добавлены по 3 строки в export_filenames.xml; 96 Android строк/локаль. Gradle assembleDebug + testDebugUnitTest PASS (9/9), Python 29/29 PASS. Повторный Android16 GUI E2E **7/7 PASS**, имя в SaveDocument и Downloads 19-compressed.jpg вместо русского, размер 479 169 байт. Редакторская вычитка и другие платформы открыты.
- [x] **L3.13 / Ухват — язык интерфейса отдельно от распознавания:** RU/EN/ES интерфейс теперь определяется настройкой языка iOS/конкретного приложения, а выбранный язык on-device диктовки остаётся только настройкой SFSpeechRecognizer. В меню есть локализованная ссылка на системные настройки iOS для изменения языка приложения. Переименование выбора в Speech recognition language; 3 заголовка Today/Yesterday/Earlier впервые локализованы в ES (Hoy/Ayer/Anteriores). Каталоги iPhone 217/217 RU/EN/ES, Watch/виджеты без изменений. iOS Simulator focused Swift + XCUITest **10/10 PASS**, включая ES UI + EN speech и RU UI + EN speech; Python **30/30 PASS**. Перед выпуском проверить привыкание существующих пользователей: ранее язык диктовки управлял и интерфейсом. Watch/iPhone physical VoiceOver остаются открытыми.
- [ ] **L3:** 41 оставшийся язык Android; остальные языки iOS по уровням 20/20/10; редакторская проверка перевода, числовых форм, RTL, CJK, VoiceOver и Dynamic Type перед релизом.
- [x] **L4.1 / ES iOS AXXXL, навигация:** воспроизведено реальное усечение названий режимов и пресетов на максимальном Dynamic Type; режимы переведены на сетку 2×2 с полными названиями и одинаковыми высотами, пресеты — на две колонки, импорт Фото/Файлы — на отдельные строки. Повторный Simulator build PASS, es_ES XCUITest 3/3 PASS (фото, PDF, AXXXL сетка); до/после подтверждены скриншотами. Полная AXXXL и языковая приёмка остаются в L4.
- [x] **L4.2 / ES Ухват AXXXL, главный экран:** найден перенос внутри «Texto» и чрезмерная высота видео-кнопки при максимальном системном шрифте; ограничена типографика только компактных действий, основной текст остаётся крупным. Симулятор подтвердил экран после исправления; XCUITest 2/2 PASS. Системный размер шрифта возвращён в large. Полная физическая VoiceOver и AXXXL-проверка других экранов всё ещё открыты.
- [x] **L4.4 / Android FR/NL/PL визуальный smoke:** Android 16 эмулятор small_phone, debug APK установлен, реальные локали FR/NL/PL через cmd locale, скриншоты FR/NL/PL получены. FR/PL в обычном режиме читабельны. В NL найден разрыв слова в переключателе; режимы перестраиваются 3/2/1 колонки по измеренной ширине переведённого текста. Проверено NL/PL скриншотами. Android Gradle 9/9 JVM PASS (3 новых регрессионных теста).
- [x] **L4.5 / Android 160% text:** воспроизведено частичное перекрытие CTA Foto kiezen при системном шрифте 1.6x; добавлен вертикальный scroll для выбора/результата, скрытие декоративного footer при fontScale >= 1.3. Повторная сборка PASS, NL screenshots top/bottom после свайпа: кнопка и сообщение о локальной обработке полностью доступны. UI проверен на эмуляторе, без TalkBack/физических устройств.
- [x] **L4.6 / Android image-engine E2E (Debug):** в отдельном Debug source set создан ImagePipelineQaReceiver, доступный только отправителю с android.permission.DUMP (adb shell); в release merged manifest отсутствует. На Android 16 Emulator проверен реальный производственный движок, синтетический PNG 900×700 / 2 199 482 байт → JPEG ≤500 000 байт (479 009), изменение до 400×311, паспорт 620×797/450 DPI, сохранение и повторная декодировка 3/3. Машинный отчёт android-pipeline-qa-result-final.json PASS, offline Gradle build + 9/9 JVM PASS, Python 24/24 PASS. Добавлен повторяемый tools/qa_image_pipeline_emulator.sh; его отдельный запуск через RDC прервался до отчёта, поэтому это не дополнительный PASS. **Системный Photo Picker + сохранение позже пройдены в L4.8.**
- [ ] **L4 / Android полная приёмка:** Photo Picker → 500 КБ → SaveDocument на Android 16 Emulator пройден (L4.8) на синтетическом PNG; остальные режимы/диалоги, 200%+ шрифты, TalkBack, реальные фотографии/нештатные медиаформаты, физические Android и вычитка языков пока не пройдены.
- [x] **L4.7 / Android Photo Picker → импорт → пресет:** настоящий Android 16 Photo Picker: Choose photo → синтетическая PNG → Done → Compose показывает 900×700 px / 1,84 MB. Выбран 500 KB, интерфейс отображает предупреждение PNG→JPG, действие Compress to 500 KB нажато. Доказательства: screenshots/UI XML/log на ArvectumSSD. Это не подтверждает завершение компрессии через UI.
- [x] **L4.9 / Ухват RU/EN/ES диагностика:** устранены устаревшие XCUITest, которые ожидали переключение визуальной локали вместе с распознаванием. Реальный экран диагностики и меню тестируются под RU/EN/ES без смены SpeechRecognizer; отдельный тест RU интерфейс + EN диктовка подтверждает независимость и сохранение визуальной локали после перезапуска. Ссылка в настройки iOS проверена, сам Settings не открывался. iPhone 17 Pro Simulator — **10/10 PASS**, xcresult 17:46, без изменения записей.
- [x] **L4.16 / Ухват: резервная копия расшифровок и безопасное восстановление:** каждое сохранение/исправление и удаление расшифровки проходит через persistTranscripts: атомарная запись зеркальной копии transcripts.backup.json, затем transcripts.json под общей блокировкой. При отказе записи копии основной файл не меняется. Очистка удалённой заметки использует строгое чтение, не перезаписывая повреждённый JSON пустым списком. Внутренняя явная операция restoreTranscriptCatalogFromBackup() отказывается откатывать исправный/отсутствующий основной файл, проверяет копию, фильтрует удалённые UUID по durable tombstones и завершает отложенную очистку. Автоматического восстановления и UI-кнопки пока нет. Семь дополнительных XCTest во временных синтетических хранилищах проверяют зеркало, восстановление, отсутствующую/повреждённую копию, отказ записи копии, очистку при удалении и завершение прерванного удаления. iPhone iOS 27 Simulator: **65 PASS / 3 SKIP / 0 FAIL**, xcresult Test-WhatIOS-2026.10.21_21-35-29-+0300.xcresult; Python **37/37**, i18n audit PASS. Остаются физический power-loss QA, файловая защита, пользовательский сценарий восстановления и VoiceOver.
- [x] **L4.15 / Ухват: защита сохранения исправленной расшифровки:** выявлен риск потери чужих заметок — при повреждённом transcripts.json прежний loadTranscripts() возвращал пустой словарь, который ручное либо автоматическое сохранение могло перезаписать. Для обеих операций updateTranscript/saveTranscript введено fail-closed чтение loadTranscriptsForMutation(): повреждённый или нечитаемый существующий файл не перезаписывается, выбрасывается transcriptStoreUnreadable с понятным сообщением RU/EN/ES (218/218 ключей iPhone). Оригинальное аудио и индекс не меняются. Пять новых XCTest на синтетических временных репозиториях: сохранение после перезапуска и неизменность других записей; отказ для пустой/несуществующей/удалённой заметки; сохранение байтов повреждённого/нечитаемого каталога; возобновление редактирования после возврата исправной копии. Испанский UI-тест подтверждает, что при ошибке появляется предупреждение, а исправленный черновик остаётся на экране. iPhone iOS 27 Simulator: **58 PASS / 3 SKIP / 0 FAIL**, xcresult Test-WhatIOS-2026.10.21_21-01-51-+0300.xcresult. Python **36/36 PASS** и аудит локализаций PASS. Автоматическое восстановление повреждённого каталога без резервной копии не выполняется; физические тесты и VoiceOver открыты.
- [x] **L4.14 / Ухват: редактор расшифровки ES + AXXXL:** в TranscriptEditorSheet при accessibility-размерах кнопки «Отмена» и «Сохранить» вынесены из ограничивающей до 36 pt системной toolbar в отдельную нижнюю панель с минимальной высотой 52 pt; при обычном шрифте исходная навигация сохранена. Добавлены стабильные accessibility ID редактора и обеих кнопок. Debug-only фикстура использует синтетический RecordingEnvelope и текст, save callback в ней ничего не пишет в репозиторий, аудио, iCloud или файловую систему; Release её не включает. Фактические XCUITest: **iPhone ES AXXXL + обычный шрифт 2/2 PASS** (19:33), **iPad ES AXXXL 1/1 PASS** (19:35), **iPhone ES изменение черновика → активируется Сохранить → закрытие 1/1 PASS** (19:37); Python и i18n **35/35 PASS**. Физическая проверка VoiceOver и реального сохранения исправленного текста с отказами/ошибками остаётся отдельным QA-gate.
- [x] **L4.13 / Ухват: голосовая запись ES AXXXL (без микрофона):** в PhoneRecordingSheet добавлена отдельная нижняя кнопка Закрыть/Удалить с минимальным размером 88 × 52 pt при Accessibility Dynamic Type, обычный режим оставляет системную панель. Start/Stop имеют стабильные accessibility ID и высоту не менее 52 pt. Debug-only безопасные флаги отключают старт микрофона и запрос разрешений, а также действие Start в тестовом режиме; продуктивный сценарий записи не меняется. Реальные XCUITest: **iPhone ES AXXXL + обычный шрифт 2/2 PASS** (19:07), **iPad ES AXXXL 1/1 PASS** (19:08); проверены переводы Cerrar, Nueva grabación, Nota de voz, доступность кнопок и возврат на главный экран без записи. Python regression + i18n audit **34/34 PASS**. Физическая проверка микрофона, разрешений, сохранения аудио и VoiceOver остаётся открытой.
- [x] **L4.12 / Ухват: видеозапись ES AXXXL (без камеры):** реальный XCUITest сначала выявил **36 pt** у системной кнопки «Отменить»; подтверждена проблема Dynamic Type в модальном экране. При accessibility-размерах VideoRecordingSheet переносит «Отменить» из UIKit toolbar в нижнюю панель (минимум **88 × 52 pt**), уменьшает превью и добавляет ID для Stop/Discard. При обычном размере верхняя кнопка сохранена. Debug-only флаги QA предотвращают запуск AVFoundation и запись данных. Итог: iPhone AXXXL **1/1 PASS** (19:00), iPad AXXXL **1/1 PASS** (19:01), iPhone обычный размер **1/1 PASS** (19:02); ES подписи камеры и Stop, ≥44 pt Discard/Stop подтверждены, Stop отключён в тесте. Python **33/33 PASS**. Физическое переключение камер/сохранение, VoiceOver и другие языки ещё не проверены.
- [x] **L4.11 / Ухват: текстовый редактор ES + AXXXL:** независимый iPad/iPhone UI QA обнаружил дефект: кнопка Done внутри UIKit навигации 36 pt вместо требуемых 44. Попытка увеличить frame внутри ToolbarItem не помогла. Исправлен TextNoteSheet: при системном Accessibility Dynamic Type Done в отдельной нижней панели над клавиатурой с минимумом 52 pt; обычный шрифт сохраняет navigation Done. Стабильный accessibility ID. Для QA размер шрифта задаётся через системный UIPreferredContentSizeCategoryName, так как увеличение только ContentView не передаётся в модальный редактор. Тест редактора ES на iPhone **1/1 PASS** (18:30), на iPad вместе с тестом меню ES **2/2 PASS** (18:31); проверены поле, кнопка ≥44, закрытие без создания заметки, сохранность разделения языка UI/диктовки. Python QA **32/32 PASS**, Debug build PASS. Обычный шрифт, прежняя кнопка навигации: iPhone тест **1/1 PASS** (18:33). Физическое VoiceOver и все устройства остаются открытыми.
- [x] **L4.10 / Ухват ES iPad AXXXL:** Debug-only синтетическая библиотека (без пользовательских файлов), испанский интерфейс при английском распознавании на отдельном iPad Simulator: фильтры, заголовок Hoy, настройки, кнопки не менее 44 pt. Системный accessibility audit четырёх категорий — description, hitRegion, trait, textClipped — PASS **1/1**, xcresult 17:49, скриншот приложен к XCTest. Python QA 31/31 PASS. Физический VoiceOver, другие экраны и редакторская вычитка остаются открытыми.
- [ ] **L3 / SmartSearch экспериментальный экран:** аудит выявил динамические англоязычные подписи в SmartSearchView.swift, но его никто не открывает в текущем UI (нет вызова конструктора вне определения). Не выдавать его за полностью переведённый/доступный продуктовый экран. Перед включением в навигацию решить, оставлять ли экспериментальную семантическую функцию, локализовать динамику RU/ES, выполнить QA результатов и политики скачивания моделей.
- [x] **L4.8 / Android Photo Picker → result → SaveDocument:** полный GUI E2E Android 16 подтверждён машинным JSON: **7/7 этапов**, системный выбор синтетического PNG 900×700 → Compose → сжатие до 500 KB → экран результата → системный SaveDocument → JPEG Downloads **479 169 байт**, JPEG 900×700 проверен. Отдельный tmux пережил RDC-disconnect; QA-артефакты и скриншоты на ArvectumSSD, tmux-photo-picker-qa/qa-photo-picker-report.json status=passed. Повторный E2E с локализованной Debug-сборкой **7/7 PASS**, имя 19-compressed.jpg. Физическая приёмка/TalkBack и другие сценарии ещё открыты.


- [x] **L3.6 QA-guard:** аудит проверяет обязательное наличие всех runtime RU/ES строк Ухвата для CaptureBrand, а также запрещает возвращение прямых isRussian-тернарников в главном экране. Python tests 14/14 PASS.
- [x] **L4.3 / Pushkin ES UI smoke:** на отдельном iOS Simulator исправлены 2 ложных требования в XCUITest: selected tab isHittable и несоответствие заголовка вкладки «Aplicaciones» экрану «Aplicaciones y configuración». После исправления тест PASS 1/1 (xcresult 21.10 09:45). Навигация History → Apps & Setup → Settings проверена. Физическая VoiceOver и AXXXL-приёмка Пушкина остаются открытыми.
- [ ] **L4:** device/visual UX и независимый review, затем отдельное явное согласование владельца для каждого релиза.
- [ ] **D-G1—G4:** физические VoiceOver, реальные интеграции и device matrix остаются открытыми. Where? на паузе.

## 19.10.2026 — Единый дизайн-код Arvectum Tools (D0)

**Статус: оформлено и реализовано в отдельной ветке, не интегрировано в main.** Документ: [UX-аудит, микрокопирайтинг и дизайн-код](docs/UNIFIED_DESIGN_CODE_2026-10-19.md).

- [x] D0: исследование Apple HIG и релевантных приложений; проверка реальных экранов/исходников четырёх продуктов, фиксация ограничений бенчмарка.
- [x] D0: общие semantic tokens и метрики в SwiftPM Core, unit-тесты; без изменения существующего UI. **SwiftPM Core: 21/21 PASS на macOS 19.10.2026; продуктовые UI/build тесты остаются отдельной задачей.**
- [x] D3/P1 Итоговая сборка 20.10: Core swift test **21/21 PASS**; iOS Simulator Debug сборки Пушкин, Фото/PDF, ChickMark и Ухват **4/4 BUILD SUCCEEDED**. Подробная QA-матрица, выполненные и открытые ворота: [внутренняя приёмка](docs/UNIFIED_DESIGN_ACCEPTANCE_2026-10-20.md). Это не разрешение на релиз.
- [x] D4.1/P1: первый реальный перенос общих токенов на контрольные экраны 4 продуктов, 44/48/64pt, радиусы и семантическая Mint/Navy CTA; ChickMark empty-state clipping исправлен. **Core 21/21, builds 4/4, UI 6/6 PASS**. [Отчёт D4.1](docs/UNIFIED_DESIGN_D4_TOKEN_INTEGRATION_2026-10-20.md).
- [x] D1/P0 Pushkin: корректное описание охвата, RU/EN главных экранов; Debug iOS Simulator BUILD, 5 unit + 5 UI PASS. Не опубликовано.
- [x] D1/P0 Фото/PDF: CTA вне ScrollView, iPhone 17 Pro normal 2/2 PASS, iPhone SE normal 2/2 PASS и AXXXL 2/2 PASS; скриншоты проверены.
- [x] D1/P1 Фото/PDF: Files exporter фото/PDF 2/2 E2E PASS, сообщение после успешной записи, unit распознавания Cancel PASS; рекламная геометрия loaded/no-fill 2/2 UI PASS, доступность consent при AXXXL PASS. Live РСЯ и физические QA gates открыты.
- [x] D1/P1 Pushkin: контраст, компактный хедер, onboarding UX, unit/UI PASS и отдельный VoiceOver истории 1/1 PASS; secondary views и полная навигация/VoiceOver открыты.
- [x] D2/P1 Ухват: видимые Видео/Текст, один hint, склонение счётчика, library identifier, обновлённые UI-тесты; build, два UI и AXXXL UI PASS. Физический VoiceOver/iPad открыты.
- [x] D2/P1 ChickMark: семантически точный «Отмечено: N из M» для RU/EN/ES, Simulator BUILD и 2/2 localization unit PASS.
- [x] D2/P1 ChickMark: AXXXL core navigation и короткий VoiceOver Today PASS; полные сценарии создания, rotor/gestures, физический QA остаются открыты.
- [x] D3/P1 Pushkin: AXXXL onboarding/coverage и settings/privacy — 2 UI PASS, исправлена маленькая область нажатия в верхнем toolbar переносом явной кнопки 48pt вне скролла. Остальные VoiceOver и физические QA открыты.
- [x] D3/P1 VoiceOver: короткие тесты реальной речи в 4/4 iOS-продуктах PASS, включая отдельно результат фото и PDF (PDF PASS через SSH 20.10). Исправлены лишние Search Image Пушкина и декоративные изображения Фото/PDF. Полный rotor/physical QA остаётся.
- [x] D3/P1 Pushkin: системный accessibility audit **3/3 PASS** на основных История/Источники/Настройки, категории labels/hit regions/traits/text clipping. Исправлены обрезания pending-card, ссылки автоматизаций, поиска и quick-add. AXXXL Setup → каталог повторный UI PASS.
- [x] D3/P1 Фото/PDF: системный accessibility audit двух экранов результата **2/2 PASS** (sufficientElementDescription, hitRegion, trait, textClipped) на AXXXL simulator; отдельный PDF VoiceOver PASS. Исправлений по результатам этих двух аудитов не потребовалось.
- [x] D3/P1 ChickMark: системный audit Сегодня и Управление привычками **2/2 PASS**. При AXXXL панель настроек прокручивается вместо закрепления на весь экран; Language/System выводятся по строкам. Обычная About/Privacy/Support навигация PASS.
- [x] D3/P1 Ухват: системный audit Capture и Library **2/2 PASS**. При AXXXL статус хранения и счётчик заметок выводятся по строкам. Обычная Capture UI smoke PASS.
- [x] D3/P1 Ухват: 13-дюймовый iPad Simulator AXXXL: Capture → пустой текстовый редактор → Library → обратно PASS, поворот Library/Capture Portrait ↔ Landscape PASS (2/2).
- [x] D3/P1 ChickMark: действительно форсированный AXXXL, заполненные группы+привычки — системный audit 4/4 категорий PASS, меню группы 48pt, настройки доступны после прокрутки. 2/2 localization unit и 2/2 обычные UI регрессии PASS.
- [x] D3/P1 Ухват: синтетически заполненная библиотека, принудительный AXXXL — подписи/traits/обрезание PASS. Пустая библиотека и Home actions — обычная UI регрессия 2/2 PASS, прокручиваемый empty state.
- [x] D3/P1 Ухват: **закрыт hit region blocker** на заполненной библиотеке AXXXL. 64pt панель действий заменяет UIKit toolbar только при Accessibility Dynamic Type; полный 4-категорийный XCUIAccessibilityAudit iPhone/iPad PASS, функциональные действия и обычная навигация 4/4 UI PASS. Физические/Watch/VoiceOver-ротор проверки открыты.
- [ ] D3/P1 Реальные медиа, много групп, полноценный VoiceOver редакторов, iPad multitasking и физические устройства требуют отдельной регрессии.
- [ ] D3/P1 Полный VoiceOver (gestures/rotor), detail/modal screens, реальные Shortcuts, physical/iPad матрица открыты. PDF VoiceOver для результата выполнен в коротком проверенном сценарии.
- [ ] D3/P1: product UX QA (VoiceOver, Dynamic Type, тёмная тема, reduce motion) и отдельные UI PR для каждого приложения.
- [ ] D4: интеграция Core после review и независимые продуктовые релизы только по явному разрешению владельца.
- [ ] D4.2: продолжить миграцию токенов других экранов и самостоятельный UX/код-review; полная миграция и release gate пока не закрыты.
- [x] D4.2/P1 Фото/PDF: внедрён понятный язык режимов и RU/EN VoiceOver-имена при компактных вкладках. Проверены RU/EN × светлая/тёмная тема, 3 mode/render сценария и локализованные action labels, build/UI PASS. [Отчёт](docs/UNIFIED_DESIGN_D4_PHOTO_MICROCOPY_2026-10-20.md).
- [x] D4.3/P1: Пушкин — локализованы группы и устойчивый список выбора (RU AXXXL full AX audit PASS, EN + старый workflow PASS, unit PASS); ChickMark — контраст ссылки заметки, меню напоминания RU/EN/ES (2 unit + 1 UI PASS); Ухват — доступная подпись текстового редактора, placeholder скрыт от VoiceOver (UI PASS). [Отчёт](docs/UNIFIED_DESIGN_D43_SECONDARY_SCREENS_2026-10-20.md).
- [x] D4.4/P1 ChickMark: Мягкое возвращение AXXXL — адаптивная навигация, 64pt Toggle/Picker, неактивный период как информация. Полный Xcode accessibility audit off/on, UI-переключение и RU/EN/ES localization tests: **5/5 PASS** плюс обычный Dynamic Type UI 1/1 PASS. [Подробный QA](docs/UNIFIED_DESIGN_D44_GENTLE_RESTART_ACCESSIBILITY_2026-10-20.md). Физический VoiceOver открыт.
- [x] D4.5/P1 Ухват: доступная диагностика синхронизации — 3 секции AX ScrollView, полноразмерные подписи и 64pt закрытие; полный аудит AXXXL PASS (верх/Watch), RU/EN UI 2/2 PASS. [Подробный QA](docs/UNIFIED_DESIGN_D45_WHAT_DIAGNOSTICS_2026-10-20.md). Реальный Watch end-to-end открыт.
- [x] **D4.6 · Итоговая внутренняя QA-приёмка (20.10):** Core 21/21, iOS Debug Simulator builds 4/4 PASS; Dark + Increase Contrast + AXXXL: ChickMark Gentle Restart OFF/ON 2/2 полного AX-аудита PASS, Ухват Diagnostics/Watch 1/1 PASS; локализации 5/5 lint OK, Git diff check PASS. [Акт D4.6 и остающиеся внешние G1—G5](docs/UNIFIED_DESIGN_D46_FINAL_ACCEPTANCE_2026-10-20.md). **Не означает релиз или merge.**
- [ ] D5: Where? остается на паузе: только принципы в документе, не реализация.

## 19.10.2026 — необязательное обновление App Store (Core, единая задача)

**Статус: интегрировано в `main`.** [PR #133](https://github.com/arvectum2/arvectum-tools/pull/133) MERGED, squash `08107c3`; [техническая приёмка](docs/APP_STORE_UPDATE_INTEGRATION_2026-10-19.md). Это не новая публикация в App Store.

- [x] Проверка опубликованной версии по Apple Lookup API при запуске, сравнение с установленной; диалог «Обновить» / «Позже», без принуждения и без блокировки офлайн. SwiftPM Core: 19/19 PASS.
- [x] Подключено к iOS ChickMark, Pushkin, Фото/PDF и Ухват; Xcode 27.1 iOS Simulator build всех четырёх: 4/4 PASS и watchOS 2/2 PASS (19.10.2026).
- [x] Изолированный iPhone 17 Pro Simulator: четыре app-specific UI-теста «Позже»/следующий запуск **4/4 PASS**, плюс positive «Обновить» на Pushkin **1/1 PASS**; Debug fixture исключён из Release, Core Release SwiftPM build PASS.
- [ ] Проверка перехода на реальную новую опубликованную версию с физического iPhone и отдельные авторизованные релизы; Where? после возобновления, Android — отдельный Google Play flow.


## 19.10.2026, вечер — Core: release provenance и адаптация

**Текущее:** [общий светофор](docs/PORTFOLIO_RECONCILIATION_2026-10-19_EVENING.md). Публичная версия ≠ исходники в main ≠ App Review. Pushkin 1.0.1(5) уже WAITING_FOR_REVIEW и **AFTER_APPROVAL**; другие приложения выпускаются независимо.

- [x] **C0:** единый ArvectumCore (DesignTokens/Persistence/Diagnostics/AdaptiveLayout), PR #90 и **38/38 интеграционных CI PASS**, четыре активных продукта используют адаптивный слой в main.
- [x] **C1 этап Pushkin:** PR #131 **8/8 GitHub checks SUCCESS**, IPA release provenance и QA-переход с сохранностью 8/8, ASC build5 VALID, submitted WAITING_FOR_REVIEW.
- [ ] **C1 следующий:** после одобрения Apple сверить build5 READY_FOR_SALE, source SHA, signed archive, GitHub/GitVerse tag, RU/другие storefronts; не путать upload с publication.
- [ ] **C2:** сохранять зелёные архитектурные контракты, зависимости, iOS/watchOS и Android CI при изменениях Core, но не присваивать продуктовым тестам общий статус.
- [ ] **C3:** матрица iPad Split View, Dynamic Type/VoiceOver, scene lifecycle по каждому приложению. Отсутствие реального Duo не блокирует код/симулятор, но **не позволяет утверждать доказанную физическую смену экранов**.
- [ ] **C4:** общий review prompt использовать только с доказанным app-specific триггером успешного действия, без агрессивных запросов.
- [x] **C5:** не вводить общий Ads/HealthKit/Telemetrics API без минимум двух реальных потребителей с одинаковой семантикой.
- [ ] Where? остаётся на паузе, не начинать её через задачи Core.

Архивные разделы ниже оставлены для provenance, даже если ранние фразы о старых review-статусах теперь неактуальны.


## Публичный checkpoint · 19.10.2026

- [x] [Apple RU подтверждение](docs/PUBLIC_RELEASE_RECONCILIATION_2026-10-19.md): Pushkin 1.0, Ухват 1.1.0, ChickMark 1.5.0 опубликованы.
- [ ] Общий Core и iPad/Duo код в `main` не является доказательством включения этих устройств в публичные версии. Подписанный patch/source mapping и app-specific gate выполнять по [плану](EXECUTION_PLAN.md).



## PR #90 объединён в main · 18.10.2026

- [x] Исходники адаптивного ArvectumCore и четырёх активных приложений объединены в стабильную main через [PR #90](https://github.com/arvectum2/arvectum-tools/pull/90), squash c86bc54, **38/38 CI PASS**.
- [x] Ухват 1.1.0 multimodal, ChickMark 1.5.0, Pushkin и Фото/PDF используют общий адаптивный дизайн. Core 13/13, финальный независимый Ухват на обычном iPhone — 104 теста, 0 ошибок, 3 skip; Pushkin удаление — 3/3 unit и 3/3 UI.
- [ ] Отдельно остаются релизная приёмка приложений, реальные системные разрешения, физический Files/Photos/Camera/HealthKit/Shortcuts и App Store дистрибуция. Отсутствие реального Duo **не блокирует разработку**; симуляторный QA уже выполнен, реальное hinge/fold-unfold не подтверждено.
- [ ] C1: закончить пост-merge CI main и пересверить реальный ASC статус каждой сборки. Слияние исходников не меняет ранее отправленные Apple бинарники.

[Акт общей интеграции](docs/ADAPTIVE_MAIN_INTEGRATION_2026-10-18.md). Формулировки исторических разделов ниже, где описан пилот вне main, относятся к состоянию ДО PR #90.


**Актуально на 18.10.2026.** **Владелец:** общая архитектура, SwiftPM, CI, контракты данных, зависимости, инженерные стандарты и release provenance. **Опорное состояние:** [Baseline 2026-10-18](BASELINE_2026-10-18.md).

## Стратегия Duo · 18.10.2026

По решению владельца отсутствие реального Duo больше **не блокер**. Доступный критерий — симуляторный QA и дальнейшие исправления по обращениям. [Мультимодальный Ухват 1.1.0](docs/ADAPTIVE_T4_T5_MULTIMODAL_2026-10-18.md) проверен на iPad/Duo; не утверждать, будто проверено реальное складывание.

## Рабочий пилот iPad/Duo · 18.10.2026

[QA T4/T5](docs/ADAPTIVE_T4_T5_PILOT_2026-10-18.md) и отдельная feature/core-ipad-duo-pilots-20261018: два пробных приложения используют ArvectumAdaptiveLayout, 13 Core unit + 4 UI теста на Duo/iPad PASS. C3 остаётся открытой до state continuity/real fold/полного продукта и physical QA. Growth не затрагивали.

## Проверенная основа

- [x] Единый монорепозиторий и независимые релизы продуктов; каноническая интеграция в main.
- [x] Рабочий SwiftPM-модуль ArvectumCore: DesignTokens, Persistence, Diagnostics. Продуктовые данные/UX остаются внутри продуктов.
- [x] Архитектурный контракт, централизованный каталог версий, проверки SwiftPM lock-файлов.
- [x] Core CI с потребителями ChickMark, Pushkin, Ухват, Фото/PDF; отдельные проверки iOS/watchOS/Android. Зелёный кодовый CI не заменяет физическую проверку.
- [x] Xcode 27.1, iPhone Duo runtime и независимый прототип AdaptiveLayout; интегрированный адаптивный Core после PR #90 уже **в main**.
- [x] Связанный релизный реестр с разделением «публично», «отправлено Apple» и «исходники/QA».

## Приоритеты для следующих шагов

- [x] **C0 · Core baseline upkeep (P0, текущий checkpoint):** при существенном изменении общей инфраструктуры выполнить [проверку baseline](README.md#быстрая-проверка), обновить датированный протокол и подтвердить CI; не менять приложение без его релизных ворот.
- [ ] **C1 · Release provenance (P0, по событию):** после решения Apple сверить ASC/READY_FOR_SALE, source SHA, подписанные бинарники, теги, GitHub/GitVerse и физическую установку. Сейчас новые Ухват 1.1.0(8) и ChickMark 1.5.0(18) имеют статус **submitted**, не опубликованы по последним доступным доказательствам. [Портфель](PORTFOLIO.md).
- [x] **C2 · Поддержка CI (P1, проверка маршрутизации):** поддерживать dependency-impact coverage четырёх собираемых iOS продуктов, watchOS, Android, manifests и lockfiles; подключать Where? только после создания реального собираемого приложения. Регрессии отслеживать в owning roadmap.
- [ ] **C3 · AdaptiveLayout (P1, gated):** два реальных потребителя, совместимость iPad Split View/Stage Manager и iPhone Duo fold/unfold, Dynamic Type/VoiceOver, scene lifecycle; только после acceptance перенести компонент из feature/core-adaptive-layout-spike-20261016 в общий пакет. [Матрица](DEVICE_ADAPTATION_ROADMAP.md).
- [ ] **C4 · StoreKit review policy (P2):** локальная оценка квалифицированных сессий (3, затем 8, 13 и т. д.), вызов RequestReviewAction **после успешного действия**, без вмешательства в запись/обработку и без обещания показа/знания, оценил ли пользователь приложение. Общий API выделять после двух реальных потребителей, испытания — в продуктах.
- [x] **C5 · Аудит общих библиотек (gated, решение принято):** выделять новый API для ads/telemetry/privacy только когда минимум два стабильных приложения используют одинаковую семантику; без скрытых сетевых/пользовательских логов и новой зависимости ради абстракции.

## Закрытие контрольной точки · 18.10.2026

- **C0:** базовая команда `bash core/tools/verify_baseline.sh` подтверждает SwiftPM, архитектуру и каталоги; реальный PR CI подтверждает интеграцию. Следующие изменения требуют повторного запуска.
- **C1:** [авторизованный read-only срез Apple](RELEASE_STATUS_ASC_2026-10-18.md) выполнен; 1.1.0 Ухвата / 1.5.0 ChickMark / 1.0 Pushkin всё ещё **WAITING_FOR_REVIEW**. Полная provenance-проверка и физический rollout **зависит от будущего решения Apple**.
- **C2:** добавлена проверка обязательных GitHub Actions `on.paths` + unit-регрессии, синхронизированы триггеры Core package/catalog и потребителей; [контракт CI](CI_IMPACT_CONTRACT.md). Тесты продуктового поведения остаются за отдельными app workflow.
- **C3:** адаптивный Core и четыре потребителя прошли симуляторные тесты и были включены в main через PR #90. Отдельные публичные релизы, физические системные разрешения и реальная работа складного дисплея пока не доказаны.
- **C4:** [политика StoreKit и матрица QA](STOREKIT_REVIEW_POLICY.md) оформлена, **общий код не выделен** без двух потребителей; после пилотов — отдельный выпуск каждой программы.
- **C5:** сверены DesignTokens, Persistence, Diagnostics; дополнительных двух стабильных потребителей для Ads/Analytics/Privacy пока не показано. Завершён аудит и принято решение **не добавлять преждевременные библиотеки**. Новый общий модуль — только по отдельной подтверждённой необходимости.

## Что не включено в Core

- Сценарии отдельных приложений (запись, HealthKit write, Shortcuts, реклама, хранение пользовательских данных) принадлежат их [дорожным картам](PORTFOLIO.md).
- SEO/ASO, сообщества, активность Growth Agent, измерение дохода и закупка трафика — [Growth](../growth/ROADMAP.md).
- Where? — на паузе; запрещено начинать реализацию через «общие» задачи.

## Документы и история

[Baseline](BASELINE_2026-10-18.md) · [Принципы](CORE_PRINCIPLES.md) · [Контракт](ARCHITECTURE_CONTRACT.md) · [Список релизных ворот](RELEASE_CHECKLIST.md) · [Execution plan, историческая очередь среза 15.10](EXECUTION_PLAN.md) · [Архив прежней версии этого roadmap](history/ROADMAP_SNAPSHOT_2026-10-18.md).

**Правило:** один активный чеклист на уровень Core. Старые чекпоинты остаются как датированные доказательства, но не дублируют незавершённые задачи.
