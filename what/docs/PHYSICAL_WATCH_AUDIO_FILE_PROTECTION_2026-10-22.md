# Ухват · физический iPhone 13 — Watch AAC / index FileProtection, 22.10.2026

## Изоляция
Физический iPhone 13, iOS 27.0.1, Mac mini/Xcode 27.1. Только тестовый app ru.arvectum.tools.what.fileprotectqa с собственными временными UUID-каталогами и синтетическими аудиобайтами. Личные AAC, MOV, записи, production bundle, Watch pairing/радио и пользовательские разрешения не изменяли.

## Реальный воспроизводимый дефект
1. Начальный тест нового AAC от локального тестового источника с обычной защитой был PASS: источник и индекс унаследовали системный CompleteUntilFirstUserAuthentication.
2. При намеренном создании исходного временного файла с NSFileProtectionNone физический тест на iPhone дал **FAIL**: скопированный AAC тоже имел NSFileProtectionNone, хотя должен быть CompleteUntilFirstUserAuthentication. Это не гипотеза: DeviceUnprotectedSourceRetry.xcresult, одна ошибка для нового UUID.m4a.
3. В коде RecordingRepository.persistIncomingFile защита теперь применяется **на временном inode до атомарного move в Audio/**. Если изменение атрибута не удалось, ошибка прерывает импорт, cleanup удаляет приватный staging, прежний оригинал сохраняется, индекс/ACK не создаются.
4. Записи recordings.json используют атомарную protectedJSONOptions (CompleteUntilFirstUserAuthentication). При открытии старого синтетического unprotected index защита мигрирует только атрибутами, исходные байты JSON остаются идентичными.

## Физические результаты после исправления
- DeviceAfterFixProtection.xcresult: 1/1 PASS (новый AAC от заведомо незащищённого временного источника + индекс).
- DeviceAudioIndexFullProtection.xcresult: **3/3 PASS** — protected audio/index, legacy index migration с неизменными байтами, fail-closed при отказе в защите staging.
- DeviceRepositoryAndWatchRegression.xcresult: **95 tests, 0 FAIL, 3 expected SKIP**, включая полный RecordingRepositoryTests и WatchA2ReliabilityTests. Проверены сохранность аудио/текстов, восстановление после разрывов commit и защита ACK.
- Артефакты: ArvectumSSD/Arvectum/tmp/what-audio-index-protection-20261022. Исходные записанные аудиофайлы не копировались на Mac.

## Границы результата
Это физическая проверка класса файловой защиты и логики после первого unlock. Не выполнены reboot до первой разблокировки, реальный фон WatchConnectivity, физический radio offline/reboot Watch, независимая миграция старых AAC/MOV и полная backup-policy. Старые пользовательские аудиофайлы не сканировались и не трогались. App Store/TestFlight не затрагивали.
