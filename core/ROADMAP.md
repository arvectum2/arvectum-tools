# Arvectum Tools Core — дорожная карта

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
