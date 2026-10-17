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
- **Позднее в тот же день сборка установлена на iPhone 13**: подробные результаты и проверка 26/26 файлов действующей QA13 — ниже. Производственная версия и QA13 не затронуты.

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

## Automated test readiness

- New isolated `PhysicalVideoCaptureUITests.testHoldSwitchCameraAndSaveLocalMovie` automates real-device camera-switch recording. `xcodebuild build-for-testing` for physical iOS destination reports **TEST BUILD SUCCEEDED**. This does **not** mean the camera E2E test passed.
- Rechecked 14 focused video merge/recovery simulator test **cases** after the async-export fix: 14 cases, 0 failures. The Xcode 27.1 test runner again hung in result finalization, emitting `invalidDigitCount(94232)`; no clean `TEST SUCCEEDED`/exit was observed.
- An iPhone XCTest run compiled and installed its dedicated QA runner, then Xcode preflight repeatedly reported the physical iPhone locked. The run was stopped after prolonged preflight wait; nothing in the existing QA13 container was changed.
- The standard iOS runtime download process had still produced no artifact after nearly an hour and was terminated; iPad simulator fix remains open.

## First unlocked physical UI run — iOS permission gate

- On physical wired iPhone 13, launching `ru.arvectum.tools.what.p2aqa` via `devicectl device process launch` **succeeded** after the owner unlocked the device. QA13 and separate P2a QA1 remained installed.
- Started 3 targeted physical UI cases (home/library, typed-note autosave, camera switch and local video save). The XCTest runner launched, but no cases executed: it reported `Timed out while enabling automation mode` (`com.apple.dt.XCTest.XCTFuture`, code 1000).
- Captured the physical screen via `devicectl device capture screenshot`, which identifies the exact blocker: iOS secure system sheet **«Введите код-пароль iPhone для приложения „XCTest“» / "Enable UI Automation"**. Owner must enter the device passcode locally; never transmit or store the passcode.
- Until this local authorization is completed and fresh targeted tests execute, **do not mark physical UI/video acceptance passed**.
- Diagnostic log: `builds/what-p2a-physical-qa-20261017/iphone-real-ui-20261017.log`; device screenshot (private, not uploaded) `builds/what-p2a-physical-qa-20261017/iphone-ui-automation-diagnostic.png`.

## Физическая приёмка после разрешения XCTest — результаты 17:11–17:25 МСК

- Владелец ввёл код на **самом iPhone**, разрешив XCTest UI Automation. Код не получался и не сохранялся. Устройство: реальный iPhone 13, iOS 27.0.1, по кабелю; отдельный `ru.arvectum.tools.what.p2aqa`, без установки на Watch.
- **PASS / `TEST SUCCEEDED`:** `CaptureFirstUITests.testCaptureFirstHomeAndLibraryBackNavigation` — главный экран, список записей, возврат; см. `builds/what-p2a-physical-qa-20261017/retry-physical-ui.log`.
- **PASS (case-level):** `CaptureFirstUITests.testTypedNoteFromPlusPersistsAfterOpeningLibrary` — `+`, ввод текста, сохранение, обнаружение в Inbox; см. `iphone-text-video-physical-20261017.log`. Общая команда содержала отдельный *не прошедший первоначальный* видеотест: не маркировать весь запуск успешным.
- **PASS / `TEST SUCCEEDED`:** `PhysicalVideoCaptureUITests.testHoldSwitchCameraAndSaveLocalMovie` после исправления accessibility и ожидания закрытия видео-экрана **после окончания экспорта**, а не по раннему существованию домашней кнопки; `iphone-video-durable-save-20261017.log`. Реальное длинное нажатие, переключение задняя→фронтальная, два локальных фрагмента, Stop/Save, запись внесена в индекс.
- **PASS (case-level):** `PhysicalVideoCaptureUITests.testShortTapStartsAndSavesAudio` — короткое нажатие, Stop/Save, физический аудиофайл. `iphone-audio-video-reopen-20261017.log` (общий запуск имел ошибку в первом варианте тестового утверждения видеоплеера).
- **PASS / `TEST SUCCEEDED`:** `PhysicalVideoCaptureUITests.testSavedVideosOpenPlayerAfterRelaunch` — видео доступно после перезапуска, встроенный плеер открывается/закрывается; исправлено ошибочное утверждение теста, ожидавшее кнопку *домашнего* экрана при возврате в *список*; `iphone-replay-fix-20261017.log`.

### Объективная проверка реальных файлов

- Исходный незавершённый видеофрагмент первой попытки: MOV 46,21 с, HEVC + AAC, сохранён локально. Автовосстановление при следующем запуске добавило видео в индекс (без дублирования UUID).
- Прерванная первой версией UI-теста двухкамерная запись: два полноценные исходных MOV (HEVC + AAC), временный `combined.mov` был прерван XCTest до финализации. При следующем запуске восстановлена как единая видеозаметка. Оригиналы не были удалены до успешного импорта.
- Финальный сохранённый двухкамерный MOV: **19,70 с**, **7 891 522 байта**, видеопоток **H.264 1080×1920**, аудио **AAC**, ненулевой аудиосигнал (mean -40,3 dB, peak -16,9 dB). После закрытия и повторного запуска — в `What/Videos/`, в `local-notes.json`; все новые видеожурналы очищены после импорта. Проверено чтение `ffprobe`, декодирование `ffmpeg` и локальный индекс.
- Аудиозаметка: **M4A 5,76 с**, **107 770 байт**, AAC 48 кГц, ненулевой аудиосигнал (mean -31,5 dB, peak -9,7 dB), зарегистрирована в `recordings.json` под тем же UUID что и `What/Audio/*.m4a`.
- Нюанс изображения: проверка `blackdetect` показала практически чёрные первые **15,43 с** от *основной* камеры и нормальный ненулевой видеосигнал после перехода на *фронтальную*. Возможно закрыт объектив основной камеры (телефон лежал на столе); причину не доказали. **Ещё требуется повторить при физически открытом и освещённом объективе основной камеры.** Не объявлять полную валидацию обеих камер.
- Инвариант безопасности: после всей физической QA вновь скопировано хранилище обычного `ru.arvectum.tools.what.qa` (сборка 13); **26/26 исходных файлов SHA-256 идентичны** до и после, ни одного добавленного/удалённого/изменённого. Само приложение QA13 и отдельное P2a QA1 остались установленными, Watch не обновлялся. Данные других приложений не тронуты.

### Исправление и остающиеся ворота

- В `VideoRecordingSheet` перенесён `what.video.preview` на собственный элемент камеры и включено `.accessibilityElement(children: .contain)` у контейнера, чтобы кнопка `what.video.switchCamera` была доступна и VoiceOver, и XCTest. Реальная физическая UI-автоматизация подтверждена после исправления.
- В `PhysicalVideoCaptureUITests` добавлены независимые аппаратные сценарии аудио/плеера, безопасная диагностика accessibility и ожидание фактического завершения видеоэкспорта. Тесты работают только с отдельным P2a QA приложением.
- **Открыто:** основная камера с открытым объективом, отказ/отзыв разрешений, принудительное завершение посреди записи, малый объём диска, длинные ролики, iPad (у runtime iOS 27.1 доступен лишь iPhone Duo), полная Watch P0/P1 регрессия с объединённой P2a веткой, отдельное решение о выпуске. App Store и production не затронуты.

## Повторная физическая проверка открытой основной камеры — 17:29–17:31 МСК

- Владелец подтвердил, что подготовил iPhone для проверки основной камеры. QA-приложение `ru.arvectum.tools.what.p2aqa` на реальном iPhone 13 не переустанавливалось. Запущен `PhysicalVideoCaptureUITests.testHoldSwitchCameraAndSaveLocalMovie`: **TEST SUCCEEDED, 1/1, 0 failures**, 33,927 с; видео задняя→фронтальная, сохранение завершено.
- Новая видеозаметка после экспорта действительно появилась в `local-notes.json` с UUID `13F473D6-3801-4C95-B6E2-E4472A5E0604` и MOV под тем же UUID в `What/Videos/`; **19,70 с**, **15 227 958 байт**, H.264 1080×1920, AAC 48 кГц. Журнал незавершённых видеосессий пуст.
- `ffmpeg blackdetect=d=0.5:pix_th=0.10`: **первые ~15,33 с с основной камеры не чёрные** (на кадре 3,0 с `YAVG=79.08`, `YMIN=43`, `YMAX=106`); прежняя 15-секундная чёрная картинка основной камеры при другом положении устройства теперь воспроизводиться не стала.
- После перехода на фронтальную обнаружены почти чёрные интервалы **15,333–16,133 с** и **16,300–19,667 с**. Кадр 17 с: `YAVG=21.89`. При *предыдущем положении телефона* фронтальная камера, напротив, давала изображение, а задняя была закрыта. Вероятное объяснение — попеременное перекрытие объективов при размещении телефона лицом вверх/вниз, **но физическое перекрытие не проверено напрямую**. Для строгой одновременной приёмки обеих камер нужен iPhone вертикально на подставке с открытыми объективами обеих сторон и дополнительный проход.
- Звук AAC содержит ненулевой сигнал (mean −24,8 dB, peak −2,6 dB). Результат со сменой камер читается `ffprobe`, все кадры декодируются `ffmpeg`; полная аудиовизуальная проверка пользователем на слух/взгляд отдельно не выполнялась.
- После этого теста ещё раз скопировано хранилище прежней `ru.arvectum.tools.what.qa` (сборка 13): **26 из 26 файлов SHA-256 полностью совпадают с исходной резервной копией**, добавленных, удалённых или изменённых — 0. Раздельная P2a QA (1) тоже остаётся на iPhone; на Watch ничего не установлено.
- Доказательства только локально на ArvectumSSD: `builds/what-p2a-physical-qa-20261017/iphone-uncovered-back-camera-20261017.log`, `device-backup/p2a-after-uncovered-back-camera`, `device-backup/legacy-qa-after-uncovered-camera`. Приватные медиа не добавлялись в GitHub.

## Итоговый тест двух открытых камер — вертикальный iPhone, 17:34–17:36 МСК

- Владелец подтвердил, что установил iPhone **вертикально с открытыми передним и задним объективами**. Действующая независимая P2a QA не переустанавливалась.
- `xcodebuild` на **физическом iPhone 13**: `PhysicalVideoCaptureUITests.testHoldSwitchCameraAndSaveLocalMovie` — **TEST SUCCEEDED, 1 test / 0 failures**, ~33,76 с. Во время теста выполнены длинное нажатие, начало записи основной камерой, `what.video.switchCamera`, продолжение записи фронтальной камерой, Stop/Save и ожидание окончания записи/экспорта.
- В отдельном P2a-хранилище появилась новая видеозаметка `726FAC42-1AA8-493C-AE63-443FD6E6C8E4`, `What/Videos/<UUID>.mov`, и соответствующая запись в `local-notes.json`: **19,8333 с**, **16 419 419 байт**, H.264 1080×1920, AAC 48 кГц, аудиосигнал ненулевой (mean −35,9 dB, peak −14,8 dB). Все кадры декодируются `ffmpeg`, видео индексировано и закрытых/незавершённых `VideoCaptures`-журналов нет.
- `ffmpeg blackdetect=d=0.35:pix_th=0.10` **не обнаружил ни одного чёрного интервала продолжительностью ≥0,35 с за все 19,83 с**. Анализ яркости кадров: до переключения 2 с `YAVG=54.93`, 8 с `YAVG=55.68`, 13 с `YAVG=55.85`; после переключения 16,5 с `YAVG=108.20` и 18,5 с `YAVG=80.10`. Таким образом, **основная и фронтальная камеры дали непустое видео в одном сохранённом MOV**, прежние чёрные участки не воспроизвелись.
- Повторная послетестовая копия старого `ru.arvectum.tools.what.qa` (версия 13) показала **26/26 файлов побайтно идентичны по SHA-256** исходной копии, 0 новых/удалённых/изменённых. Старое QA и отдельное P2a QA (версия 1) остались установленными, Watch не изменялся. Фото/видео пользователя **не загружались в GitHub**.
- Доказательства только на ArvectumSSD: `builds/what-p2a-physical-qa-20261017/iphone-both-cameras-unobstructed-20261017.log`, `device-backup/p2a-after-both-open-20261017`, `device-backup/legacy-qa-after-both-open-20261017`.
- **Этап одновременной физической проверки обеих камер закрыт**. Открыты другие ворота перед релизом: отказ в разрешениях, аварийное завершение, длительные видео, заполнение хранилища, интеграция Watch и iPad runtime.
