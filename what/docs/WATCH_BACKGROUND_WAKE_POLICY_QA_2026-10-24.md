# Ухват — условия фонового пробуждения WatchConnectivity (24 октября 2026)

## Почему это новый этап

На физической паре 22 октября Watch использовал WCSession.transferFile при
isReachable=false. Watch-side didFinish пришёл через 0,328 с, но iPhone didReceive(file:)
сработал примерно через 171 с — в начале возвращения QA-приложения из фона.
Commit, ACK и дедупликация затем выполнялись быстро.
Предыдущий акт: PHYSICAL_WATCH_WCSESSION_ROUTE_TIMING_2026-10-22.md.

Новый вопрос — контекст фоновой активности: Background App Refresh,
Low Power Mode, доступность защищённых данных, состояние iOS-приложения
и WCSession. Базовые offline, потерянный ACK и повторная отправка здесь
не тестируются заново.

## Что реализовано

Файл WhatIOS/PhoneWakeEnvironmentQA.swift доступен только при
компиляционном флаге WATCH_ROUTE_QA. Он дописывает в уже имеющийся
Documents/WatchRouteQA/events.json:

- событие content-appear, scene-background, scene-active или wc-session-activation;
- UIApplication.applicationState и backgroundRefreshStatus;
- ProcessInfo.isLowPowerModeEnabled и UIApplication.isProtectedDataAvailable;
- WCSession.activationState и, только после успешной активации,
  isPaired, isWatchAppInstalled, isReachable.

Только чтение публичных API, на MainActor. Журнал содержит имена
состояний и время, без AAC, расшифровок, текстов сообщений, контактов.
Пользовательские настройки и UIBackgroundModes не изменялись.
В производственную сборку это не включается.

## Фактические проверки

- Xcode 27.1, схема WhatIOS, проект WhatWatchPhysicalQA.xcodeproj:
  подписанная iOS QA-сборка BUILD SUCCEEDED; codesign --verify PASS.
- Bundle ID ru.arvectum.tools.what.watchphysqa штатно обновлён
  на реальном iPhone 13 iOS 27.0.1. Production Ухват не затронут.
- Реальный запуск QA для чтения системных значений iOS запретила:
  FBSOpenApplicationServiceErrorDomain RequestDenied, причина Locked
  (телефон не был разблокирован). Поэтому значения Background Refresh,
  Low Power Mode и WCSession на физическом iPhone в этот день
  НЕ получены и не должны представляться как проверенные.
- Не выполняли принудительную разблокировку, radio reset, reboot,
  новую голосовую запись или повтор уже закрытых ACK/offline тестов.
- Артефакты и логи на Mac mini:
  /Volumes/ArvectumSSD/Arvectum/tmp/what-watch-wake-policy-20261024.

## Значение результатов и следующий безопасный шаг

Apple определяет WCSession.transferFile и transferUserInfo как
opportunistic background delivery без гарантии немедленного вызова
delegate. sendMessageData требует isReachable=true:
https://developer.apple.com/documentation/watchconnectivity/wcsession

Background Refresh и Low Power Mode важны для фоновой активности, но
само значение этих флагов не доказывает причину задержки конкретного
transferFile:
https://developer.apple.com/documentation/uikit/uiapplication/backgroundrefreshstatus

После обычной разблокировки iPhone пользователем необходимо только
запустить уже установленную QA-сборку, перевести её в фон открытием
системных «Настроек», затем прочитать события phone-wake-environment.
Это не требует нового AAC и не повторяет прежние физические тесты.

Итог: QA-инструмент создан, подписан и установлен; аппаратная
проверка самих фоновых условий остаётся OPEN из-за Locked.


## Исправлено рассогласование штатного Xcode-проекта с XcodeGen

После проверки обычного What.xcodeproj обнаружилось, что зафиксированный
project.pbxproj не включает несколько уже существующих Swift-исходников
(PhoneCaptureStorage, PrivateMediaProtection, WatchInboundFileReceiver).
Это существовавшее ранее рассогласование, а не ошибка новых фоновых API.
Прежний CI каждый раз пересоздавал проект из project.yml, скрывая проблему
для разработчика, который просто открывает .xcodeproj.

Штатный What.xcodeproj заново сформирован из project.yml, в него
добавлены недостающие файлы. После этого iPhone/watchOS сборка
с CODE_SIGNING_ALLOWED=NO завершилась BUILD SUCCEEDED.
Подписанную производственную сборку здесь не проверяли и не публиковали.

В what-ios-ci.yml добавлен отдельный XcodeGen sync gate:
после генерации CI сверяет проект с закоммиченным .pbxproj и завершится
ошибкой при рассогласовании. Две последовательные локальные генерации
дали одинаковый SHA-1 файла проекта.

Физические фоновые значения iPhone остаются OPEN: iOS отказала в запуске
QA приложения из-за блокировки телефона.
