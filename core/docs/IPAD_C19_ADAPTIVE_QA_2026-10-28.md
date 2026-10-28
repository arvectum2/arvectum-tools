# C19 — реальный iPad Simulator для адаптивного UI, 28.10.2026

## Окружение и граница

- Mac mini, Xcode 27.1, **iPad Air 11″ (M3) iOS 27.0 Simulator**, UDID `A6ED0363-25C2-4B2B-BFE5-38BBC7E04EB8`.
- Никаких физических iPhone, Apple Watch, iPad, пользовательских файлов, камер, уведомлений и HealthKit; Apple Store Connect/релизы не менялись.
- Ранее заблокированное на ограниченном iOS 27.1 runtime создание iPad заменено **реальным доступным iPad iOS 27.0 runtime**. Это не подтверждает, что ограниченный runtime 27.1 исправлен.

## Native XCTest, не скриншот и не статическая проверка

| Приложение | Проверка | Результат |
| --- | --- | --- |
| Ухват | `CaptureFirstUITests.testIPadLandscapePreservesCaptureTextEditorAndLibrary` | PASS, 17.340 сек |
| Ухват | `CaptureFirstUITests.testIPadRotationPreservesVisibleCaptureAndTextControls` | PASS, 13.679 сек |
| ChickMark | `AdaptiveLayoutUITests.testCreateHabitAndKeepItAcrossOrientationChanges` | PASS, 13.452 сек |
| ChickMark | `HabitFlowUITests.testReminderIsVisibleWithBothDisclosuresClosed` | PASS, 7.903 сек |
| Фото/PDF под размер | `AdaptiveLayoutUITests.testTaskRemainsAvailableAfterOrientationChange` | PASS, 10.903 сек |

- **Ухват 2/2, ChickMark 2/2:** итоговый `xcodebuild ** TEST SUCCEEDED **`, exit code 0.
- **Фото/PDF 1/1:** XCTest вывел `Test Suite 'Selected tests' passed` и `Executed 1 test, with 0 failures`, но `xcodebuild` завис на завершающем этапе более 3 минут. После проверки полного XCTest PASS был остановлен **только этот запущенный QA-процесс**; честный статус — test-case/suite PASS, **не** `xcodebuild TEST SUCCEEDED`. Ни один файл или данные симулятора не удалялись.
- Встроенная команда CI теперь запускает выделенный `xcodebuild` как собственную группу процессов; требует все точные `Test Case ... passed`, `Selected tests passed` и `Executed N tests, with 0 failures`. Она ограниченно завершает только зависшее закрытие процесса после grace, отдельно печатая, что чистый exit не подтверждён. Если нет полного доказательства, получено хотя бы одно падение или истёк срок до XCTest PASS — CI FAIL. iPhone как подмена iPad запрещён.

## Закрываемые и открытые пункты

- [x] Ухват — iPad portrait/landscape базовый захват, видимость кнопок и редактора, переходы в библиотеку и назад: native simulator PASS.
- [x] ChickMark — создание привычки с поворотом, видимые настройки напоминания в закрытой форме: native simulator PASS.
- [x] Фото/PDF — адаптивность основной задачи/предпросмотра и футера при повороте: XCTest PASS, teardown blocker зафиксирован.
- [ ] Ухват — Split View/Stage Manager, камера/mic, реальный iPad, Watch ACK и прерывания: не проверены.
- [ ] ChickMark — реальные iOS notification permission/delivery, HealthKit, CloudKit, Watch: не проверены.
- [ ] Фото/PDF — реальные Files/Photos/HEIC/EXIF, Yandex ad fill, ATT/privacy: не проверены.
- [ ] GitHub iPad-matrix CI: результат нового PR проверяется отдельно; локальные PASS не объявляются GitHub PASS.

Локальные исходные журналы: `/Volumes/ArvectumSSD/Arvectum/tmp/roadmap-c19-devicefree/what-ipad.log`, `chick-ipad.log`, `photo-ipad.log`; exit-status markers для первых двух равны `0`.
