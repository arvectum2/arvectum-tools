# What? — Product Roadmap

## WH19-LOST-ACK · Повторная доставка того же UUID при неполученном ACK (19.10.2026)

- [x] Реализован безопасный, **только для QA** сценарий `what-watch-qa-drop-ack`: после запуска семисекундной записи запоминает её UUID, перехватывает подтверждение от iPhone как из `sendMessageData.replyHandler`, так и из фонового `didReceiveUserInfo`, **не удаляет Watch оригинал и не изменяет индекс очереди**. При таймауте 60 с или ошибке повторной отправки тестовый фильтр автоматически снимается без удаления AAC. Учтено, что оба ACK могут прийти в разном порядке.
- [x] Как только Watch получил хотя бы одно корректное подтверждение по этому UUID (значит приёмник уже зафиксировал файл), QA-пробник сверяет `pending>0` и наличие исходного `.m4a`, а затем снимает тестовый фильтр и отправляет **этот же AAC и UUID** вторым `WCSession.transferFile`. Повторное подтверждение должно очистить очередь. Ни pairing, ни Bluetooth/Wi-Fi, ни бандл обычного «Ухвата» не трогаются.
- [x] В симуляторные регрессионные тесты добавлена проверка **реального декодируемого AAC** при двух вызовах `RecordingRepository.acceptTemporaryFile` с одним UUID: при первом потерянном ACK исходный Watch-файл и очередь сохраняются, при повторе телефон имеет единственную заметку и идентичные аудиобайты, только `WatchAcknowledgementJournal.acknowledge` удаляет оригинал. Это *детерминированный* тест протокола, не имитация реального радиоканала.
- [x] Отдельная Watch QA сборка компилируется в Xcode 27.1 через `generic/platform=watchOS` с изолированными bundle IDs; никаких изменений в производственном ACK-коде вне `#if WATCH_PHYSICAL_QA`.
- [ ] **Физический lost-ACK/duplicate-delivery PASS ещё не получен:** в 09:08–09:10 МСК оба устройства восстановили CoreDevice-связь, Watch `Documents/WhatOutbound/queue.json` прочитан как `[]` (0 ожидающих), прежний 0,124-секундный `.m4a` сохранён. Но iPhone отказал в foreground-запуске QA-приёмника (`FBSOpenApplicationServiceErrorDomain / Locked`): пользовательский экран заблокирован. **Не запускать** автоматическое подавление ACK до разблокировки телефона и подтверждения активности QA-приёмника; после этого проверить один UUID в `recordings.json`, его реальный replay и очистку Watch queue.

[Протокол и условия запуска](docs/PHYSICAL_WATCH_LOST_ACK_REDELIVERY_2026-10-19.md).

## WH19-WATCH-LIFECYCLE · Реальная аудиосессия Watch: диагностика внезапного обрыва (19.10.2026)

- [x] В изолированную QA-сборку Watch добавлен атомарный JSON-журнал `Documents/WatchPhysicalQA/timeline.json` (до 100 событий): `ScenePhase`, AVAudioSession interruption/route changes, начало записи, семисекундный stop timer, результат и времена. **Аудиоданные в журнал не входят**, production Watch-сборка эти события не собирает.
- [x] Два физические автозапуска на Apple Watch SE после корректного разрешения микрофона дали **полноценные записи 7,548 и 7,612 с**. В обоих trace есть `start-capture-called`, `recording-observed`, `audio-route-change(3)` и `stop-timer-fired` приблизительно через 7,3 с; **событий interruption/background между началом и остановкой нет**. Нельзя выводить из этого, что watchOS прерывание невозможно — исходный 0,124-секундный сбой не воспроизведён.
- [x] Первый из новых файлов ожидал в Watch queue при неактивном QA-приёмнике, после foreground iPhone QA и повторной активации Watch был доставлен с тем же UUID `55F1B526-5095-41D2-B8E4-13815ED4CCE9` **ровно один раз**, Watch queue очищена. Второй UUID `1154309C-AEFC-4E17-98DC-419CBD1BAAD1` доставлен автоматически с `ack-observed`. Четыре валидные QA-аудиозаписи по одному UUID хранятся только в iPhone QA-контейнере.
- [x] Добавлен модульный тест реального дефектного AAC **25 247 байт / 0,124 с** при ожидаемых 7 с (запрещает считать длительность исходя из размера файла) и контроль принятия валидной записи 7,612 с. Сам повреждённый источник сохранён на Watch и не отправлен.
- [ ] **Причина 0,124-секундного обрыва не доказана**. При следующем воспроизведении сравнить `timeline.json` с системным событием (sceneBackground, audio interruption/route change) и определить корректный способ восстановления; **не ослаблять проверку AAC** и не удалять исходник до расследования.

[Физический протокол](docs/PHYSICAL_WATCH_AUDIO_LIFECYCLE_2026-10-19.md).

## WH19-ACK-PHYSICAL · Watch → iPhone → ACK на настоящих устройствах (19.10.2026)

- [x] **Ручная запись на реальных Apple Watch SE** после подтверждения микрофона владельцем доставлена в отдельный iPhone QA bundle: UUID `39B7AFC0-F2D7-487B-BAC0-03DD7E0E92A7`, **4,4 с / 94 КБ**, в `recordings.json` ровно одна запись. Watch `WhatOutbound` пуст, а входящий WatchConnectivity UserInfo появился в 07:56. Ни одно пользовательское приложение не изменено.
- [x] **Полностью автоматический физический сценарий с искусственно задержанной отправкой:** Watch QA записал реальный AAC **7,228 с / 45 КБ**, UUID `A2BE3682-31DA-40AF-95B3-FF1592A1F3D4`; на 10 секунд приостановлен только `pumpTransfers()` **в QA-бандле**. На Watch подтверждены `offline-queued`, `pending=1`, источник на диске; после возобновления — `ack-observed`, `pending=0`, исходный `.m4a` отсутствует. iPhone индексирует этот UUID **ровно один раз**. Это не физическое отключение Wi-Fi/Bluetooth.
- [x] После перезапуска **только QA-приложений** Watch и iPhone подтверждены пустая исходящая очередь Watch и обе аудиозаписи на iPhone по **одной копии каждого UUID**. QA-приложение не копировало оригинальные AAC на Mac.
- [x] Ещё один автономный прямой запуск обнаружил **неполную запись 0,124 с / 25 247 байт**, не прошедшую `WatchCaptureValidation`: новая заметка не создавалась, файл `E048D504-A943-49B8-AAA4-BBDEA76A0048.m4a` сохранён **на часах**. Длительность подтверждена `AVAudioPlayer` непосредственно на Watch. Не удалять до отдельного решения; причина обрыва записывающего сеанса ещё не установлена.
- [x] QA probe доработан: только явный параметр запуска инициирует тестовую запись; диагностический/обычный перезапуск Watch QA больше не запускает микрофон автоматически, не влияет на production; различаются UUID новых и ранее оставшихся исходников, есть режим чтения `what-watch-qa-audit` и автоматическая проверка ACK. Обе физические сборки компилируются под Xcode 27.1.
- [ ] Физическое выключение/восстановление реального транспорта, **потеря ACK с повторной доставкой**, перезагрузка самих Apple Watch и длительные офлайн-очереди ещё **не проверены**. Не подменять их QA-local 10-секундным удержанием передачи.

[Подробный протокол](docs/PHYSICAL_WATCH_ACK_AUTO_QA_2026-10-19.md).

## WH19-SEGMENTS · Не сохранять неполную видеозаметку после переключений камеры (19.10.2026)

- [x] **Физически воспроизведено на iPhone 13:** `VideoRecordingSheet` → три переключения камеры (4 файла MOV) → системные «Настройки» → назад в тот же QA-процесс. Два прогона старого кода преждевременно добавили заметку лишь **6,86 с** (первые три фрагмента), а финальный `segment-000003.mov` продолжал дописываться (21–24 МБ); все исходники оставались в журнале. QA-заметки не удалялись.
- [x] **Оба пути исправлены:** обычное `saveCompletedVideo` теперь проверяет на serial camera queue, что число завершённых MOV точно равно числу начатых и активный writer остановлен; fallback после возврата в приложение требует все ожидаемые и читаемые сегменты (никакого частичного salvage в живом процессе). При отсутствии последнего файла никакого нового UUID в библиотеку не записывается, оригиналы остаются. После реального аварийного завершения прежний осторожный частичный salvage доступен.
- [x] В процедуре удаления журнала после ранее сохранённой частичной заметки проверяется суммарная длительность всех восстановленных исходников: если в них имеется ещё не включённое видео, **их нельзя удалять**. Предыдущие QA-исходники сохранены для отдельного, безопасного восстановления полной записи.
- [x] **Повторный физический тест после двойного исправления:** три реальные смены камеры, сворачивание в «Настройки» и возвращение без остановки QA-процесса → одна видеозаметка **28,62 с** (AVFoundation измерила **28,63 с**), на телефоне присутствуют видео/аудиодорожки, новый UUID создан один раз, именно новая временная сессия очищена. Предыдущие два тестовых журнала оставлены без изменения.
- [x] Восстановление/переключение подтверждено **26 целевыми модульными тестами без ошибок**, включая три новых теста неполного четвёртого сегмента, отсутствующего сегмента и безопасности исходников уже индексированной частичной заметки, а также gate обычного экспорта.
- [x] Watch ↔ iPhone physical ACK: после разрешения микрофона и реальных передач закрыт в WH19-ACK-PHYSICAL; физический radio outage, lost ACK и device reboot продолжают оставаться открытыми там же.

[Протокол QA](docs/PHYSICAL_VIDEO_FOUR_SEGMENT_RACE_2026-10-19.md).
## WH19-WATCH-PAIR · Изолированная пара Watch/iPhone для физического ACK QA (19.10.2026)

- [x] Создан отдельный XcodeGen-спек `project.watch-physical-qa.yml` с уникальными идентификаторами iPhone, Watch, WidgetKit и complication. Командой Xcode 27.1 собраны и подписаны обе разработки: iPhone `ru.arvectum.tools.what.watchphysqa`, Watch `ru.arvectum.tools.what.watchphysqa.watch`; Watch companion указывает **ровно на QA iPhone bundle**. Оригинальные production и старые QA-bundle не заменены.
- [x] Пара установлена отдельно на физические iPhone 13 и Apple Watch SE через `devicectl install app` (без сброса часов/удаления записей); перед запуском существующая Watch QA-очередь `queue.json` была пуста. Новый тестовый сценарий создаёт лишь **одну 7-секундную запись** по специальному аргументу запуска и сохраняет агрегированный статус без копирования AAC на Mac.
- [ ] Реальная запись/потеря связи/ACK **не подтверждены**: Watch QA статус остался `waiting-for-microphone`, очередь нового QA-бандла пуста, затем CoreDevice кратковременно потерял туннель к часам. Новый QA-probe подтвердил `AVAudioApplication.recordPermission = undetermined`; требуется ручное подтверждение системного доступа к микрофону на разблокированных Apple Watch перед физическим ACK QA. **Не менять** сопряжение/сетевые параметры и не перезаписывать пользовательские приложения.

[QA-конфигурация и инструкция](docs/PHYSICAL_WATCH_ISOLATED_PAIR_2026-10-19.md).

## WH18-BG · Сохранение видео после сворачивания без перезапуска (18.10.2026)

- [x] **Физический регрессионный сценарий** на iPhone 13: через изолированный QA-бандл открыт настоящий `VideoRecordingSheet`, начата съёмка MOV, затем через CoreDevice активированы системные «Настройки»; QA фиксирует `ScenePhase.background`. После возвращения в **тот же процесс** исходный MOV оставался в `VideoCaptures` и не попадал в библиотеку даже спустя ~30 с. Личные приложения/камеру/watchOS не изменяли.
- [x] **Сохранность данных до исправления:** два источника (примерно 4 МБ и 3 МБ) удалось восстановить через штатную launch recovery после перезапуска QA-приложения, каждый с исходным UUID и без уничтожения заметок. Это воспроизводимый UX-дефект, а не потеря оригиналов.
- [x] Исправлено: `VideoRecordingSheet` при выходе из Active инициирует ограниченную фоновую задачу iOS для завершения MOV; при возвращении, если callback `didFinishRecordingTo` не пришёл, контроллер **на serial capture queue** проверяет, что писатель окончательно остановился, и только затем снимает `active` с UUID и запускает существующий `VideoCaptureRecovery`/индексацию. Повторные вызовы и дубли UUID защищены; при неудачной/неполной записи исходники сохраняются.
- [x] Защита первого разрешения Camera/Mic: временная `.inactive` во время системного диалога **не прерывает подготовку камеры**; незавершённую подготовку останавливаем только при фактическом `.background`. Код не запрашивает новые разрешения на пользовательском устройстве для этого теста.
- [x] **Повторный физический тест с исправлением:** настоящий экран камеры → системные «Настройки» → тот же живой QA-процесс. `saved-after-background`: **ровно один MOV 20,93 с (~2,9 МБ)**, приватный индекс содержит **1 заметку с исходным UUID**, временный журнал — **0 файлов**, перезапуск не требовался. На самом iPhone `AVURLAsset` подтвердил воспроизводимость, видео и аудиодорожки (20,93 с).
- [x] QA-only режим `what-physical-qa=background-sheet` запускает **производственный экран видеозаписи**, а не фальшивый тестовый AVFoundation-контроллер. Принудительный SIGKILL, настройки пользователя и системные разрешения в этом тесте не менялись.
- [x] Полный Xcode 27.1/iOS 27.0 Simulator регрессионный прогон: **114 модульных тестов, 0 failures, 3 expected skips**; тест включает отсечение открытого writer и восстановление завершённого MOV ровно с одним UUID.
- [ ] Отдельно проверить фон при **незавершённом переключении камеры**, длительную блокировку экрана, прерывание телефонным вызовом и низкий остаток памяти; физический Watch ACK остаётся открытым.

[Подробный физический протокол](docs/PHYSICAL_VIDEO_BACKGROUND_RECOVERY_2026-10-18.md).

## WH18-PHYSICAL · Камера, 3+ минуты и аварийный обрыв на iPhone 13 (18.10.2026)

- [x] **6 реальных последовательных переключений** задней/фронтальной камер в отдельно установленном `ru.arvectum.tools.what.multimodalqa` (iOS 27.0.1): исходные 7 фрагментов → **один MOV 22,69 с / ~12 МБ** с тем же UUID, ровно одна заметка в локальном индексе, `VideoCaptures` после сохранения — **0 файлов**. Прямой QA-пробник обошёл ошибку инициализации XCTest UI Automation, не затрагивая производственную сборку.
- [x] **180 секунд непрерывной физической камеры**: итоговый MOV длительностью **191,38 с / ~26,3 МБ**, записан и проиндексирован, временные оригиналы очищены; не равно многочасовому тесту.
- [x] После обновления **только изолированного QA-приложения** видеозаметки сохранились. `AVURLAsset` непосредственно на iPhone подтвердил оба MOV как воспроизводимые, с видео- и аудиодорожками; видео на Mac не копировалось.
- [x] **SIGKILL во время первого сегмента** QA-записи, до штатного `Stop`: на iPhone остался манифест UUID и оригинальный MOV. Последующий обычный запуск восстановил в библиотеку **одну запись 9,32 с / ~1,2 МБ**, `VideoCaptures` очистился; AVFoundation на iPhone подтвердил воспроизводимость и звук. Дополнительный перезапуск — ровно тот же UUID и **без дубля** (9 QA-заметок всего).
- [x] Все проверки — изолированный bundle без компаньона Watch, App Groups и доступа к личным контейнерам. Установленный production Ухват и очередь Watch не менялись. Сбой запуска физического UI-раннера XCTest фиксируется отдельно, **не считается** ошибкой продукта или успешно пройденным UI XCTest.
- [ ] Физические многочасовая запись, реальное исчерпание места и фон/долгая блокировка экрана, а также Watch ACK и upgrade публичного production bundle — **не закрыты**.

[Подробный протокол](docs/PHYSICAL_VIDEO_STRESS_RECOVERY_2026-10-18.md).

## WH18-VIDEO · Многократная смена камеры и проверка места для MOV (18.10.2026)

- [x] Перед сохранением видеозаметки добавлена консервативная оценка **свободного пространства для экспорта и копирования в библиотеку**: один фрагмент — ~1× исходный объём + 32 МиБ, несколько — ~3× + 32 МиБ; используется системная ёмкость `volumeAvailableCapacityForImportantUsage`. Если система не сообщает число, сохраняется прежний безопасный механизм обработки ошибок записи.
- [x] При недостатке места дорогостоящий экспорт не начинается, пользователь видит ошибку, исходные `.mov` остаются в журнале для повторного сохранения/восстановления после освобождения места. Это профилактическая оценка, **не гарантия**, что при реальном заполнении запись завершится успешно.
- [x] 10 последовательных фрагментов от двух камер (10 × 0,8 с): проверены порядок/цвет каждого кадра, итоговая длительность, аудиодорожка и неизменность исходных MOV. В тестовом `AVAssetImageGenerator` зафиксирован допуск времени 0,05 с во избежание выбора соседнего кадра.
- [x] Симуляторный отказ при свободном объёме 1024 байта: экспорт отклонён до создания итогового файла, все исходные фрагменты сохранены; повтор при нормальной ёмкости успешен.
- [x] Xcode 27.1 / iOS 27.0 Simulator: **113 модульных тестов, 0 failures, 3 expected skips**; 8/8 VideoCameraSwitchTests PASS.
- [ ] Проверить 30–120 минут физической записи, 10+ реальных переключений камеры, фактический остаток места, фон/возобновление и перезапуск на изолированном физическом устройстве — не считать это закрытым симуляторными тестами.

[Протокол видео-QA](docs/VIDEO_STORAGE_MULTISWITCH_QA_2026-10-18.md).

## WH18-ACK · Устойчивость ACK при разрыве связи и перезапуске Watch (18.10.2026)

- [x] При подтверждённом сохранении аудио на iPhone перед изменением очереди Watch атомарно фиксируется маркер ACK для UUID; исходный `.m4a` удаляется **только после** успешного обновления `queue.json`. При сбое на любом из этапов маркер/оригинал остаются до следующей безопасной попытки.
- [x] После перезапуска Watch завершает прерванную ACK-очистку **до** поиска «осиротевших» аудиозаписей, а сканер не возвращает подтверждённые UUID в очередь. При недоступном на заблокированных часах индексе исходная очередь не заменяется пустой.
- [x] Повторный live/background ACK не затрагивает другие заметки; запоздавший `didFinish` для уже подтверждённого UUID не меняет retry/backoff состояния.
- [x] **12/12** целевых `WatchA2ReliabilityTests` PASS; полный `WhatIOSTests`: **110 выполнено, 0 failures, 3 expected skips** на iOS Simulator, Xcode 27.1. Временные файлы и XCT отчёты только на ArvectumSSD.
- [ ] Физическое воспроизведение потери ACK, Watch offline/reboot, нескольких несинхронизированных записей, фоновой доставки и аудио после приёма; код и симуляторные тесты **не закрывают** этот релизный gate.

[Подробный QA-протокол](docs/WATCH_ACK_RACE_QA_2026-10-18.md).

## WH18-QA · Защита восстановления до первого сегмента и при нехватке места (18.10.2026)

- [x] Пустая незавершённая видеосессия после аварийного обрыва до первого `MOV`: сохраняется её UUID/манифест; при следующем запуске показывается уведомление о невосстановленной записи вместо молчаливого пропуска. Оригинальные данные не удаляются, фантомная заметка не создаётся; повторный запуск идемпотентен.
- [x] Симуляция ENOSPC **после частичного копирования** видео: неполный `.incoming` / `.repair` очищается, исходный фрагмент и индекс заметок сохраняются; дальнейшее восстановление с тем же UUID не блокируется устаревшим staging-файлом.
- [x] Детерминированные модульные тесты на iOS Simulator (без заполнения накопителя и без личных медиа): **107 executed, 0 failures, 3 expected skipped**, включая 13/13 сценариев VideoCaptureRecovery; физическая проверка самого раннего обрыва и реального малого остатка места остаётся отдельным открытым пунктом.
- [ ] Реальные стресс-проверки многочасового видео, нехватки места и завершения до финализации первого MOV на **изолированном физическом QA-устройстве**; итоговый production build/Watch не трогать до отдельной приёмки.

[Протокол испытаний](docs/VIDEO_EARLY_CRASH_ENOSPC_QA_2026-10-18.md).

## Физический iPhone: дополнение к QA Ухвата 1.1 · 18.10.2026

- [x] Реальное аудио: короткое нажатие, микрофон, сохранение — физический iPhone 13, 1/1 UI PASS.
- [x] Реальное видео: длинное нажатие, смена камеры, сохранение MOV — физический iPhone 13, 1/1 UI PASS.
- [x] Открытие ранее сохранённого MOV через библиотеку после нового запуска: физический iPhone 13, 1/1 XCTest PASS (11.400 с), системная связь восстановлена. Первоначальный CoreDeviceError остался в истории QA.
- [x] 90-секундная реальная видеозапись: Stop and save, файл сохраняется и Home возвращается; физический iPhone 13, 1/1 UI PASS (102.699 с теста).
- [x] Отмена короткой реальной видеозаписи и возврат Home: 1/1 физический UI PASS.
- [x] Отмена после переключения задней/фронтальной камеры: 1/1 дополнительный UI PASS на iPhone 13; независимый просмотр приватной QA-папки `VideoCaptures` показал **0 файлов** до и после перезапуска, `local-notes.json` не изменён (дата модификации 20:49 при тесте 21:15); временный журнал удалён. Этот сценарий не требует физического iPhone повторно без регрессий.
- [x] Физический аварийный обрыв после переключения камеры: 1/1 XCTest PASS, два сегмента и манифест сохранились; при запуске объединены в один MOV, повторный запуск не породил дубль (один UUID). Проверка только на изолированном UhWhat QA. Воспроизведение именно восстановленного ролика — PASS (1/1 физический UI); разрыв до закрытия первого сегмента — OPEN.
- [ ] Watch ACK, фоновый жизненный цикл, **многочасовые** записи и Store rollout — открыто. Физические медиа остаются только в собственном QA-контейнере.
- [ ] Возобновить приёмку после переподключения iPhone, не сбрасывая и не удаляя личные приложения.

[Физический QA-протокол](docs/PHYSICAL_MULTIMODAL_1_1_QA_2026-10-18.md).


## PR #90 объединён в main · 18.10.2026

- [x] Исходники реального Ухвата 1.1.0 (текст/аудио/видео, Watch, ChickMark handoff) и iPad/Duo адаптивность в main через PR #90, 38/38 GitHub checks.
- [x] Финальные тесты на обычном iPhone: 104 executed, 0 failures, 3 expected skip; [протокол](../core/docs/ADAPTIVE_MAIN_INTEGRATION_2026-10-18.md).
- [ ] Ранее отправленная Apple сборка 1.1.0(8) не заменялась новым бинарником. Новые iPad-релизы, реальные доступы камеры, окончательная физическая приёмка и настоящее fold/unfold не закрыты.


## Мультимодальный iPad/Duo · 18.10.2026

[QA 1.1.0](../core/docs/ADAPTIVE_T4_T5_MULTIMODAL_2026-10-18.md): интегрированы общие адаптивные редакторы в actual 1.1.0 с текстом/аудио/видео/ChickMark. Core 13/13, What 104 unit (3 skipped), iPad UI 5/5 и Duo 4 executed (2 skipped) прошли. По решению владельца физический Duo не блокирует разработку; симуляторная проверка и исправления по user feedback. Живое fold/unfold не доказано. Релиз и данные на обычном iPhone — отдельные ворота.

## Пилот iPad/Duo · 18.10.2026

В отдельной ветке feature/core-ipad-duo-pilots-20261018: ArvectumCore, читаемая библиотека/редактор, широкий/компактный layout, iPad target только для QA; Debug build PASS, 61 unit (3 skipped) и 2 UI PASS. Мультимодальная версия 1.1.0 не интегрирована и не менялась, WH-D0…D3 и физическая приёмка всё ещё открыты. [QA](../core/docs/ADAPTIVE_T4_T5_PILOT_2026-10-18.md).

## Актуальный релизный чекпоинт · 18.10.2026
**Ухват / UhWhat:** последняя подтверждённая публичная iOS версия — 1.0.1(6), ASC 18.10. **1.1.0 (build 8)** с Watch/complication/widget и интеграцией ChickMark **отправлена в App Review 18.10 09:01 МСК**: upload VALID, WAITING_FOR_REVIEW на момент [релизного аудита](https://github.com/arvectum2/arvectum-tools/blob/release/what-chickmark-20261018-rc1/what/docs/RELEASE_AUDIT_WHAT_CHICKMARK_2026-10-18.md). До READY_FOR_SALE не считать выпущенной.

- [x] **WH18-0 · Реализовано в кандидатах:** единый local-first Inbox audio/text/video, короткое касание большой кнопки — аудио, удержание — видео, отдельный «+» — текст; автонапоминания о новых заметках по opt-in Off/+1/+2/+3 ч; ручная отправка полной заметки в разовое напоминание ChickMark. Изменения не приписывать публичной 1.0.0.
- [x] **WH18-1 · QA evidence:** физическая проверка обеих камер iPhone 13, recovery и сохранности старых файлов; Watch→iPhone UUID/ACK+транскрипция; изолированная физическая связка с ChickMark (импорт, обратная ссылка, дедупликация, реальное приватное уведомление). Это разные QA-сценарии, не замена полной приёмке публичного обновления.
- [x] **WH18-2 · Подготовка Apple:** production 1.1.0(8) с RU/EN release notes, reviewer instructions и iPad скриншотом принята обработкой и отправлена на review.
- [ ] **WH18-3 · Релиз:** решение Apple, READY_FOR_SALE, storefront и безопасный upgrade без потери аудио/видео/текста и очереди Watch.
- [ ] **WH18-4 · Оставшийся QA:** физический iPad и multitasking, экстремальное завершение/**многочасовое** видео и низкая память, реальные отказы доступа камеры/микрофона, Watch ACK race, тихие часы и настоящий продакшен push/tap-through после обновления.
- [ ] **WH18-5 · После релиза:** исправления транскрипций, расширенный поиск/архив и semantic memory — без нарушения мгновенной записи.

**Связанные планы:** [ChickMark](../chickmark/ROADMAP.md), [Core](../core/ROADMAP.md), [Growth](../growth/ROADMAP.md). Старые невыполненные пункты ниже относятся к прежней версии MVP и проверяются по чекпоинту 1.1.0.


## Адаптация iPad / iPhone Duo — 2026-10-16

**Статус:** бэклог; реализация iPad **частично есть только в feature/what-multimodal-20261016**, а не в текущей main и не в опубликованной версии. [Общая матрица Core](../core/DEVICE_ADAPTATION_ROADMAP.md).

**Инфраструктура (16.10.2026):** Xcode 27.1 активна; частичная поддержка iPad уже реализована в feature/what-multimodal-20261016. Первый пилот адаптивного Core — библиотека/редактор. WH-D0…D3 остаются открытыми; Duo QA ждёт runtime iOS 27.1 (T3/T4). Проверка физической камеры и Watch — отдельно.

- [ ] **WH-D0 · Подтвердить baseline:** перенести/сверить M5a из multimodal feature-ветки и готовность iPad target family 1,2 без случайного включения в релиз.
- [ ] **WH-D1 · iPad:** сохранить одну большую круглую кнопку (короткое нажатие — аудио; долгое — видео), отдельный плюс для текстовой заметки; проверить editor, библиотеку, камеру, кнопки Стоп и смены камер, portrait/landscape/Split View/Stage Manager, VoiceOver.
- [ ] **WH-D2 · iPhone Duo:** закрытый экран — один жест записи и быстрая библиотека; раскрытый — полноценная библиотека/редактор. При fold/unfold во время видео, переключения фронтальной камеры, аудиозаписи или незавершённого текста не терять медиа/черновик и не запускать дубль записи. Watch одно касание сохраняется без изменений.
- [ ] **WH-D3 · QA и отдельный релиз:** симулятор на обоих размерах Duo, реальные разрешения Camera/Mic, recover journal, большие записи, жесты, background/foreground, Watch ACK, уведомления о заметках и App Store assets. Отсутствие Duo runtime фиксировать как блокер физической/симуляторной приёмки, а не как успешно пройденный тест.

## Active release checkpoint — 2026-10-15

**A5 RC:** [Ухват 1.0.2 (7)](../core/A5_SIGNED_RELEASE_CANDIDATES_20261015.md) подписан, iPhone/Watch/complication/widget проверены, CI PASS, **не загружен в ASC**. Отправленная 1.0.1 (6) ещё WAITING_FOR_REVIEW; физическая 1-tap/ACK/офлайн-проверка остаётся OPEN.

**Brand:** Ухват (RU) / UhWhat? (international), code directory what/.
**Public 1.0.0 (5):** READY_FOR_SALE independently rechecked in App Store Connect API 2026-10-15
(App ID 6822476399). **Submitted 1.0.1 (6):** Waiting for Review, recorded
2026-10-15. Exact details and release evidence belong to the
[1.0.1 release-branch roadmap](https://github.com/arvectum2/arvectum-tools/blob/release/what-1.0.1/what/ROADMAP.md);
release-proven iOS/watchOS source was **selectively integrated into main** 2026-10-15 via [PR #67](https://github.com/arvectum2/arvectum-tools/pull/67) (`e129efc`); private RuWordNet corpora and research pipeline were not copied.

**North star:** Catch the thought before it disappears. Reliable immediate
capture, durable original audio and Watch-to-iPhone delivery have priority.

- [x] iPhone capture-first UI, Watch recording, local Inbox/Archive,
  transcription, searchable text and sharing shipped in 1.0.0 (5).
- [x] Release 1.0.1 (6) source fixes complication to launch Watch recording
  in one tap, uses branded Watch glyph and saves active recording upon
  app backgrounding. Signed IPA and simulator tests passed, submitted.
- [x] A2 source-level queue and receiver hardening: atomic on-disk enqueue/ACK/recovery before in-memory mutations; iPhone rejects unreadable/corrupt AAC before ACK. 7/7 focused tests PASS; complete suite 61 executed, 0 failures, 3 skipped. Both Watch and iOS builds and GitHub PR CI pass. [PR #70](https://github.com/arvectum2/arvectum-tools/pull/70) merged into main at `2f9239f`. [A2 QA](docs/A2_CAPTURE_DELIVERY_QA_2026-10-15.md). Changes are **not** in Apple's submitted 1.0.1 (6) binary.
- [ ] Physical proof for 1.0.1: one Watch complication tap → audio,
  Digital Crown/background → saved playable audio on iPhone exactly once,
  including offline / ACK / reboot and duplicate-delivery scenarios.
- [ ] Measure real capture latency and playback survival; sudden power loss
  or force termination may leave unfinished AAC unplayable.
- [x] Shippable 1.0.1 source, widgets and tests integrated into main with
  source provenance, without the private RuWordNet corpus. No user-device
  records were modified in this merge; physical regression remains open.
- [ ] Keep semantic Ask Memory research out of release-critical P0.

**Updated:** 2026-10-16 (multimodal text/audio/video + iPad backlog added; no application code or release binary changed). **Shared Core:** [Core](../core/ROADMAP.md).
**Growth:** [Growth](../growth/ROADMAP.md).
**Note:** P0–P5 checklist below retains historic and research milestones.
The current main now includes the release source; unchecked device/research
acceptance cases must not be confused with absent capture, Inbox, transcript
or export features.

## P0 — Reliable Apple Watch capture
- [x] Watch recording, UUID/time, durable local queue, opportunistic transfer to iPhone, ACK and deduplication (implemented in `main`).
- [x] Watch-face entry point and immediate recording UX (source integrated into `main`).
- [x] Automated A2 queue crash/write-failure/offline-batch and receiver AAC integrity regression tests added; no real Watch devices tested yet.
- [ ] Complete remaining disconnected-device, multiple-pending-recording and device-reboot acceptance cases on a physical paired Watch and iPhone.
- [ ] Reconcile final physical test evidence and prove no recorded thought is lost.

## P1 — Voice + transcribed text (existing; not a manually typed note)
- [x] Preserve original audio as source of truth; transcript stored separately by recording UUID.
- [x] Add on-device Speech transcription (explicit permission; no cloud fallback), local text persistence, and play/stop controls.
- [ ] Verify playback and actual Speech recognition of existing audio on physical iPhone; add language selection, retry/cancel controls and transcript corrections.

## P2 — iPhone inbox
- [ ] Today/Yesterday grouping, search, archive/delete and sync status; playback available in initial list.

## P2a — Unified multimodal capture on iPhone and iPad (new backlog, 2026-10-16)

**Target experience and device matrix:**

**Capture controls (mandatory UX contract):** On **iPhone and iPad**, keep the existing **large round recording button** as the primary control: **short tap → start audio recording immediately**, **long press → start video capture with the camera** (no Text/Audio/Video selection menu). The small **`+` button opens a new typed text note only**. Watch keeps its **one-tap audio** complication and audio-only interface. Distinguish a long press from a short tap before triggering capture: a long press must never accidentally start an audio recording first. Keep obvious recording state, haptic/visual feedback, Stop/Save/cancel and permission handling for both media types.

| Device | Text note (typed) | Audio note | Video note |
| --- | --- | --- | --- |
| **Apple Watch** | — | **Yes — one-tap voice capture**, existing primary flow | — |
| **iPhone** | **Yes — compose and edit** | **Yes — keep existing fast audio capture** | **Yes — record with camera in app** |
| **iPad** | **Yes — compose and edit** | **Yes — record with microphone** | **Yes — record with camera in app** |

**Status:** backlog only; the current iOS Xcode target uses `TARGETED_DEVICE_FAMILY = 1` (iPhone only), so **native iPad support is not implemented or validated**. Existing on-device Speech audio transcription does **not** mean manually composed text notes are already supported. Preserve the current Watch capture-first/ACK reliability before introducing new capture modes; none of these changes are in the public or Apple-submitted releases.

- [ ] **M1 · Unified local note model:** one inbox for `text`, `audio`, and `video`, with stable UUID, creation/edit timestamps, explicit media kind, optional body/transcription, local original-media URL and source device. Keep Watch audio IDs, migration, ACK/dedupe and existing archives backward-compatible; never replace original media with generated text.
- [ ] **M2 · Native text note (iPhone/iPad):** `+` → Text, instant empty editor with keyboard focus, manual typing and editing, reliable local draft/autosave, cancel/delete safeguards and optional title. Text must work offline without Speech permission, microphone or camera.
- [ ] **M3 · Preserve fast audio (iPhone/iPad):** a **short tap on the existing large round record button** starts the existing audio recording immediately (no mode chooser); support playback, transcription (with explicit permission), edit transcription separately from original audio and reuse stable note identity. On Watch retain **audio-only** complication → immediate recording, with no new selection screen.
- [ ] **M4 · Native video note (iPhone/iPad):** a **long press on the same large round record button** starts video capture with the device camera **inside Ухват**, without an intermediate mode chooser; provide clear recording/Stop state, elapsed timer and preview. Resolve short-vs-long press before starting audio so a video gesture never leaves a stray audio note; show haptic/visual confirmation. Ask Camera/Microphone permissions only when needed, handle refusal and interruption, and never record without an explicit user action. Save original video locally atomically; support preview/playback, poster frame, size/duration indication and safe delete/export. If video speech-to-text is added, it must be optional and must not overwrite the video. Importing existing library videos is a separate enhancement, not a prerequisite for recording.
- [ ] **M5 · iPad-first-class UI:** expand iOS device family to include iPad, make text editor/recorders/camera preview and Inbox usable in portrait, landscape, split view and large text; ensure iPhone-specific layouts, Share sheet, permission copy, icons and Store device assets remain correct. Do not claim an iPad release until actual build and device/simulator QA passes.
- [ ] **M6 · One Inbox, sensible presentation:** preserve the **large round recording button** (short tap = audio; long press = video) and add a separate unobtrusive **`+` for typed text notes only** on iPhone/iPad; no three-way capture menu. Provide a discoverable long-press hint without cluttering the capture screen, plus type indicators, inline text, thumbnails/previews and type filters; preserve search, archive/delete, timestamps, per-note links and notification-reminder eligibility. Video assets remain local-first; sharing/synchronization across iPhone and iPad is **not automatically implied** by supporting both devices and needs a separate opt-in architecture decision.
- [ ] **M7 · Acceptance and safe release:** tests for app restart mid-draft, background/low storage while recording, media integrity after interruptions, cancelled capture, camera/mic/Speech denied, large video, deletion without orphan files, old audio-model migration, Watch offline/ACK regression, gesture arbitration (short tap audio; long press video; no unintended audio), long-press discoverability and accessibility alternatives for users unable to hold the button, iPhone+iPad layouts, permission/privacy descriptions and no implicit cloud uploads. Gate shipping behind iPhone/iPad physical QA and its own signed release; do not alter already submitted IPA or any existing user's notes.

**Proposed delivery order:** M1 + M2 (typed text first), then M3 (shared audio interface), M4 (video), M5–M7 (iPad/adaptive Inbox + acceptance). New capture modes must remain secondary to Watch's one-tap audio workflow and the existing durable queue.

## P3 — Apple Notes / Shortcuts
- [ ] Export and optional system integration without depending on cloud.

## P4 — Semantic memory
- [ ] Local transcript chunking, embeddings, semantic search and source references.

## P5 — Ask Your Memory
- [ ] Retrieval-grounded responses with note/audio timestamp attribution; no unsupported invented statements.

## P6 — Follow-up reminders for captured notes (post-1.0 backlog)
- [ ] **P1 · Revisit a note later:** after saving a new text/audio/video note (including audio delivered from Watch), offer one-tap "Напомнить" with +1 / +2 / +3 hours from the time it becomes available on iPhone; allow per-note override, reschedule, cancel and mark reviewed. Keep recording/Watch transfer fast and unaffected by notification scheduling. No default reminders unless explicitly enabled by the user.
- [ ] **P1 · Optional auto-follow-up:** opt-in rule "new note → remind after 1/2/3 hours", with quiet-hour/notification-permission handling, duplicate protection by stable recording UUID and no reminders for deleted notes. Add a low-noise daily review/digest only as a subsequent option if individual alerts prove noisy.
- [ ] **P1 · ChickMark handoff:** optional local-only integration to create a distinct "Review this note" follow-up in ChickMark, **not** a recurring habit or an automatic habit completion. Carry the saved/edited transcription as the follow-up's full text, recording UUID, creation time and a deep link back to the original audio in Ухват. The notification itself defaults to privacy-safe generic text; showing transcription on the lock screen is a separate explicit choice.
- [ ] **P1 · Integration feasibility spike:** validate app-to-app transfer for the two signed iOS apps (App Group/shared container versus App Intents/Shortcuts/openURL), actual background/notification limits, permissions and behavior when ChickMark is not installed. Never require cloud, network or an always-running companion app. If unavailable, use Ухват's own local notification fallback.
- [ ] **Acceptance:** test Watch offline/delayed arrival, transcription still pending, edited transcription after handoff, app reinstall/upgrade, duplicate Watch deliveries, deleted/archived notes, ChickMark unavailable, denied notification permission, timezone/quiet hours, and tap-through to the correct audio. Do not silently copy private transcripts to shared or external destinations without opt-in.

## Later
- [ ] Optional clustering and additional platforms only after MVP validation.

Keep product features in this roadmap; common engineering in Core and acquisition/monetization experiments in Growth.
