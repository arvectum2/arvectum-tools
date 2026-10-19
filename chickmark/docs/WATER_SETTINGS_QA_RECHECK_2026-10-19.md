# ChickMark — изолированный consent UI QA, 19 октября 2026

**iOS 27 Simulator: 2/2 tests PASS**, 0 ошибок, 41.252 секунды. Использован только ru.arvectum.tools.chickmark.waterqa с DEBUG --ui-testing --disable-cloud-sync --seed-water-settings-demo. Запись или чтение Apple Health samples в этих тестах отключена.

- testDeniedPermissionDoesNotPersistOptInOrOpenHealth: OFF by default, явное включение, гарантированный DEBUG отказ, после Cancel повторно OFF.
- testQuantityHabitHasWaterExportScreenButNoAutomaticPermission: переход через реальное меню количественной привычки, явное включение, Cancel без автоматического запроса HealthKit.
- Артефакты: /Volumes/ArvectumSSD/Arvectum/tmp/chickmark-water-priority-20261019/water-consent-sim.log и WaterConsentSimulatorRegression.xcresult; exit 0, TEST SUCCEEDED.

**Физический UI на iPhone 13: НЕ ПРОЙДЕН.** Два запуска XCTest Runner завершились ошибкой системного режима автоматизации Timed out while enabling automation mode до первого assertion. Первый прогон был прерван, второй точечный остановлен после того же тайм-аута. Это ограничение запуска iOS XCTest, а не доказанный дефект/успех реального UI.

Предыдущее независимое физическое испытание HealthKit с отдельным QA bundle (см. PHYSICAL_WATER_EDIT_UNDO_2026-10-19.md) подтвердило 250→500→0→750→0 мл и очистку только собственных samples. Оно НЕ проверяло живой UI вместе с реальной авторизацией.

**Открыто:** настоящий check-in/edit/undo + revoke/regrant в системных настройках на iPhone, CloudKit двух устройств, Watch sync, безопасное обновление публичного приложения. Пользовательская база и HealthKit не изменялись этим UI прогоном. Новый App Store билд не отправлялся.
