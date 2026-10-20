# Arvectum Tools · единый дизайн-код и UX-аудит

**Версия:** 0.1, 19.10.2026 · **Статус:** проект стандарта, без изменения публичных бинарников.
**Контекст:** SwiftUI, iOS/watchOS, четыре активных потребителя Core: ChickMark, Ухват (What?), Пушкин (Pushkin), Фото и PDF под размер; Where? — концепт, разработка на паузе.

## 1. Метод и границы достоверности

- Проверен исходный код main на коммите b3eb81b (19.10.2026): общий ArvectumDesignTokens, представления TodayView/Theme (ChickMark), QuickCaptureHomeView/RecordingLibraryView (Ухват), ContentView/SetupGuide (Pushkin), ContentView/PhotoTaskCard/ResultViews/SharedControls (Фото/PDF).
- Визуально просмотрены хранимые в репозитории App Store скриншоты: chickmark/app-store/screenshots/ru-RU/01-today.png, pushkin/store-assets/appstore/iphone-6.9/01-history.png и photo-pdf-to-size/store-assets/screenshots/01-weight.png. Они могут отличаться от последней сборки и публичной версии.
- Референсы: Apple HIG, официальные материалы Things/Apple Reminders, Drafts, Pushcut, PDF Expert, Sortly. Это сравнительный UX-бенчмарк, **не рейтинг по числу установок**, не live-юзабилити-тест и не доказательство метрик конкурентов.
- Mobbin недоступен без оплаченного тарифа; не утверждать, что аудитированы актуальные живые экраны всех конкурентов.
- iPhone VoiceOver/Dynamic Type, тёмная тема, реальное поведение длинных надписей и полнота локализаций — отдельные проверки, не отмечать их выполненными автоматически.

## 2. Принцип портфеля

**Один характер: ясно, спокойно, надёжно, локально когда возможно; разные сценарии.**
Бренд — в системной логике, языковом стиле, токенах и деталях, не в огромной одинаковой плашке на каждом экране.
- Всякий экран отвечает на один вопрос: что я могу сделать прямо сейчас?
- Главное действие доступно сразу (обычно не дальше 1 нажатия с главного экрана).
- Вторичные действия доступны, но не конкурируют размером и цветом с основным.
- Понятные заголовки и состояние без интерпретации и маркетинговых обещаний.
- Нативные NavigationStack, TabView, toolbar, sheets и system materials — по умолчанию. Не имитируем интерфейс другой ОС и не разрушаем Liquid Glass кастомными фонами панелей.
- Продуктовые акценты допустимы: ChickMark — привычки, Ухват — запись, Пушкин — история, Фото/PDF — обработка файла. Не перекрашивать всё в мятный.
- Privacy-first формулировки только в рамках фактически подтверждённого хранения и автоматизации.

## 3. Foundation tokens (v0.1)

| Слой | Норма | Применение / оговорки |
| --- | --- | --- |
| Brand Navy | #041A33 | Насыщенный фирменный цвет, текст на светлом |
| Brand Mint | #43E5C5 | Заполнение главной кнопки, индикаторы; **не мелкий текст на белом** |
| Brand Graphite | #243446 | Вторичный текст, поверхности тёмной темы |
| Текстовый акцент, светлая тема | #007A68 | Минимум 4.5:1 для обычного текста на белом/светлом |
| Основная кнопка | Mint #43E5C5 + Navy #041A33 | Рассчитанная контрастность около 11.04:1 |
| Фон / карточка, светлая тема | #F3F5F7 / #FFFFFF | Нейтрально, основной текст Navy |
| Фон / карточка, тёмная тема | #041A33 / #243446 | Не заставлять Ухват терять собственную фирменную сцену |
| Пространство | 4, 8, 12, 16, 24, 32 pt | Базовый шаг 4 pt; без бесконечных декоративных зазоров |
| Стандартный край | 16 pt на компактных iPhone | На iPad ширина контента ограничена сценарием |
| Тач-зона | минимум 44×44 pt | Для основного контролла комфортно от 48 pt |
| Радиусы | контролл 14 pt; карточка 20 pt | Допустимые умолчания, а не запрет системного радиуса |
| Текст | системные стили largeTitle/title2/headline/body/footnote/caption | Не фиксировать размер там, где должен работать Dynamic Type |
| Иконки | SF Symbols, содержательная accessibilityLabel | Единого размера недостаточно: действие должно быть угадываемо |
| Анимация | короткая, смысловая, с Reduce Motion | Не блокировать запись и сохранение анимацией |
| Обратная связь | прогресс → успех или исправимое действие | Не оставлять пользователя в неясном состоянии |

Проверка контраста sRGB для текущих бренд-пар: Mint на белом **1.58:1 (нельзя для текста)**, Navy на Mint **11.04:1**, #007A68 на белом **5.27:1**, #007A68 на #F3F5F7 **4.82:1**. Расчёт математический; реальные системные наложения и accessibility contrast перепроверяются отдельно.

Кодовые primitives: ArvectumDesignMetrics и ArvectumSemanticColors. Они **не подключаются автоматически** к существующим экранам; миграции по продуктам — отдельные безопасные PR.

## 4. UX-аудит: текущий UX → изменение

### ChickMark (P1: точечная полировка, не редизайн)

**Сильное:** хорошо читается «Сегодня», визуальные сигналы привычек, очевидная отметка выполнения; на скриншоте есть прогресс и отдельные напоминания.
**Из исходников:** TodayView скрывает стандартную панель навигации и рисует свою шапку; '+' открывает меню «привычка/разовое напоминание»; предусмотрены Undo и отдельное first-run состояние. Это обоснованное отличие сценария, не обязательно ошибка.
- P1: после UX-прогона решить, нужен ли прямой сценарий «Новая привычка» в 1 нажатие и отдельный доступ к «Напоминанию», не теряя второй тип сущности. Измерить, как часто выбирают каждую опцию, только при добровольной локальной аналитике.
- P1: сделать значение «0 из 2» однозначным: «Отмечено: 0 из 2» (выполнение или пропуск); проверить на узком экране и с VoiceOver.
- P1: у иконки с тремя линиями контекстно подписать назначение для новичка («Мои привычки»), проверить наличие корректной accessibilityLabel.
- P2: объединить визуальные параметры с Core, сохранив цветовые категории привычек, читаемость бейджей и undo-состояния.
- Не усложнять старт аналитикой, социальными механиками или геймификацией, не подтверждённой обратной связью.

### Ухват / What? (P1: доступность видео и сокращение объяснений)

**Сильное:** Shazam-подобная одна большая точка входа, автозапуск записи по нажатию, локальное сохранение, библиотека заметок.
**Из исходников:** на первом экране дважды объясняются «нажми/удерживай», видео вызывается LongPressGesture(0.5), текстовая заметка спрятана за «+». Для VoiceOver видео уже есть именованное действие.
- P1: убрать дублирование подсказки на домашнем экране. Оставить один текст «Нажмите для аудио · Удерживайте для видео» и явную вспомогательную кнопку «Видео» рядом/ниже, только после теста на компактных телефонах.
- P1: заменить неочевидное «+» на ясное «Текст» или «Новая текстовая заметка» (в зависимости от плотности), не убирать быстрый доступ.
- P1: в карточке «Мои записи» использовать «Все заметки», поскольку число включает audio + localNotes (+ видео); счётчик склонять по локали («1 заметка», «2 заметки», «5 заметок»). Не менять до подтверждения точных типов.
- P2: добавить подтверждение «Запись сохранена» и понятное состояние синхронизации Watch → iPhone без ложной гарантии; текущая надёжная очередь и исходное аудио остаются нетронутыми.
- Не разрушать тактильный, моментальный capture-flow ради единого хедера.

### Пушкин / Pushkin (P0: обещания, навигация, локализация)

**Из экрана/кода:** одновременно заголовок History и бренд-плашка Arvectum/PUSHKIN, верхний Add app и три нижние вкладки History / Apps / Settings; пустое состояние «Never lose a notification» и обещание архивации после одноразовой настройки.
- P0: уточнить обещание продукта. iOS не предоставляет произвольный архив всех чужих уведомлений; отображаем **только подключённые источники**. Нельзя обещать «никогда больше не потеряете уведомление» или полноту истории.
- P0: адаптировать UI к русскому языку при ru locale (пока наблюдаемые строки интерфейса жёстко на английском): History → «История», Apps → «Источники», Settings → «Настройки», Add app → «Подключить приложение», Search notifications → «Поиск уведомлений».
- P1: оставить один визуальный главный заголовок. Упростить тяжёлую бренд-плашку внутри каждого экрана до аккуратной идентификации приложения; не менять бренд-ассеты и logo.
- P1: пустой экран объясняет три стадии: «Подключите источник» → «Включите автоматизацию» → «Проверьте тестовое уведомление», каждую с честным статусом. Проверка фактического покрытия отдельно.
- P1: фильтр по приложениям/источникам и группировка по дням для большой истории, после проверки влияния на поиск.
- Не имитировать системный Notification Center и не скрывать ограничения автоматизации.

### Фото и PDF под размер (P0/P1: ясность сценария)

**Сильное:** документно-ориентированные режимы, реальное «до/после» по размеру и разрешению, основной экспорт уже есть.
**Визуально:** старый screenshot результата занимает много вертикали; сохранить/поделиться находится внизу. В коде результат — отдельный ResultCard внутри ScrollView.
- P0: проверить на малом iPhone, действительно ли «Сохранить файл» уходит ниже первого экрана; если да — закрепить CTA в безопасной нижней области, не перекрывая контент/рекламу.
- P1: более человеческие названия режимов: «По весу» → «Сжать файл»; «По размеру» → «Изменить размер»; «На документы» → «Фото на документы». Проверить строки во всех локалях.
- P1: на результате сначала показывать измеримый эффект: «2,92 МБ → 472 КБ» и «Готово», а технические параметры — вторым уровнем.
- P1: «Вернуться к настройкам» → «Изменить параметры»; «Максимальный вес» → «Размер файла до». После экспорта — явная обратная связь.
- P2: для PDF и фото разные способы сравнения, но единые команды «Выбрать» → «Обработать» → «Сохранить».
- Нельзя перемещать рекламу в область, где её ошибочно примут за результат или CTA.

### Where? (P3: проект только для будущего возобновления)

- Будущий основной экран: видимое поле «Где лежит…?» + «Сфотографировать вещь».
- Результат поиска: фото, название, место и достоверность совпадения, без непрозрачного «ИИ нашёл».
- Никаких задач на реализацию в текущем PR. Local-only, OCR, эмбеддинги, VLM — по отдельной дорожной карте.

## 5. UX-writing / микрокопирайтинг

**Правило голоса:** нейтральный, разговорный, уважительный. Короткий глагол в кнопке, конкретное последствие в предупреждении. RU — преимущественно «Нажмите / Выберите / Сохранить», а не хаотичное смешение «Нажми» и «Выберите». Названия продуктов могут быть дружелюбными, но системные ошибки — всегда точными.

| Контекст | Сейчас / риск | Предлагаемый текст |
| --- | --- | --- |
| Pushkin, empty | Never lose a notification | «История пока пуста» |
| Pushkin, explanatory | Set up PUSHKIN once, then incoming notifications can be archived automatically | «Подключите нужные приложения через «Команды». Здесь появятся уведомления из настроенных источников.» |
| Pushkin, CTA | Set up PUSHKIN | «Настроить сохранение» |
| Pushkin, CTA | Enable PUSHKIN automation | «Открыть автоматизации» |
| Pushkin, tabs | History / Apps / Settings | «История / Источники / Настройки» |
| Ухват, подсказка (дубль) | «Нажми — звук. Удерживай — видео» + вторая инструкция | «Нажмите — аудио. Удерживайте — видео.» (один раз) |
| Ухват, библиотека | «Мои записи», хотя считаются и заметки | «Все заметки» |
| ChickMark, прогресс | «0 из 2» | «Отмечено: 0 из 2» |
| Фото/PDF, режим | «По весу» | «Сжать файл» |
| Фото/PDF, режим | «На документы» | «Фото на документы» |
| Фото/PDF, back | «Вернуться к настройкам» | «Изменить параметры» |
| Любой продукт, ошибка | «Ошибка», «Не удалось» | «Не удалось сохранить файл. Проверьте свободное место и повторите.» — только если причина действительно проверена |
| Любой продукт, разрешения | «Дайте доступ» | «Разрешить доступ к фото» + зачем + «Не сейчас» |

**Локализации:** строки должны быть в собственных каталогах продукта, с pluralization и screen reader labels. Английские формулировки — отдельный осмысленный оригинал, не механическая калька. Учитывать VoiceOver, RTL, увеличение шрифта. Не обещать локальное хранение, если в конкретном потоке реально есть облачный путь.

## 6. Минимальный QA-gate для каждого UX-PR

1. Сначала baseline screenshot и сценарий до правки, затем screenshot и тест после.
2. Путь к главному действию: количество касаний и время первого успеха; не ухудшать без обоснования.
3. Compact iPhone, обычный iPhone, iPad Split View; портрет/ландшафт где поддерживаются. Нет клиппинга заголовков и CTA.
4. Light/Dark, Dynamic Type (включая большие accessibility sizes), VoiceOver фокус/labels, Reduce Motion, Increase Contrast.
5. Empty/loading/success/failure/permission denied/offline; undo и необратимость удаления.
6. RU/EN локализации минимум; полный набор продуктовых языков там, где он уже поддерживается. Проверка склонений, длинных немецких слов и системных шрифтов.
7. Без ложных обещаний: Pushkin capture coverage, Ухват сохранение и синхронизация, Фото/PDF результат, ChickMark отметка.
8. Системные материалы и нативные элементы не маскировать неадаптивным цветным фоном. Реклама не перекрывает критическое действие.
9. Код + UI/QA пройдены, новая сборка не отправляется в App Store/TestFlight без отдельного явного согласования.

## 7. План внедрения и оценка

| Очередь | Задачи | Критерий завершения |
| --- | --- | --- |
| D0 — готово в этой ветке | Документ, общие semantic tokens и тесты Core | SwiftPM unit/build проходят; нет изменения публичных экранов |
| D1 — P0 | Pushkin: точность обещаний и языковые строки; Фото/PDF: CTA доступен на маленьком экране | UI-тесты, локализация, демонстрация до/после |
| D2 — P1 | Ухват: видео/текст обнаруживаемы; ChickMark: ясность прогресса; единые семантические цвета и отступы | QA основных сценариев/VoiceOver/динамических шрифтов |
| D3 — P1/P2 | Пушкин: хедер и onboarding; Фото/PDF: терминология и результаты | Регрессионные тесты результатов и навигации |
| D4 — P2 | Дизайн QA всем четырём приложениям, релизный чеклист и снимки состояний | Матрица готовности + независимые product release gates |
| D5 — P3 | Where? после снятия паузы | Отдельное продуктово согласованное MVP |

## 8. Основания бенчмарка

- Apple HIG — https://developer.apple.com/design/human-interface-guidelines/designing-for-ios/
- Apple HIG Writing — https://developer.apple.com/design/human-interface-guidelines/writing
- Apple Liquid Glass — https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- Apple UI hit targets — https://developer.apple.com/design/tips/
- Apple Reminders — https://support.apple.com/en-gb/guide/iphone/iphc7880ecd6/ios
- Drafts capture — https://docs.getdrafts.com/gettingstarted/
- Pushcut automation — https://www.pushcut.io/support/notifications
- PDF Expert reduce file size — https://support.readdle.com/pdfexpert/en_US/managing-files-and-folders/reduce-the-pdf-file-size
- Sortly mobile — https://help.sortly.com/sortly-mobile-app

**Решение:** общий Core владеет фундаментальными цветами/метриками/контрактом; продукт владеет основным UX, юридическими обещаниями, текстами, локализацией и релизом. Не добавляем непроверенные общие UI-компоненты ради стандартизации.

## 9. Фактическая приёмка · 19.10.2026

Все результаты ниже получены на выделенном iPhone 17 Pro Simulator, iOS 27.0, Xcode 27.1, Debug; они не относятся к публичным App Store версиям или физическому Watch/iPhone.

- **Фото/PDF:** CTA находится вне ScrollView; два независимых UI теста testPhotoSaveIsVisibleWithoutScrolling и testPDFSaveIsVisibleWithoutScrolling прошли. Проверены isHittable и положение в пределах экрана. AXXXL прогон прервался до проверки UI; компактный iPhone, РСЯ, реальный экспорт через Files остаются отдельными gates.
- **Пушкин:** компактный 34-pt ArvectumWordmark, dark teal tint на белом, mint+navy CTA, сокращённый заголовок подключения без изменения исходного source identity. Unit + два UI теста пройдены; результат визуально проверен по снимку. На предыдущем снимке белый текст на mint имел недостаточный контраст; теперь текст navy. Dark Mode отдельно не проверен.
- **Ухват:** AXXXL testAccessibilityTextSizePreservesCaptureAndEmptyTextEditor прошёл; большая кнопка аудио, текстовый редактор и библиотека доступны, пустая заметка не сохраняется. Скриншот AXXXL проверен. Стабильный identifier what.open.library добавлен; ожидания переименования синхронизированы в пяти файлах UI тестов.
- **ChickMark:** AXXXL testA7AXXXLCoreNavigationAndAccessibleHabitControls прошёл (Сегодня, Manage, Detail, Extended History). RU/EN/ES счётчик Отмечено проверен отдельными unit тестами.
- **Нестабильность QA-среды:** одна система разрешения камеры от Ухвата перекрывала экран Фото/PDF на общем QA-симуляторе. После рестарта только выделенного QA-симулятора основные Photo/PDF UI тесты прошли. Иногда второй UI тест внутри одной сессии прерывается с BUILD INTERRUPTED; такой прогон не обозначается PASS и не доказывает наличие дефекта продукта.

Артефакты тестов сохранены на ArvectumSSD в папке Arvectum/tmp/arvectum-tools-design-qa-20261019. Исходники лежат в отдельной локальной ветке; main и App Store не изменялись.

## 10. Приёмка доступности 20.10.2026

**Среда:** iPhone SE 3rd gen iOS 27.0 Simulator (временный QA), iPhone 17 Pro iOS 27.0, Xcode 27.1, Debug fixtures; ничего не публиковали.

- **Pushkin:** тёмная тема с Increase Contrast проверена скриншотом. Системное поле поиска получило контрастный placeholder (dark/light). Сборка iOS Simulator PASS; полный VoiceOver/secondary UI QA остаётся.
- **Фото/PDF:** на iPhone SE обычный текст: фото+PDF 2/2 UI PASS. При AXXXL до исправления тоже 2/2 по нажимаемости, но скриншоты выявили гигантские/обрезанные элементы. Исправлены: компактная 44pt доступная кнопка Домой, вертикальная строка статуса/настроек, ограничение служебной типографики до accessibility1/xxxLarge, прокручиваемое основное содержимое, вертикальные подпись/значение PDF, читаемый CTA и полная ссылка рекламы/приватности. После исправления iPhone SE AXXXL фото+PDF: **2/2 UI PASS**; скриншоты проверены, PDF статистика не ломает слова/значения.
- UI-тест дополнен проверками isHittable для Save/Изменить настройки/Реклама и конфиденциальность, ограничением высоты sticky Save до 96pt и XCTAttachment со снимком.
- За рамками: реальный Files export, рекламный SDK consent/no-fill, физический VoiceOver, iPad Split View.

Артефакты xcresult и скриншоты находятся только на ArvectumSSD/Arvectum/tmp/arvectum-tools-design-qa-20261019.

## 11. Системный экспорт и рекламные состояния · 20.10.2026

Изолированный iPhone 17 Pro iOS 27.0 Simulator, Xcode 27.1, Debug fixtures, без пользовательских документов.

- Files: testPhotoFileExporterAndSuccessFeedback и testPDFFileExporterAndSuccessFeedback — оба PASS. Система открывает настоящий Files exporter, кнопка «Сохранить» доступна, после завершения callback приложение показывает RU «Файл сохранён» / EN «File saved». При одном лишь открытии экспортера успех не показывается. Независимый побайтовый аудит файла в системном провайдере не проведён.
- Отмена: NSCocoaErrorDomain code NSUserCancelledError выделяется в отдельный путь, настоящие IO ошибки сохраняются. Специальный unit test — PASS. Полная UI-автоматизация отмены на iOS 27 не подтверждена, поскольку picker «На iPhone» не содержит видимой кнопки Cancel, а жест закрытия в раннере нестабилен. Физическая ручная проверка остаётся обязательной.
- Реклама: DEBUG-only рекламный mock loaded (180pt) и no-fill (1pt) — 2/2 PASS. Проверены сохранение, настройки и доступность приватности. Эти UI-функции не осуществляют реальный сетевой показ и не подтверждают поведение Yandex Mobile Ads в release.
- Конфиденциальность: экран согласия на рекламу при AXXXL — UI PASS, обе кнопки достижимы, отказ возвращает к результату с доступной кнопкой сохранения. Реальные ATT/SDK data flows не тестировались.
- Post-change Files E2E был прерван QA-раннером при повторной попытке после добавления обработки отмены; первоначальные два полных E2E пройдены и новый unit test прошёл. Не объявлять финальную UI-проверку отмены выполненной.

Артефакты — на ArvectumSSD в Arvectum/tmp/arvectum-tools-design-qa-20261019. Основная ветка и опубликованные приложения не изменялись.

## 12. Pushkin AXXXL navigation · 20.10.2026

- iPhone 17 Pro, iOS 27 Simulator: тест Setup/Coverage AXXXL **PASS**, отдельный Settings/Privacy AXXXL **PASS**. Подключение новых системных Shortcuts и очистка реальной истории не выполнялись.
- Первый тест выявил 36pt фактическую область кнопки в toolbar. Пытались увеличить frame до 48pt, но системный layout сжал tappable size. Исправили конструктивно: вынесли кнопку перехода к управлению источниками в видимую 48pt строку между бренд-хедером и прокручиваемым List. Повторный AXXXL UI PASS.
- Микрокопирайтинг Setup/Settings RU стал короче без утверждения доступа ко всем уведомлениям; добавлены стабильные UI identifiers для настройки приватности/очистки истории.
- Полноценный физический VoiceOver, производительность и работа с Shortcuts остаются отдельными воротами качества.


## 13. VoiceOver QA · 20.10.2026

Изолированный iPhone 17 Pro Simulator, iOS 27.0, Xcode 27.1. На Mac mini volume=0. Физический iPhone пользователя не переключался.

- Настоящий XCUIDevice.shared.voiceOverService был включён в UI-тесте. Получены utterances истории Пушкина: PUSHKIN История Heading, Подключить приложение Button, Search Image, Поиск уведомлений Text field.
- Декоративная иконка magnifyingglass получила accessibilityHidden(true). Повторный журнал реальных VoiceOver utterances подтвердил исчезновение отдельной Search Image: теперь после бренда произносится Поиск уведомлений Text field.
- При этом UI-раннер неоднократно завершался BUILD INTERRUPTED (много запущенных симуляторов, большой swap, нестабильный RDC). Поэтому фиксируем фактические utterances и выполненную правку, а не полный VoiceOver E2E PASS. Системный performAccessibilityAudit также INTERRUPTED до результата.
- Два теста VoiceOver истории/настроек и системный Accessibility Audit оставлены opt-in через ARVECTUM_VOICEOVER_QA=1 и ARVECTUM_ACCESSIBILITY_AUDIT_QA=1. Штатный UI suite не должен из-за них прерываться без специального включения.
- Ухват: исправлена accessibilityHint первичной кнопки (двойное касание для аудио, action Видеозапись для видео); UITest audio/video/text labels and tappability PASS. Build-for-testing Ухвата и Пушкина PASS.
- Открыто: независимый полный VoiceOver на всех 4 продуктах, реальные жесты/rotor и физическая приёмка, системный аудит второстепенных экранов. Никаких пользовательских настроек не меняли.


## 14. VoiceOver acceptance · 20.10.2026

Среда: изолированный iPhone 17 Pro simulator iOS 27, Xcode 27.1, Mac mini volume 0, user iPhone не трогали. Все четыре теста реально использовали XCUIDevice.shared.voiceOverService для получения utterances, а не только accessibility properties.

- Ухват: testActualVoiceOverCaptureSpeech PASS 21.207s, произнесены Ухват, Создать текстовую заметку, Ухвати мысль, Начать запись с корректной подсказкой для VoiceOver, Видео. Файл what-voiceover-speech-short-20261020.log.
- ChickMark: testVoiceOverTodayShortSpeechSmoke PASS 26.017s, произнесены ChickMark, Manage habits, Add, Today Marked: 0 of 2, 0%, Reading, Mark complete. Файл chickmark-voiceover-speech-short-20261020.log.
- Фото/PDF: testActualVoiceOverPhotoResultSpeech PASS 26.176s после скрытия декоративных Wordmark/Preview. Озвучены На главный экран, ГОТОВО, Изменить настройки, Фото подготовлено, До, После, размер. Без лишнего Image. Файл photo-voiceover-speech-rebooted-20261020.log. PDF отдельно действительно произнёс PDF уже подходит, До, 249 КБ, После, но runner завершился BUILD INTERRUPTED: для PDF теста PASS нет.
- Пушкин: testVoiceOverHistorySpeechWithoutDecorativeSearchIcon PASS 20.476s. Озвучены PUSHKIN История, Подключить приложение, PUSHKIN, Поиск уведомлений и статус CapCut без исходного Search Image. Файл pushkin-voiceover-short-4app-20261020.log.
- PDF VoiceOver test оставлен opt-in через ARVECTUM_VOICEOVER_QA=1, поскольку отдельные запуски нестабильны; не запускать в стандартном CI до стабилизации среды.\n- Короткие VoiceOver smoke tests PASS для 4 из 4 приложений, но НЕ полный аудит доступности. Открыты все secondary screens, VoiceOver gestures/rotor, PDF test PASS, системный performAccessibilityAudit и physical-device QA. Длинный VoiceOver Settings Пушкина и системный аудит opt-in; короткий History теперь обычный тест.
- При BUILD INTERRUPTED симулятор может сохранить VoiceOverTouchEnabled=1; перезапускать и выключать только выделенный QA-симулятор, проверять VoiceOverTouchEnabled=0. Не менять реальные пользовательские accessibility settings.

Исходники и результаты только на ArvectumSSD, main и App Store не затронуты.


## 15. PUSHKIN accessibility audit · 20.10.2026, утренний прогон

Среда: выделенный iPhone 17 Pro iOS 27.0 Simulator, системный Accessibility XXXL, Xcode 27.1, отладочная фикстура истории. Проверялся интерфейс, без создания системных Shortcuts, пользовательских данных и публикаций.

- Xcode performAccessibilityAudit: sufficientElementDescription, hitRegion, trait, textClipped.
- Первый аудит истории FAIL: coverage-finish-card, кнопка Открыть автоматизации, поиск уведомлений — text clipped. Исправлены: независимая прокрутка pending-card в Accessibility sizes, перенос длинного CTA и заголовка, гибкая высота и явная accessibilityLabel поиска, ограничение размера однострочного поля.
- После исправлений История PASS (pushkin-ax-audit-after-layout-20261020.log), Настройки PASS (pushkin-settings-audit-20261020.log).
- Первый аудит Источников FAIL: текст Добавить или настроить источники обрезался в однострочной quick-add. Разрешён перенос до трёх строк при большом шрифте; рост по высоте, minHeight 48. После правки Источники PASS (pushkin-sources-audit-final-20261020.log); промежуточный прерванный тест не учитывается.
- testAccessibilityXXXLSetupAndCoverageNavigation после правки PASS (pushkin-setup-axxxl-after-audit-20261020.log): quick-add → каталог → действие подключения.
- Итого три основных экрана Пушкина прошли системный аудит 3/3. НЕ тестировались все модальные окна, detail screens, реальные Shortcuts, rotor и физический iPhone.
- PDF VoiceOver после нового прогона xcodebuild BUILD INTERRUPTED в момент включения службы; ранее фактические фразы PDF получены, но тестовое завершение не PASS. PDF-тест остаётся opt-in.


## 16. PHOTO/PDF accessibility audits & PDF VoiceOver · 20.10.2026

Среда: выделенный iPhone 17 Pro iOS 27.0 Simulator, Xcode 27.1, системный AXXXL, только DEBUG synthetic photo/PDF fixtures. Проверены четыре категории системного XCUIAccessibilityAudit: sufficientElementDescription, hitRegion, trait, textClipped.

- Результат фотографии: testPhotoResultSystemAccessibilityAudit PASS, без найденных проблем в указанных категориях. Первый запуск BUILD INTERRUPTED из-за нестабильного RDC, повторный TEST SUCCEEDED. Log: photo-result-accessibility-audit-retry-20261020.log.
- Результат PDF: testPDFResultSystemAccessibilityAudit PASS. Запуск через SSH с MacBook к Mac mini, чтобы прерывание RDC не завершало процесс Xcode. Log: pdf-result-accessibility-audit-over-ssh.log. В тестовом UI пользовательский PDF не использовался.
- Результат PDF, реальное произнесение VoiceOver: testActualVoiceOverPDFResultSpeech PASS; Xcode voiceOverService с включением/перемещением/отключением. Произнесено: VoiceOver on, ГОТОВО, Изменить настройки Button, PDF уже подходит, До. Log: pdf-voiceover-over-ssh-20261020.log. После завершения VoiceOverTouchEnabled=0, громкость Mac mini=0.
- Итого системные аудиты основных экранов Пушкина и результата Фото/PDF: **5/5 PASS**; короткие реальные VoiceOver тесты 4/4 приложений, отдельный Фото/PDF VoiceOver 2/2. Это не покрывает весь функционал и не заменяет физический VoiceOver, rotor/gestures и пользовательские сценарии.
- Ранее в разделе 14 PDF VO был честно открыт из-за прерывания раннера. Данный более поздний успешный прогон закрывает именно короткий PDF VoiceOver-тест. Полные сценарии и ручная физическая приёмка остаются открытыми.
- Исходники и файлы результатов на ArvectumSSD в Arvectum/tmp/arvectum-tools-design-qa-20261019, без изменений main, системных автоматизаций, пользовательских данных и App Store.


## 17. ChickMark and What accessibility audits · 20.10.2026

Среда: iPhone 17 Pro iOS 27 Simulator, Xcode 27.1, отдельный QA профиль на ArvectumSSD. Не совершались записи видео/аудио и не менялись реальные HealthKit, Watch, Shortcuts или пользовательские заметки. Xcode audit: sufficientElementDescription, hitRegion, trait, textClipped на AXXXL; обычная регрессия при стандартном Large.

ChickMark:
- Today: testTodaySystemAccessibilityAudit PASS. Проверено пустое тестовое состояние.
- Manage habits: исходный audit FAIL — Text clipped element=nil. Диагностический Accessibility Tree обнаружил фиксированную нижнюю safeAreaInset панель, высота строки выбора языка 233 pt, и перекрытие основного экрана на AXXXL.
- Исправлено: при Accessibility Type настройки переносятся в ScrollView (пустое состояние) либо List Section (заполненное), вместо фиксированной нижней панели. Подпись языка и значение выводятся вертикально. При стандартных размерах интерфейс не меняется.
- Повторный testManageHabitsSystemAccessibilityAudit PASS: chickmark-manage-audit-after-fix-20261020.log. На нескольких группах/привычках пока не проверено.
- Стандартная регрессия testBrandAndVersionInAboutScreen PASS: chickmark-manage-normal-regression-20261020.log.

Ухват / What:
- Capture: testCaptureHomeSystemAccessibilityAudit PASS: what-capture-ax-audit-20261020.log.
- Library: исходный audit FAIL, элемент «Сохранено на устройстве» — text clipped: в HStack теснились статус и число заметок.
- Исправлено: при Accessibility Type статус и счётчик размещаются вертикально в VStack. При стандартном размере остаётся HStack.
- Повторный testNotesLibrarySystemAccessibilityAudit PASS: what-library-ax-after-fix-20261020.log. Проверена пустая тестовая библиотека, не реальный набор заметок.
- Стандартная регрессия testCaptureAlternativesAreDiscoverable PASS: what-capture-normal-regression-20261020.log.

Итог: 4/4 системных accessibility audits ChickMark/What PASS, 2/2 проверки стандартной навигации PASS. Вместе с ранними тестами Пушкина/Фото-PDF имеем 9 проверенных экранных состояний с системным аудитом. Это не полный аудит приложения; остаются заполненные списки, другие формы, gestures/rotor и физическая приёмка.

Исходники и журналы на ArvectumSSD; main/App Store не изменялись.


## 18. What iPad 13-inch AXXXL regression · 20.10.2026

Выделенный QA iPad Simulator UhWhat-13-inch-Release-20261018 (iOS 27.0); контентный размер Accessibility XXXL, без физических камер, микрофона и Watch.

- testAccessibilityTextSizePreservesCaptureAndEmptyTextEditor PASS: стартовый Capture, видимость действия текстовой заметки, пустой редактор, Done без создания пустой заметки, Library и фильтр All, возврат к записи. Log: what-ipad13-axxxl-editor-20261020.log.
- testCaptureAndUnifiedLibraryKeepStateAcrossRotation PASS: открытие библиотеки, смена портретной/альбомной ориентации, возврат, видимость действий. Log: what-ipad13-rotation-after-design-20261020.log.
- Итого 2/2 PASS. Не подтверждает реальный Duo hinge, stage manager/side-by-side Split View, системное разрешение камеры, работу Watch ACK и полноту VoiceOver.


## 19. Populated state and verified AXXXL QA · 20.10.2026

**Уточнение методики.** Параметры запуска UIPreferredContentSizeCategoryName и simctl ui content_size сами не гарантировали, что SwiftUI фактически выполняет ветку dynamicTypeSize.isAccessibilitySize. Это подтверждено отладочным деревом (около 16pt, обычная строка Delete group в якобы AXXXL). Для двух синтетических Debug QA сцен добавлено принудительное environment dynamicTypeSize = accessibility5, строго под их флагами. Release и реальные данные не затрагиваются. Само увеличение шрифта не подменяет системный XCUIAccessibilityAudit.

**ChickMark:** тестовый флаг ui-testing плюс qa-design-filled-habits, seed-watch-sync-demo и seed-screenshot-demo создаёт in-memory SwiftData и группу на отдельном симуляторе. Длинная строка удаления группы обрезалась. Перенос меню в header Section не сделал его доступным в AX tree; рабочее решение — отдельный 48pt доступный Menu в строке группы при AXXXL, короткая локализованная подпись и подсказка, что привычки сохранятся. Стандартный размер показывает строку удаления группы. testPopulatedGroupedHabitsAccessibilityAudit проверяет наличие меню, область 44pt, категории labels/hitRegion/traits/textClipped, прокрутку до настроек: **PASS**, log chickmark-filled-axxxl-verified-audit-20261020.log. Unit локализации 2/2 и обычные UI тесты 2/2 PASS, log chickmark-filled-normal-locale-final-20261020.log. Само удаление не нажималось.

**Ухват:** Debug-флаг qa-design-filled-library создаёт 2 временные текстовые заметки, 1 отсутствующее видео, 1 архивную заметку лишь во временных свойствах PhoneStore, без записи файлов и передачи Watch. При настоящем AXXXL системный audit обнаружил обрезание: текст внутри кнопок имел высоту около 52pt при 48pt контейнере. Действия переводятся в вертикальный layout 64pt для AX, фильтры и меню увеличены, Inbox/Archive Picker использует controlSize large; стандартный HStack сохраняется. labels/traits/textClipped заполненного экрана **PASS**: what-axxxl-increased-actions-20261020.log, what-filled-final-after-empty-state-20261020.log.

**Пустая библиотека Ухвата:** стандартный ContentUnavailableView обрезал подсказку даже после её сокращения. Заменён на ScrollView + VStack с динамическими шрифтами и переносом строк, текст уточнён RU/EN: «Нажмите „+“ для текста или вернитесь к записи». Обычная UI регрессия Home 1/1 PASS и системный audit пустой библиотеки 1/1 PASS, log what-empty-custom-state-20261020.log.

**История проблемы (до исправления из раздела 20):** системный hitRegion audit заполненной библиотеки Ухвата первоначально показывал 2 проблемы Hit area is too small с element=nil. Внутренние UIKit UINavigationBar buttons оставались 36–40pt несмотря на SwiftUI frame 48pt, поэтому частичный тест labels/traits/textClipped не заменял полный audit. Блокер впоследствии **исправлен и закрыт** в разделе 20 с полными iPhone/iPad XCUIAccessibilityAudit PASS.

**Границы:** не изменялись пользовательские привычки, заметки, аудио/видео файлы, HealthKit и Watch; main/App Store не изменялись. Открыты физический VoiceOver, iPad Split View, реальный медиаконтент и end-to-end Watch ACK.


## 20. What navigation hit-region closure · 20.10.2026

**Причина:** системный XCUIAccessibilityAudit заполненной библиотеки Ухвата показывал два hitRegion issue с element=nil. SwiftUI frame 48pt внутри нативной toolbar не расширял фактические кнопки UINavigationBar, оставшиеся около 36–40pt.

**Решение:** только при dynamicTypeSize.isAccessibilitySize скрываем системную navigationBar внутри RecordingLibraryView и показываем в контенте accessibleLibraryActions: назад к записи, новая текстовая заметка, настройки. Кнопки 64pt; иконка микрофона без видимого слова «Записать» при AXXXL имеет полный accessibilityLabel. Текст «Записать» обрезался в узком горизонтальном заголовке. Сохранили старые callbacks/меню/URL/state, обычные размеры продолжают использовать нативную toolbar.

**Приёмка:**
- testPopulatedMixedLibrarySystemAccessibilityAudit — полный системный аудит 4 категорий PASS на iPhone 17 Pro iOS 27, включая явные проверки трёх кнопок не меньше 44pt. Лог what-filled-four-category-icon-record-20261020.log.
- На 13-дюймовом iPad Simulator iOS 27 тот же полный тест PASS. Лог what-ipad13-full-ax-custom-bar-20261020.log.
- testPopulatedLibraryAccessibleActionsNavigateSafely PASS: пустой текстовый редактор открывается, Done не создаёт заметку, возврат на экран записи.
- testPopulatedLibraryAccessibleSettingsMenuOpens PASS: оригинальное меню открывается, выбор опций не совершался.
- Стандартная регрессия testCaptureAlternativesAreDiscoverable и testNotesLibrarySystemAccessibilityAudit PASS. Общий тестовый прогон 4/4 PASS, лог what-library-combined-regression-final-20261020.log.

**Ограничение QA:** ранее тест Home иногда не находил tappable Text, когда CoreSimulator показывал окно 134×291pt вместо настоящего размера iPhone. Добавлены проверка геометрии, один перезапуск при миниатюрном окне и ограниченное ожидание, но обязательная проверка isHittable не отключена. Одиночный и комбинированный прогон после этого PASS; длительная CI-стабильность пока не измерена.

**Границы:** данные пользователя, видео/аудио, Apple Watch, main и App Store не затрагивались. Далее физический VoiceOver rotor/gestures, iPad Split View/Stage Manager, независимая приемка Core tokens.


**Итоговый акт D3:** [внутренняя QA-приёмка 20.10](UNIFIED_DESIGN_ACCEPTANCE_2026-10-20.md).

**Выполнено D4.1 (20.10.2026):** [точечная интеграция Core-токенов и регрессия четырёх продуктов](UNIFIED_DESIGN_D4_TOKEN_INTEGRATION_2026-10-20.md). Остальные экраны не объявлены мигрированными.

**Выполнено D4.2 Фото/PDF (20.10.2026):** [видимые короткие режимы, полные VoiceOver-имена и проверка RU/EN](UNIFIED_DESIGN_D4_PHOTO_MICROCOPY_2026-10-20.md).

**D4.3 (20.10.2026):** [локализация и доступность второстепенных экранов: Пушкин, ChickMark, Ухват](UNIFIED_DESIGN_D43_SECONDARY_SCREENS_2026-10-20.md). Только указанные сценарии приняты, не весь UI.

**D4.4 (20.10.2026):** [Полный accessibility audit настройки ChickMark «Мягкое возвращение» в состояниях off/on](UNIFIED_DESIGN_D44_GENTLE_RESTART_ACCESSIBILITY_2026-10-20.md).
