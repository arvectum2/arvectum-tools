# Arvectum Tools — Product + Brand + UX Specification v0.1

**Status:** canonical v0.1
**Date:** 2026-09-24
**First product:** «Фото под размер»
**Master brand:** Arvectum
**Consumer family:** Arvectum Tools
**Principles:** One tool. One job. Done. / Local first.

## Current release state — 2026-09-25

**Canonical Android build:** `Фото под размер 0.4.2` (`versionCode 7`).

The product/UI phase is complete for the first market test. The approved launcher icon is the edge-to-edge Deep Navy portrait-in-frame artwork with four inward mint arrows. Primary flows must fit without vertical scrolling.

**Current phase:** release preparation.

Next work is:
- production signing;
- RuStore publication;
- iOS/App Store port and publication;
- no new product features before the first market experiment.

Canonical handoff: `docs/RELEASE_HANDOFF_2026-09-25.md`.

---

## Current amendment — v0.3.0

This amendment supersedes the historical v0.1 UI/color notes below. Functional scope remains frozen after v0.2; v0.3.0 changes branding and interaction polish only.

**Final user modes:** `По весу` / `По размеру` / `На паспорт`.

**Final app shell:**
- canonical Arvectum wordmark at the top;
- product title `Фото под размер`;
- all three mode buttons in one row;
- task content in one primary card;
- `Arvectum.com` at the bottom;
- Light/Dark support remains.

**Arvectum palette used in the app:**
- Mint Primary: `#43E5C5`;
- Mint Light: `#7AF1DD`;
- Deep Navy: `#041A33`;
- Graphite: `#243446`;
- Soft Gray: `#F3F5F7`;
- White: `#FFFFFF`.

**Visual language:** the same restrained mobile language as Arvectum Proxy Launcher — Deep Navy foundation, Graphite surfaces, mint reserved for actions/signals, large rounded task panels, minimal decorative UI.

**UI/UX QA:** seven cross-review passes are recorded in `docs/UI_UX_CROSS_REVIEW_V0_3_0.md`.

---

## 1. Product Contract — «Фото под размер»

### User job
«Сайт говорит, что файл должен быть не больше X КБ/МБ. Сделай так, чтобы он подошёл».

### Promise
Выберите изображение → укажите максимальный размер → получите файл, который не превышает лимит.

### Contract
- Обработка выполняется локально на устройстве.
- Оригинал никогда не изменяется.
- Пользователь не управляет JPEG quality, DPI, percentage resize и другими техническими параметрами.
- Приложение само подбирает качество и при необходимости уменьшает разрешение.
- Успешный результат всегда проходит проверку `actualBytes <= requestedMaximum`.
- Если исходник уже укладывается в лимит, он не перекодируется.
- Результат можно сохранить или отправить через системный Share Sheet.

### Presets
100 КБ / 500 КБ / 1 МБ / 2 МБ / 5 МБ / Свой.

Custom range v0.1: 10 КБ–50 МБ.

Внутренний целевой размер: ориентировочно до 98% заданного лимита, чтобы уменьшить риск пограничного отказа стороннего сайта.

---

## 2. MVP v0.1 scope

### Входит
- Android / RuStore-first.
- Русский язык.
- JPEG/JPG, PNG, статичный WebP на входе.
- JPG на выходе.
- Корректная ориентация изображения.
- Удаление лишних метаданных в результате.
- Предупреждение о потере прозрачности PNG при конвертации в JPG.
- Выбор изображения через системный Photo Picker / SAF-подобный поток без общего доступа ко всей медиатеке.
- Save.
- Share.
- Light / Dark.
- Минимальная продуктовая аналитика.
- Crash reporting.
- Реклама только после получения результата; отсутствие рекламы не блокирует функцию.

### Не входит
- Batch.
- Crop / rotate editor.
- Pixel resize UI.
- JPEG quality slider.
- Выбор выходного формата.
- PDF.
- HEIC как обязательная launch-функция.
- Видео.
- История файлов.
- Аккаунт.
- Backend.
- Облако.
- Синхронизация.
- Собственная камера.
- Подписка / Pro.
- AI.
- Общая micro-app platform.
- Отдельный reusable core до появления повторения минимум в нескольких реальных приложениях.

---

## 3. Brand direction v0.1 — Precision Utility

### Character
Точный, спокойный, быстрый цифровой инструмент. Не «технологичный ради технологичности» и не generic consumer app.

### Visual rule
Главный визуальный объект — сама операция и её измеримый результат: `12,4 МБ → 4,73 МБ`.

### Brand hierarchy
1. Product name — пользовательская функция.
2. Product action/result.
3. `by Arvectum` — подпись происхождения.
4. Arvectum Tools — семейство, преимущественно store/about/website level, а не крупный элемент каждого рабочего экрана.

---

## 4. Wordmark / logo usage

### Arvectum
Существующий мастер-логотип Arvectum является source of truth. Для Tools не создаётся новый конкурирующий corporate logo.

### Arvectum Tools
Текстовый lockup:

`Arvectum Tools`

- «Arvectum» — основной вес.
- «Tools» — вторичный вес/контраст.
- Не использовать как hero-элемент внутри конкретного utility app.

### Product lockup

`Фото под размер`
`by Arvectum`

`by Arvectum`:
- только одна строка;
- lowercase `by`;
- визуально вторично;
- не превращается в кнопку;
- не ставится внутри основного CTA;
- допустимо на home screen, About, store artwork и loading/error fallback, но не повторяется на каждом блоке.

### App icon family
Иконка каждого Tool:
- одна базовая геометрия контейнера;
- один знак действия;
- без текста;
- без мелких деталей;
- узнаваема в 24–32 px;
- общий акцентный цвет семейства;
- продукт различается знаком, не новой стилистикой.

Для «Фото под размер»: идея знака — прямоугольник/изображение, сходящийся к ограничительной рамке или двум inward-маркерам. Не использовать банальные «молнию», «магическую палочку», фотоаппарат или облако.

---

## 5. Color system v0.1

### Light
- Background: `#F7F8FA`
- Surface: `#FFFFFF`
- Surface subtle: `#F0F2F5`
- Text primary: `#111318`
- Text secondary: `#616975`
- Border: `#D9DEE6`
- Accent / Primary: `#315EFB`
- Accent pressed: `#274DD2`
- Accent soft: `#E9EEFF`
- Success: `#14845A`
- Error: `#B3261E`

### Dark
- Background: `#0D0F12`
- Surface: `#15181D`
- Surface subtle: `#1D2127`
- Text primary: `#F4F6F8`
- Text secondary: `#A8B0BA`
- Border: `#2B3139`
- Accent / Primary: `#7894FF`
- Accent pressed: `#97ACFF`
- Accent soft: `#202B50`
- Success: `#5BC99A`
- Error: `#FFB4AB`

### Rules
- Accent используется только для действия, выбранного состояния и ключевой цифры результата.
- Success — только подтверждение реально выполненной операции.
- Не красить весь интерфейс фирменным цветом.
- Не использовать gradients в v0.1.

---

## 6. Typography

### App UI
Использовать системный Android sans / Roboto через Material typography. Не добавлять внешний font asset в MVP.

### Scale
- Hero value: 32sp / semibold
- Screen title: 24sp / semibold
- Section title: 18sp / medium
- Body: 16sp / regular
- Button: 16sp / medium
- Supporting: 14sp / regular
- Meta / `by Arvectum`: 12–13sp / medium

### Rules
- Размеры файлов всегда таблично читаемы; не смешивать `MB`/`МБ` в одном интерфейсе.
- Для русского UI использовать КБ / МБ.
- Максимум две визуальные иерархии текста внутри одной карточки.

---

## 7. Shape, spacing, motion

### Grid
4dp base grid.

### Screen margins
20dp phone.

### Spacing tokens
4 / 8 / 12 / 16 / 20 / 24 / 32 / 40.

### Radius
- Small control: 10dp
- Card: 16dp
- Main CTA: 16dp
- Modal/bottom sheet: 20–24dp

### Elevation
Минимальная. Предпочтение контрасту surface/background и border, а не теням.

### Motion
- 150–220ms для обычных state changes.
- Compression progress не маскировать fake animation.
- Если операция быстрая, переход сразу к результату.
- Если занимает заметное время — реальный determinate/indeterminate progress без искусственной задержки.

---

## 8. Icon system

- Material Symbols/Icons для стандартных системных действий: share, save, close, info, chevron.
- Собственные продуктовые иконки только для identity.
- Stroke visual weight должен быть единым.
- Не смешивать outline и filled без семантики.
- Filled допустим для selected state.

---

## 9. Core components

### Primary button
- Height: 56dp.
- Full width.
- Accent fill.
- Один главный CTA на screen state.

### Secondary button
- 52–56dp.
- Surface/outline or tonal.

### Size preset chip
- Height: 44–48dp.
- Single-select.
- Selected = accent soft + accent text/border.

### File card
Shows:
- file name (1 line, ellipsis),
- size,
- dimensions,
- optional thumbnail,
- replace/remove action.

### Result card
Hero:
- final size,
- target relation,
- previous size and reduction percentage,
- preview.

### Inline notice
Для PNG transparency, unsupported file, impossible target, storage failure.

### Ads slot
- Только после доступного результата.
- Визуально отделён от product action.
- Никогда не занимает место основного CTA.
- Не показывать пустой контейнер, если ad не загрузился.

---

## 10. Home screen — final v0.1 UX

### Empty state
Top:

`Фото под размер`
`by Arvectum`

Main block:

**Фото должно быть не больше нужного размера?**
Выберите файл — всё остальное приложение сделает само.

Primary CTA:

`Выбрать фото`

Privacy note:

`Изображение обрабатывается на этом устройстве.`

No onboarding carousel. No splash delay.

### Selected state
File card:

`IMG_4821.jpg`
`12,4 МБ · 4032×3024`

Section:

**Не больше**

Chips:
`100 КБ` `500 КБ` `1 МБ`
`2 МБ` `5 МБ` `Свой`

Primary CTA:

`Сделать до 5 МБ`

Secondary text action:

`Выбрать другое фото`

### If file already fits
Replace CTA flow with:

**Уже подходит**
`3,7 МБ ≤ 5 МБ`

Actions:
`Сохранить` / `Поделиться`

No re-encode.

---

## 11. Result screen — final v0.1 UX

Top:

`Готово`

Hero:

**4,73 МБ**
`≤ 5 МБ`

Supporting:

`Было 12,4 МБ · меньше на 62%`

Preview card.

Actions:
1. `Сохранить` — primary.
2. `Поделиться` — secondary.
3. `Ещё фото` — text.

After save:

`✓ Сохранено`

Ad slot appears only below product actions and only if loaded.

---

## 12. Error language

Писать человеческим языком, без технических кодов.

Examples:
- `Не получилось открыть этот файл.`
- `Этот формат пока не поддерживается.`
- `До такого размера уменьшить изображение без серьёзной потери качества не удалось.`
- `Не получилось сохранить файл. Попробуйте выбрать другое место.`

Технический error_code допускается только в аналитике/logging.

---

## 13. Android architecture v0.1

Stack:
- Kotlin.
- Jetpack Compose.
- Material 3.
- One app module.
- One Activity.
- One ViewModel.

Packages:

```
app
├── ui
│   ├── MainScreen
│   ├── ResultScreen
│   └── AppTheme
├── compression
│   └── CompressionEngine
├── storage
│   └── ImageStorage
├── analytics
│   └── Analytics
└── ads
    └── Ads
```

Do not add initially:
- Room,
- Retrofit,
- backend client,
- DI framework,
- WorkManager,
- multi-module architecture,
- generic reusable core.

### Compression approach
1. Check original size.
2. If already within limit, return original reference.
3. Decode safely.
4. Binary-search JPEG quality.
5. If target cannot be met at acceptable quality, reduce dimensions stepwise.
6. Repeat encode/measure.
7. Success only after `actualBytes <= requestedMaximum`.

---

## 14. Analytics v0.1

Events:
- `app_open`
- `file_picker_opened`
- `file_selected`
- `target_selected`
- `compression_started`
- `compression_success`
- `compression_failed`
- `save_clicked`
- `save_success`
- `share_clicked`
- `ad_impression`

Allowed parameters:
- input_format
- input_size_bucket
- target_bucket
- elapsed_ms_bucket
- error_code
- app_version

Never send:
- filename,
- URI,
- local path,
- image hash,
- EXIF,
- preview,
- image content.

---

## 15. Acceptance criteria

### Technical release gate
- 100% successful outputs satisfy requested byte limit.
- Original is never modified.
- Already-fitting images are not re-encoded.
- Core workflow works offline.
- Ad/network failure cannot block the workflow.
- Save and Share work end-to-end.
- No P0/P1 crash in internal test set of at least 100 operations.
- Light/dark verified.
- Large system font verified.

### Product milestones
**M1:** at least one unknown real user installs and completes a successful useful operation.

**M2:** advertising revenue becomes > 0 ₽ in the advertising reporting system.

Internal diagnostic targets:
- `compression_started → compression_success >= 98%`
- `first_open → successful_operation >= 50%`

Retention is secondary for this utility category.

---

## 16. Experiment roadmap

`Concept → MVP → Internal Test → RuStore → Measurement → Decision`

### Concept — DONE
- market check
- Product Contract
- MVP boundaries
- visual direction
- design system v0.1
- UX v0.1
- architecture
- analytics
- acceptance criteria

### MVP v0.2 — FEATURE FROZEN

#### Scope freeze after v0.2
After the initial size-by-bytes flow, only two product additions are allowed before feature freeze:

1. **По размеру**
   - Presets: 600 px / 450 px / 300 px / custom.
   - The number always means the **long side** of a rectangular image.
   - Aspect ratio is preserved.
   - The UI always previews the resulting short side / final WxH before processing.
   - A custom long-side value immediately recalculates and shows the short side.
   - Never upscale an image whose long side is already below the requested value.

2. **На паспорт**
   - User-facing name: "На паспорт".
   - Subtitle/context: "Для заявления на Госуслугах".
   - One shared technical preset for passport / international-passport online application where the upload requirements overlap.
   - Fixed crop ratio: 35:45 (7:9), adjusted manually by the user; no face detection.
   - Output: JPEG.
   - Target density: 450 DPI (above the 300 DPI minimum) with matching resolution metadata.
   - Target pixel dimensions derived from 35×45 mm at 450 DPI: approximately 620×797 px.
   - Keep the output within the portal's accepted file-size range; never trade the required geometry/DPI for a smaller file.
   - The app changes only technical parameters and crop. No AI, retouching, background replacement, face/body modification, beauty processing or content generation.
   - The app does **not** claim to verify pose, facial geometry, expression, background or other visual eligibility requirements; it only prepares the technical file.

After these two additions, «Фото под размер» is feature-frozen for the first market experiment. Any further unrelated user need must be evaluated as a separate Arvectum Tool rather than added to this app.

**Implementation status (2026-09-24): DONE.** All three user modes are implemented: «По весу», «По размеру», «На паспорт». The Android build passes assembleDebug, lintDebug and unit tests. Next gate: real-device functional testing; no new product features are allowed before measurement.

First functional increment completed locally:
- Android project: Kotlin + Compose + Material 3.
- System image picker without broad gallery permission.
- Preset/custom target selection.
- Local JPEG compression with byte-limit verification.
- JPEG/PNG/static WebP input; PNG transparency flattened to white when compression is required.
- EXIF orientation handling.
- Already-fitting files are not re-encoded.
- System Save and Share.
- Light/dark Precision Utility theme.
- No backend, analytics, ads, or INTERNET permission yet.
- `assembleDebug + lintDebug + test` passes; Android Lint reports no issues.

Next: real-device functional test matrix before adding analytics/ads.

### Internal Test
Real-device matrix, 100+ image operations, privacy/compliance check, production ad configuration.

### RuStore
Store card, screenshots, build upload, moderation, launch.

### Measurement
Traffic → installs → useful operations → crashes → reviews → ad revenue.

### Decision
Continue / iterate / archive based on evidence, not sunk cost.

---

## 17. Non-goals / guardrails

- Do not integrate with Arvectum OS without demonstrated need.
- Do not import Arvectum Company governance into the app.
- Do not create a portfolio platform before repetition is proven.
- Do not add features because competitors have them.
- Do not block utility behind ads.
- Do not require registration.
- Do not upload user images to a server.
- Do not count release itself as product success.
