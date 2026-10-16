# Аудит повторно используемой адаптивности — 16.10.2026

**Цель:** сократить повторную верстку iPhone/iPad/iPhone Duo без привязки Core к функционалу отдельных приложений.

## Подтверждено по исходникам

| Область | Что есть сейчас | Что предлагается |
| --- | --- | --- |
| Core | Одна SwiftPM-библиотека ArvectumCore содержит palette/JSON/diagnostics; визуальной adaptive API ещё нет в main | Новый небольшой модуль ArvectumAdaptiveLayout (исследовательская ветка) |
| Ухват | В ветке feature/what-multimodal-20261016 используются GeometryReader, adaptive scroll, readable maxWidth 640/860/900/960, Dynamic Type compact | Pilot: читаемая ширина редактора/библиотеки; переход содержимого две панели ↔ одна. Не трогать жест записи/камеры |
| ChickMark | Есть собственные Dynamic Type checks, layout карточек и размеры целей; текущая main target family iPhone only | Pilot позднее: форма/статистика/читаемая ширина. Check-in/HealthKit/CloudKit не в Core UI |
| Пушкин | NavigationStack, формы onboarding, коллекция и карточки уведомлений; основной target iPhone only | Pilot позднее: список/детали + общая типографика. Уведомления и Shortcuts остаются продуктовой логикой |
| Фото/PDF | Редактор фото/PDF, формы экспорта, рекламные слоты с собственным GeometryReader; основной target iPhone only | Pilot: Preview + параметрическая панель, читаемая ширина. Files, ориентирование PDF, РСЯ не переносить |
| Where? | Утверждён концепт, активной сборки ещё нет, проект на паузе | Использовать модуль при старте MVP только после снятия паузы |

## Вывод и границы

**Уже есть смысл в общем Core:** width-based layout decisions, readable column, compact/expanded view composition, общий QA-контракт. В Core не нужны универсальные хедеры/кнопки записи и рендер всей навигации. Native SwiftUI NavigationSplitView / ViewThatFits / Grid / адаптивные arrangement views решают часть вопросов лучше кастомного Core.

**Нельзя определять дизайн по** UIScreen.main.bounds, UIDevice.current.userInterfaceIdiom, фиксированной ориентации и названию Duo: размер окна меняется во время работы, включая Split View и fold/unfold. Особые reserved regions Duo при частичном складывании требуют системных API, не самодельной поправки на шарнир.

**Среда и проверки:** Mac mini Xcode 27.0; iPhone Duo simulator (по Apple) требует Xcode 27.1. SwiftPM Core: **11/11 unit-тестов PASS** на macOS; сборки пакета под **iOS Simulator и watchOS Simulator PASS**. Это проверка компиляции Core, **не** app-level UI на iPad/Duo и не физическое тестирование.

**Релизы:** никакие производственные UI, конфигурации device family, SDK target, подписанные IPA, исходные пользовательские данные не менялись.

## Следующий приёмочный этап

- [x] R0: аудит реальных Core API, четырёх активных iOS-продуктов и What feature-ветки.
- [x] R1: создать изолированный SwiftUI прототип (metrics/column/content stack), Core unit tests.
- [ ] R2: два пилота-потребителя в своих feature-ветках с iPhone/iPad simulator UI проверками и гарантией сохранения состояния при resize.
- [ ] R3: Xcode 27.1 + iPhone Duo simulator, native reserved-region tests, сравнение с iPad Split View.
- [ ] R4: CI по Core + двум потребителям, физическая приёмка критичных системных интеграций, только затем рассматривать слияние в main.

## Источники

Apple (актуально на 16.10.2026): https://developer.apple.com/iphone-duo/prepare/ и https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

Core собственные правила: core/packages/README.md — общий Swift-код после фактического применения минимум в двух приложениях.
