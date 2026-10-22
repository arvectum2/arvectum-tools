# Ухват: PhoneCaptures FileProtection — физическая приёмка 22.10.2026

## Аппаратура и безопасность
- Реальный iPhone 13, iOS 27.0.1; Mac mini, Xcode 27.1.
- Только подписанное изолированное QA-приложение ru.arvectum.tools.what.fileprotectqa и временные UUID-каталоги.
- Аудио генерировалось из синтетических PCM-буферов через MicrophoneCapturePipeline/AVAudioFile, без микрофона, камеры и чтения личных записей. Публичное приложение, Watch pairing, радио, TestFlight и App Store Connect не менялись.
- Диагностика: ArvectumSSD/Arvectum/tmp/what-phonecaptures-protection-20261022/DevicePhoneCapturesProtection.xcresult и DevicePhoneCaptureCombinedFinal.xcresult.

## Реализовано
1. PhoneCaptureStorage.prepare создаёт Application Support/What/PhoneCaptures, защищает папку классом NSFileProtectionCompleteUntilFirstUserAuthentication и метаданными обновляет существующие регулярные файлы, включая неполные AAC/JSON. Содержимое не декодируется, не перемещается и не удаляется.
2. Более строгий уже существующий NSFileProtectionComplete не ослабляется. При отказе в миграции ни новая запись, ни автоматический импорт прежнего аварийного AAC не начинаются.
3. Manifest до старта микрофона и после Stop атомарно записывается с completeFileProtectionUntilFirstUserAuthentication (включая новый inode после atomic-write).
4. AVAudioFile writer и новый AAC получают защищённый класс перед installTap/AVAudioEngine.start. В случае ошибки writer закрывается, старт отклоняется; данные пользователя не коммитятся частично.
5. Только в XCTest контроллер получает изолированный captureDirectory. Прежнее производственное расположение Application Support не меняется.
6. Синтетический playable AAC после сценария crash принят с прежним UUID один раз, оригинал удалён только после durable repository commit. Нечитаемая временная запись вместе с manifest сохранена без ложного импорта.

## Аппаратная приёмка
- Адресный запуск: 5/5 PASS, DevicePhoneCapturesProtection.xcresult.
- Финальный объединённый XCTest на физическом iPhone 13: 132 tests executed, 0 FAIL, 3 expected SKIP, DevicePhoneCaptureCombinedFinal.xcresult. В том числе 7 новых PhoneCaptureStorageTests, 81 RecordingRepositoryTests, 15 WatchA2ReliabilityTests, 18 VideoCaptureRecoveryTests, 11 LocalNoteRepositoryTests.
- Проверены legacy AAC/JSON и неполные копии с побайтовым сравнением; два атомарных сохранения manifest; декодируемый AAC; симулированная ошибка прав; восстановление/идемпотентность; нечитаемая запись; сохранение более строгого Complete; запрет импорта при отказе защитить legacy.
- Python core: 40 тестов PASS, архитектурный контракт PASS.

## Осталось
Не проверялись до-первой-разблокировки после настоящего reboot, реальный звонок и microphone interruption, OS power-kill, реальный ENOSPC, Watch фон/радиосвязь, VoiceOver rotor/gestures, резервное восстановление encrypted iOS backup и длительная запись на микрофон. Это отдельные приёмочные ворота.

## Backup
Исходники и manifest в Application Support не исключены из штатных резервных копий устройства. Отсутствует собственная серверная выгрузка: local-first не означает, что данные не войдут в настроенный пользователем iCloud или локальный device backup.
