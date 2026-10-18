# Ухват · выделенная Watch/iPhone QA-пара, 19.10.2026

## Оборудование и изоляция

Физический iPhone 13 iOS 27.0.1 через USB, Apple Watch SE watchOS 26.6 через ранее существующее локальное сопряжение и CoreDevice. Mac mini, Xcode 27.1. Установлены отдельно и без uninstall **новые** bundle IDs:

- iPhone: `ru.arvectum.tools.what.watchphysqa` (1.1.0 / build 20).
- Watch: `ru.arvectum.tools.what.watchphysqa.watch` (1.1.0 / build 20).
- Widget: `ru.arvectum.tools.what.watchphysqa.widget`; Watch widget `ru.arvectum.tools.what.watchphysqa.watch.capturewidget`.

Оба приложения подписаны через разработческий профиль; `codesign --verify` успешно прошёл для iPhone.app и WhatWatch.app. `WKCompanionAppBundleIdentifier` указывает на QA bundle iPhone, а не на production. `project.watch-physical-qa.yml` **не используется** при стандартном App Store билде. Конфигурация содержит дубликат отдельного `WatchPhysicalQA/Watch.Info.plist` и исключает production `WhatWatch/Info.plist` из копируемых ресурсов, чтобы не создавать конфликт двух Info.plist.

## QA-probe для физической записи

Скомпилирован только с `WATCH_PHYSICAL_QA`, при явном аргументе `what-watch-qa-record-once` после реального появления `CaptureView` он ждёт перехода `WatchCaptureController` в `.recording`, затем через 7 секунд вызывает реальный `stopCapture`. В `Documents/WatchPhysicalQA/status.json` сохраняет только стадию, время, число ожидающих и сообщение об ошибке. Сам AAC и UUID остаются в своём Watch `Documents/WhatOutbound` и отправляются iPhone штатным WatchConnectivity. Полное испытание должно независимо подтвердить **один и тот же UUID** в Watch-очереди до ACK и в iPhone index после импорта, отсутствие дублей и удаление источника только после ACK.

## Фактическое состояние, не выдавать за PASS

QA-пара успешно собрана, подписана и установлена на оба физических устройства, без изменения личных приложений. iPhone QA-контейнер после запуска содержал только пустые `Audio`, `PhoneCaptures`, `Videos`. Первый запуск физического Watch QA дал статус `waiting-for-microphone`, `pending=0`, и `Documents/WhatOutbound` оказался пустым. Позднее CoreDevice при чтении статуса кратковременно сообщил `Timed out while attempting to establish tunnel`, затем связь и доступ к watchOS приложению восстановились; статус записи не изменился. **Новая физическая аудиозапись, очередь/ACK/offline пока не проверены.** После сборки диагностического QA-probe и повторной установки в этот же отдельный Watch bundle `AVAudioApplication.shared.recordPermission` на реальном устройстве вернул **`undetermined`**. Разрешение не отклонено: приложение ожидает пользовательского подтверждения системного доступа на экране часов. Пока оно не получено, запись, импорт, ACK и офлайн-тесты не считаются проверенными.

## Оставшийся безопасный тест

1. Пользователь вручную разблокирует/активирует Apple Watch, откроет отдельное приложение `UhWhat` QA с идентификатором выше и при необходимости подтвердит системный диалог доступа к микрофону. Не менять сопряжение и не отключать сеть произвольно.
2. Запустить при активном QA-приложении физическую 7-секундную запись и проверить `Documents/WatchPhysicalQA/status.json` и `Documents/WhatOutbound/queue.json` без передачи AAC на Mac.
3. Сверить UUID и счётчик в независимой QA-библиотеке iPhone, потом повторить с разрывом соединения/возвратом связи только способом, согласованным с пользователем и не затрагивающим личные данные. Watch исходник должен удаляться **только после подтверждения** iPhone.

Никакие пользовательские M4A, расшифровки, незавершённые заметки, производственная App Store версия и старые QA-сборки не удалены.
