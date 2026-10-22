# D4.5 — Ухват: доступная диагностика синхронизации

Дата: 20.10.2026. Ветка feature/unified-design-system-20261019; worktree на ArvectumSSD.

## Выявлено

На действительно форсированном SwiftUI AXXXL были обрезаны название «Диагностика синхронизации», строка «С расшифровкой» и другие подписи ограниченных строк List. Полный системный XCUIAccessibilityAudit (description, hitRegion, traits, textClipped) первоначально FAIL: design-d45-what-diagnostics-audit.log, промежуточный design-d45-what-diagnostics-v2.log. Зависший тест v2 остановлен отдельно; на остальные симуляторы не воздействовали.

## Исправлено

- Только при Accessibility Dynamic Type: ScrollView вместо List, три самостоятельные карточки отчёта с естественным переносом длинных подписей и данных, заголовок полной длины в содержимом и кнопка закрытия 64 pt с прежними VoiceOver-подписью и идентификатором syncDiagnosticsClose.
- Обычный размер текста оставляет исходный нативный List, три Section, LabeledContent, UINavigationBar и кнопку «Готово».
- Метрики количества записей/аудио, расшифровок, p95 скорости запуска записи и последнего отчёта часов берутся из прежних PhoneStore и CaptureLatency: никаких изменений в сохранении, передаче или синхронизации Watch нет.
- Пояснение об отчёте Watch остаётся точным: это последний полученный отчёт, не проверка соединения в реальном времени.

## Фактические проверки

- iPhone 17 Pro Simulator iOS 27, AXXXL, синтетический заполненный Inbox: testPopulatedLibraryDiagnosticsAXXXLSystemAccessibilityAudit **PASS** (design-d45-what-diagnostics-v3.log, exit 0). Системный аудит выполнен дважды: сразу после открытия и после прокрутки до последнего блока Apple Watch; обе проверки включали все четыре категории. Предупреждение о неактуальности отчёта проверено.
- При стандартном размере: testEnglishDiagnosticsAndSettingsMenu **PASS**, testRussianDiagnosticsAndSettingsMenu **PASS** (design-d45-what-normal-regression.log, exit 0). Проверены меню настроек, заголовок, закрытие и возвращение в библиотеку.
- Все UI проверки выполнялись на QA-симуляторе, без реальных микрофона, камеры и часов. История сохранённого состояния Watch может различаться между запусками, поэтому тест требует честного пояснения, а не определённого значения счётчика.

QA-логи: /Volumes/ArvectumSSD/Arvectum/tmp/arvectum-tools-design-qa-20261019

## Открыто

Реальный VoiceOver (ротор, жесты, фокус), iPad Split View, подтверждение Watch ACK и соединения, разрешения медиа, реальные пользовательские файлы и релизная проверка. Merge/push и TestFlight/App Store без отдельного разрешения не выполнялись.
