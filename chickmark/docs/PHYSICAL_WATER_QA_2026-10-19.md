# ChickMark CM18-3 — 19.10.2026, физический iPhone 13, новая regression QA

## Отдельная физическая QA-сборка

- iPhone 13, iOS 27.0.1, Mac mini/Xcode 27.1, Apple Development signature.
- Использован *только* независимый QA-bundle `ru.arvectum.tools.chickmark.waterqa`, версия **1.5.0 build 202**, обновление поверх QA build 201 без удаления production ChickMark, Watch data, CloudKit/SwiftData пользователя или реального личного приложения.
- Исходник [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94) после `b673339`, включающий три новых unit сценария. `project.water-physical-qa.yml` изменён только для номера изолированной QA-сборки.
- Изоляция UI тестов через `--ui-testing` и DEBUG-only принудительный отказ, *без* реальной авторизации/записи Apple Health в этом прогоне. Проверка отката и сбоя использовала `FakeWaterHealthDriver`.

## Доказательство

- `xcodebuild build-for-testing`: **TEST BUILD SUCCEEDED**, signed physical arm64.
- `test-without-building`, точные наборы `WaterExportSyncTests` и `WaterExportSettingsUITests`: **15/15 PASS**, 0 skipped, 0 failures: **13 unit + 2 UI**.
- Среди unit PASS: `testWaterCheckinsEditUndoAndReentryKeepOneOwnedDailySample`, `testRevokedWritePermissionPreservesReceiptUntilRegrant`, `testTwoDaysExportIndependentlyAndUndoOnlyTargetDay`, безопасный replay после interruption и idempotence.
- Среди UI PASS: `testDeniedPermissionDoesNotPersistOptInOrOpenHealth` и `testQuantityHabitHasWaterExportScreenButNoAutomaticPermission`.
- Сохранённый ранее одноразовый HealthKit QA journal **побайтово/семантически не изменился** после этого теста: `stage=completedClean`, `ownDeletionCompleted=true`, `residualOwnSamples=0`; никаких новых live-образцов не создавали. Ранее, 18.10.2026, настоящий тестовый 250 мл sample был создан и удалён с 0 residual. Сведения и права пользователя Health не читались.

Логи и xcresult только на ArvectumSSD:
`/Volumes/ArvectumSSD/Arvectum/tmp/chickmark-water-physical-20261019`.

## Открыто перед merge feature → main и App Review

- [x] Внутренняя логика 13 focused mock-sync + 2 UI на физическом iPhone без побочных эффектов
- [x] Одноразовый реальный HealthKit QA write + удаление своего образца с 0 residual (18.10)
- [ ] Приёмка **настоящего интерфейса привычек**: несколько check-ins → изменение объёма → undo с реальным HealthKit, только в контролируемой новой disposable QA истории
- [ ] Физическое revoke→regrant в iOS Settings и persistence retry; в текущих 15 тестах этот сценарий доказан **только mock-драйвером**
- [ ] Safe upgrade личного production ChickMark/Watch/CloudKit без потери данных
- [ ] Отдельное решение о релизе, App Store категория Productivity в новой редактируемой версии; текущая публичная версия остаётся 1.5.0 Health & Fitness

**Не загружено** в App Store Connect и не отправлялось на ревью.
