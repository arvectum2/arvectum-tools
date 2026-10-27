# C16 — техническая приёмка ASO-карточек, 27 октября 2026

Среда: Mac mini, Xcode 27. Никаких изменений App Store Connect, TestFlight, рабочего сайта или персональных данных.

## Локальные проверки

| Проверка | Результат |
| --- | --- |
| Core Python: 82 теста | PASS |
| Core Swift: 21 тест | PASS |
| 197 каталогов, 10 259 строк, 4177 риск-чувствительных строк | PASS: 0 структурных ошибок |
| ASO: 64/64 текста, 448/448 native PNG по SHA/размерам | PASS |
| 144 iPad JPEG (192 региональных слота), исходные native UI PNG проверены | PASS |
| Фото/PDF: ImageEngine, PDF, импорт/экспорт, layout/compression/navigation | PASS |
| Pushkin: local storage, Shortcuts payload, onboarding | PASS |
| Ухват: WatchA2ReliabilityTests | PASS |
| ChickMark: core unit/integration | PASS |
| ChickMark Release-архив 1.5.2 (20): приложение, Watch, iOS Widget, Watch Widget | PASS |
| ChickMark Privacy manifests: 4 bundles, tracking=false, collected_types=0 | PASS |
| 16 публичных App Store storefronts × 4 Apple ID | PASS (Apple Lookup read-only) |

Четыре набора Xcodebuild iOS Simulator завершились TEST SUCCEEDED, одноразовый iPhone 18 Pro iOS 27.0. ChickMark Release Archive успешно собран без подписи. Release hygiene и audit_archive.py завершились успешно, errors пуст.

## Исправление GitHub CI

Исходный Habits run 40546355039: unit/integration и essential UI smoke успешно прошли, но архивирование прервано **общим лимитом 35 минут**. Статус CANCELLED — не ошибка логики приложения.

Workflow habits-ios-ci.yml разделён на независимые jobs: build-and-test (45 минут) и archive-smoke (25 минут). Архивный job имеет собственный лимит шага 20 минут. Это устраняет зависимость архивирования от времени предыдущих UI-тестов. Полная приёмка GitHub CI требует зелёного результата на коммите с исправлением.

## Открытые релизные зависимости

- [ ] Авторизованный App Store Connect read-only diff: keywords, screenshots, subtitles, build ID и App Privacy.
- [ ] Подписанный Release Candidate и QA на реальных iPhone/iPad/Watch (HealthKit, запись, Files, VoiceOver, реклама).
- [ ] По необходимости независимое подтверждение native-speaker/legal.
- [ ] Явное разрешение владельца для конкретного build/asset hash на обновление опубликованных App Store карточек.

В проверке Apple Devices физический iPhone 13 доступен по паре, Watch недоступен. На личный iPhone ничего не устанавливалось. Созданный архив не подписан для распространения. Эти ограничения нельзя выдавать за пройденные проверки.

[C16 Apple Lookup](ASO_C16_PUBLIC_STORE_QA_2026-10-27.md) · [C15 редактура и ассеты](ASO_C15_EDITORIAL_ACCEPTANCE_2026-10-27.md).
