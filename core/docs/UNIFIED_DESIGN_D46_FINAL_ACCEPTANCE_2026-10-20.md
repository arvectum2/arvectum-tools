# D4.6 — Итоговая внутренняя приёмка Arvectum Tools

Дата: 20.10.2026. Ветка: feature/unified-design-system-20261019. Отдельный worktree на ArvectumSSD. База main: b3eb81b. До этой приёмки HEAD ветки: 38b7391.

## Что закрыто в этом проекте

| Этап | Подтверждённые изменения | Отчёт |
| --- | --- | --- |
| D0—D3 | Семантические Core-токены, более честный UX Pushkin, фиксированный Save CTA Фото/PDF, видимые видео/текст Ухвата, точный прогресс ChickMark, основные аудиты доступности, отдельные iPad и VoiceOver сценарии | UNIFIED_DESIGN_CODE_2026-10-19.md, UNIFIED_DESIGN_ACCEPTANCE_2026-10-20.md |
| D4.1 | Реальное использование общих размеров/цветов в 4 приложениях, адаптивное пустое состояние ChickMark | UNIFIED_DESIGN_D4_TOKEN_INTEGRATION_2026-10-20.md |
| D4.2 | Названия режимов Фото/PDF и RU/EN имена для VoiceOver | UNIFIED_DESIGN_D4_PHOTO_MICROCOPY_2026-10-20.md |
| D4.3 | Планировщик групп Pushkin RU/EN, контраст и семантика ChickMark One-off, доступность TextEditor Ухвата | UNIFIED_DESIGN_D43_SECONDARY_SCREENS_2026-10-20.md |
| D4.4 | Gentle Restart ChickMark off/on, большие размеры и короткое название, локали | UNIFIED_DESIGN_D44_GENTLE_RESTART_ACCESSIBILITY_2026-10-20.md |
| D4.5 | Ухват: читаемая диагностика и фактически не real-time отчёт Watch | UNIFIED_DESIGN_D45_WHAT_DIAGNOSTICS_2026-10-20.md |

Не выкидывать промежуточные отрицательные QA-логи: они показывают исправленные дефекты. Финальный PASS подтверждать только независимыми завершающими прогонами.

## Свежие контрольные проверки D4.6

Журналы на Mac mini: /Volumes/ArvectumSSD/Arvectum/tmp/arvectum-tools-design-qa-20261019/.

| Критерий | Лог | Итог |
| --- | --- | --- |
| SwiftPM ArvectumCore | design-final-core.log | **21/21 unit PASS** |
| Pushkin iOS Simulator Debug | design-final-build-pushkin.log | **BUILD SUCCEEDED** |
| ChickMark iOS Simulator Debug | design-final-build-chickmark.log | **BUILD SUCCEEDED** |
| Фото/PDF iOS Simulator Debug | design-final-build-photo.log | **BUILD SUCCEEDED** |
| Ухват iOS Simulator Debug | design-final-build-what.log | **BUILD SUCCEEDED** |
| ChickMark Gentle Restart OFF и ON: iPhone 17 Pro Simulator, тёмная тема, Increase Contrast, AXXXL | design-final-dark-chickmark.log | **2/2 full system AX audits PASS** |
| Ухват Diagnostics: тот же iPhone, тёмная тема, Increase Contrast, AXXXL, сверху и после прокрутки до Watch | design-final-dark-what.log | **1/1 full system AX audit PASS** |
| Изменённые RU/EN/ES локализации ChickMark и RU/EN Фото/PDF | macOS plutil -lint | **5/5 OK** |
| git diff --check main...HEAD | Git | **PASS** |

В рамках full system AX аудитов проверены sufficientElementDescription, hitRegion, trait и textClipped. Это **не полный физический VoiceOver**. По завершении QA свой iPhone-симулятор возвращён к light, Increase Contrast disabled, размеру текста large. VoiceOver выключен, громкость Mac mini — 0.

## Ворота, которые нельзя честно назвать закрытыми

**G1 — физический VoiceOver.** Реальный ротор, жесты, порядок фокуса, модальные переходы и весь пользовательский цикл на физическом iPhone/iPad. Автоматический XCTest accessibility audit и короткие озвученные simulator-сценарии не эквивалентны этой проверке. Принимать только на отдельном QA bundle/fixture, не уничтожая личные данные.

**G2 — системные интеграции и данные.** Pushkin: отдельная безопасная Shortcuts automation → настоящее уведомление → история, без правки существующих automation; Apple sign ранее возвращал 500/504. Фото/PDF: реальный Files/Photos import/export, HEIC, большие повёрнутые PDF и live РСЯ consent/no-fill. ChickMark: реальный HealthKit revoke/regrant, CloudKit/Watch и сохранность истории при обновлении. Ухват: долгие записи и необъяснённая остановка около 340 секунд, физические Watch offline/reboot/ACK, звонки/разрешения и сохранность оригинальных медиа. Нельзя устраивать ENOSPC/стресс на личном устройстве.

**G3 — матрица устройств/состояний.** iPad Split View/Stage Manager, реальный Duo fold/unfold, Reduce Motion и контраст/AXXXL во всех второстепенных представлениях; текущие тёмные аудиты охватывают только указанные экраны.

**G4 — интеграция и релиз.** Независимый diff/code review и визуальная приёмка 67 изменённых файлов. Pushkin и ChickMark используют общие Core SwiftUI-исходники напрямую через XcodeGen, Фото/PDF и Ухват через SwiftPM; интеграция единым способом — отдельная возможная инфраструктурная задача. MAIN не обновлять без согласованной интеграции; TestFlight, App Store Connect, resubmit и публикация требуют отдельного явного разрешения для каждого релиза. Никакой релиз в рамках этого этапа не выполнялся.

**G5 — Where?** Продукт остаётся на ранее утверждённой паузе и не входит в эту приёмку.

## Решение

**Внутренний симуляторный и unit-этап D0—D4.6: принят по документированным сценариям.** Технически готово к независимому review feature-ветки, но **не к автоматическому merge/release**. Открытые физические и системные ворота G1—G4 не подменяются зелёными симуляторными тестами. Первичный реестр незакрытых требований — продуктовые ROADMAP.md; данный акт служит сводкой и не отменяет их.
