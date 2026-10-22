# Ухват — физическая приёмка защиты файлов и восстановления, 22.10.2026

## Изоляция и оборудование

Физический iPhone 13, iOS 27.0.1, Mac mini / Xcode 27.1. CoreDevice сообщает available (paired), Developer Mode enabled, unlockedSinceBoot=true.

Создана новая независимая iOS QA-сборка по what/ios/project.file-protection-qa.yml: app ID ru.arvectum.tools.what.fileprotectqa, отдельные test ID и DEBUG REVIEW_HANDOFF_QA. Watch companion отсутствует; WatchConnectivity не запускается. Исходники — актуальный main (c1e5544). Production ru.arvectum.tools.what, старые QA-бандлы, личные заметки, аудио/видео, Shortcuts и системные настройки не изменяли.

Файловые тесты создают отдельные временные UUID-каталоги в QA sandbox и удаляют лишь собственные файлы. UI использует две Debug-синтетические расшифровки. Никакой личный контент с устройства на Mac не копировался.

## Результат: 18 / 18 PASS, 0 FAIL

| Пакет | Аппаратные тесты | Результат |
| --- | --- | --- |
| L4.18b: FileProtection | 3 XCTest: основная и резервная расшифровки; tombstone удаления; побайтовая сохранность legacy-файлов при миграции | 3/3 PASS: физический NSFileProtectionKey = completeUntilFirstUserAuthentication |
| L4.17b: Recovery UI | 5 XCUITest: отсутствующая, повреждённая, пустая копия; здоровый основной каталог; Cancel → Confirm → healthy | 5/5 PASS; восстановление не предлагается там, где оно небезопасно |
| L4.19: atomic writes | 5 XCTest: остановка до backup, после backup, после primary, при авто-распознавании и удалении | 5/5 PASS; тестовые аудио и существующие транскрипции сохранены, удалённый UUID не возвращается |
| P0 UI/AXXXL физический экран | 5 XCUITest: Home, аудио без микрофона, видео без камеры, редактор текста, меню локализации/настроек при максимальном шрифте | 5/5 PASS; работающие кнопки/подписи и безопасное закрытие |

Все четыре отдельных запуска xcodebuild test завершились exit 0 / TEST SUCCEEDED. Артефакты только на ArvectumSSD:
- Arvectum/tmp/what-file-protection-physical-20261022/DeviceFileProtection.xcresult
- Arvectum/tmp/what-file-protection-physical-20261022/DeviceRecoveryUI.xcresult
- Arvectum/tmp/what-file-protection-physical-20261022/DeviceInterruptedStorage.xcresult
- Arvectum/tmp/what-file-protection-physical-20261022/DeviceAccessibilityAXXXL.xcresult

## Не закрытые аппаратные ворота

- Первая разблокировка после настоящей перезагрузки: НЕ ПРОВЕРЕНА (unlockedSinceBoot=true).
- Эти тесты подтверждают класс защиты трёх JSON, но не отдельную защиту AAC/MOV, остальных индексов, local-notes и правила системных backup.
- Debug checkpoints бросают исключения на настоящем iPhone, НЕ имитируют фактическое отключение питания, аппаратный crash, реальный ENOSPC или критическую системную блокировку.
- Не проводились в этот раз Watch offline/reboot, фоновая WCSession-доставка, 30–120 минут видео, звонки и полноценный VoiceOver rotor/gestures. Ранее подтверждённые отдельно 420 сек foreground видео и lost ACK от 19.10 не подменяются этим прогоном.
- Не отправляли ничего в App Store Connect и TestFlight. Каждая будущая публикация требует явного отдельного разрешения.

Следующее: safe locked/unlocked QA, реальный VoiceOver, неразрушающий reboot/unlock протокол, Watch background/offline и отдельное stress-устройство для ENOSPC/аварийного завершения.
