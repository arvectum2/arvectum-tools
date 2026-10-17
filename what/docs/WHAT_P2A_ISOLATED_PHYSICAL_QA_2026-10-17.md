# Ухват — независимая физическая QA текстовых и видеозаметок (2026-10-17)

## Изоляция

- QA-ветка: qa/what-multimodal-physical-20261017, ответвление от integration/what-multimodal-watch-20261017. НЕ включать QA-конфиг в релиз.
- Новое независимое приложение: «Ухват P2a QA» с идентификатором ru.arvectum.tools.what.p2aqa. Оригинальный Ухват ru.arvectum.tools.what и проверенный Ухват QA ru.arvectum.tools.what.qa, а также их хранилища — без изменений.
- Отдельный URL scheme whatp2aqa://record; phone widget использует тот же URL.
- **Watch app в этой сборке отсутствует**: сначала проверяем iPhone-текст и iPhone-видео, часы не трогаем. Watch-интеграция — отдельный этап после физической приёмки.
- Внутренние PRODUCT_NAME оставлены WhatIOS и WhatPhoneWidget для совместимости с XCTest TEST_HOST. Отображаемое название и ID приложения отдельные.

## Собрано и проверено

- Xcode 27.1: подписанная Debug iPhone-сборка SUCCESS, codesign --verify --strict --deep PASS, верные QA IDs, Watch directory отсутствует.
- 2/2 UI-теста в этой QA-конфигурации прошли на iPhone Duo simulator: текстовая заметка через «+» сохраняется; длинное нажатие открывает «Видеозаметка», не аудиозапись. Результат **TEST SUCCEEDED**.
- Артефакт на ArvectumSSD: builds/what-p2a-isolated-phone-qa1-20261017/Build/Products/Debug-iphoneos/WhatIOS.app. Лог: builds/what-p2a-isolated-phone-qa1-smoke-v2-20261017.log.
- **На реальный iPhone эта сборка ещё НЕ установлена**: CoreDevice показывает устройство unavailable. Существующая QA13 и production с данными не затронуты.

## Следующая физическая приёмка (после восстановления связи)

1. Убедиться, что CoreDevice видит доверенный iPhone available (paired), и проверить отдельные bundle IDs. Установить только новый ru.arvectum.tools.what.p2aqa, ничего не удаляя.
2. В новом приложении через «+» создать отдельную текстовую заметку, изменить её, перейти в «Мои записи», перезапустить приложение и убедиться, что текст сохранился.
3. Проверить короткое нажатие для аудио и длинное нажатие для видео. Для теста настоящей камеры выключить активный iPhone Mirroring: конфликт доступа к микрофону/камере не является дефектом Ухвата.
4. Записать и сохранить короткое несекретное видео, воспроизвести со звуком, переключить переднюю/заднюю камеры; отдельно проверить Stop/Cancel, прерывание и восстановление.
5. После M1–M4 провести отдельную интеграцию/QA Watch и проверку iPad; пока не считать их физически принятыми.

Ограничения: никакой App Store отправки, установки на Watch, удаления старых QA или production записей.

## iPhone 13 connected — installed, pending unlocked acceptance

- Physical device connected by USB, Developer Mode enabled, iOS 27.0.1. Legacy `ru.arvectum.tools.what.qa` remains on device at 1.0.2 (13).
- Before installing the isolated app, copied `Library/Application Support` from the established legacy QA container to `/Volumes/ArvectumSSD/Arvectum/builds/what-p2a-physical-qa-20261017/device-backup/legacy-qa-app-support`: 26 files. Re-read the same container after installation: **26/26 files SHA-256 identical**. No existing QA or production bundle uninstalled.
- Imported updated iOS 18+ native async MOV exporter (iOS 17 fallback retained) and minor shared encoder warnings from the desktop QA branch. Physical Debug build on Xcode 27.1 SUCCEEDED. Strict deep code signature PASS; separate ID `ru.arvectum.tools.what.p2aqa`; nested standalone iOS widget, **no Watch app**.
- Physical `devicectl device install app` succeeded for `Ухват P2a QA` version 1.0.2 (1); device inventory confirms both established QA (13) and separate P2a QA (1).
- Real-device automated UI test preflight blocked: `Unlock iPhone Nikita to Continue` (locked screen). Foreground launch similarly denied by SpringBoard reason `Locked`. No claim of completed real camera/video/microphone testing until device is unlocked and successful evidence is collected.
- Standard iOS simulator runtime download launched but has produced no output/artifact; the installed iOS 27.1 runtime has `restrictedToDeviceTypes` iPhone Duo only. iPad simulator still blocked independently of the physical iPhone acceptance.
