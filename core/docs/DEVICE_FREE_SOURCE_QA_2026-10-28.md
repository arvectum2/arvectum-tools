# Arvectum Tools · автономная проверка приложений без iPhone/Watch · 28.10.2026

## Scope

Весь цикл выполнялся на Mac mini / iOS Simulator / GitHub Actions / публичном read-only Apple Lookup. На личных iPhone и Apple Watch **не запускали** тесты, не создавали медиа, не меняли системные настройки, не удаляли историю. В App Store Connect, TestFlight и опубликованные карточки ничего не отправляли. Коды исходников и публичные бинарники различать.

## Проверенный результат

| Приложение | Device-free QA | Результат | Осталось |
| --- | --- | --- | --- |
| Фото/PDF (iOS) | `DocumentPhotoPresetTests`, `ImageEngineTests`, `PDFEngineTests`, `ImportExportIntegrityTests` | **27/27 PASS**, исходные файлы не переписываются, размеры/ориентация/пресеты | реальный Files/Photos/HEIC/EXIF и рекламный SDK |
| Фото/PDF (UI) | `WorkflowUITests`: loaded ad, no-fill, ad-consent доступность | **3/3 PASS**, `TEST SUCCEEDED` | реальные запросы РСЯ, ATT и privacy manifest/App Store questionnaire |
| ChickMark | `HabitFrequencyTests`, `HabitReminderSchedulerTests`, `GentleRestartTests` | **41/41 PASS**, overdue, repeat от фактической отметки, планировщик и мягкий рестарт | реальные нотификации/HealthKit/CloudKit/Watch |
| ChickMark | `HabitFlowUITests.testReminderIsVisibleWithBothDisclosuresClosed` из PR #158 | **1/1 PASS**, настройка видна в расписании | physical consent/отказ и реальное сохранение времени |
| Pushkin | iOS 17 deployment target compile; `ArvectumNotifyTests` + `MinimalUXUITests` | **BUILD SUCCEEDED**, **30 unit + 1 UI PASS** | runtime iOS17–26 и реальный Shortcuts/data migration; PR #160 DRAFT |
| Ухват | актуальный source PR #157 + более ранние device QA | **35/35 Simulator PASS**, кнопка и Watch foreground route ранее приняты | полностью фоновая доставка и прерывания без устройств не подтверждаются |
| Фото/PDF Android | PR #129: Gradle 9.8.2 + SHA-256, GitHub verify | **GitHub 2/2 verify PASS; merged** | локальный JDK отсутствует; реальные Android devices не тестировали |
| APL iOS | PR #265: theme System/Light/Dark + urls + build QA | **21/21 GitHub checks PASS; merged** | публикация и физическая QA 0.1.38 — отдельно |
| Where? | PAUSED | MVP не начат по решению владельца | не считать запуском продукта |

### App Store — C18

64/64 отдельных read-only Lookup: Фото/PDF **1.0.4**, Pushkin **1.0.3**, Ухват **1.1.2** опубликованы во всех 16 регионах. ChickMark пока **1.5.2** (не 1.5.3). Детали/скриншоты/языки: [C18](ASO_C18_PUBLIC_STORE_QA_2026-10-28.md).

### Строгие границы

- Успешная сборка с `IPHONEOS_DEPLOYMENT_TARGET=17.0` не является проверкой запуска Pushkin на старом OS runtime. В macOS/Xcode установлены только iOS 27 Simulator runtimes.
- `loaded ad` / `no-fill` — синтетические состояния UI, **не реальные показы РСЯ и не доказательство отсутствия tracking**.
- Часы/телефон забраны владельцем: физические Watch/HealthKit/Background и Shortcuts тесты умышленно не запускались.
- `main`, PR, релиз App Store — отдельные состояния. Новая версия не отправляется без per-release approval, согласно `AGENTS.md`.

## Локальные QA-журналы

`/Volumes/ArvectumSSD/Arvectum/tmp/portfolio-devicefree-20261028/`: `apple-individual-64.json`, `photo-contracts.log`, `photo-adsim.log`, `chickmark-interval-source.log`, `chickmark-ui.log`, `pushkin-ios17-compile.log`, `pushkin-target17-tests.log`. Отдельные подписи/ссылки/аудио из личных приложений не выгружались.
