# Ухват — приём Watch-файла на физическом iPhone, 22.10.2026

Цель: проверить сохранение AAC и UUID до ACK в реализации фонового WCSession callback. Не выдавать локальный unit-test за реальную фоновую отправку с Watch.

## Аппаратура и изоляция
- Физический iPhone 13 iOS 27.0.1 и Mac mini/Xcode 27.1.
- Изолированный iOS QA-бандл ru.arvectum.tools.what.fileprotectqa, без Watch companion, без изменений публичного Ухвата.
- AAC создан программно в отдельной временной UUID-папке QA sandbox. Микрофон, камера и личные записи не задействованы.
- Результат: ArvectumSSD/Arvectum/tmp/what-inbound-background-20261022/DeviceWatchInboundGate.xcresult.

## Код и результат
- Новый WatchInboundFileReceiver.accept проверяет корректный тип, декодируемый AAC, длительность и успешную запись UUID до разрешения ACK.
- WCSession didReceive(file:) использует тот же проверяемый gate. Неудачный импорт не подтверждается.
- Повтор UUID или replay после удаления ACK-совместимы без второй записи или восстановления удалённой.
- Физический XCTest (первый адресный прогон): **3/3 PASS**, 0 FAIL. Полный WatchA2ReliabilityTests: **15/15 PASS**, 0 FAIL, xcodebuild exit 0, сохранён DeviceWatchA2FullSuite.xcresult. Включает BackgroundReceiverStorageGateOnPhysicalDevice, LostACKRealisticAACResend, 24-item queue, ошибку записи ACK, восстановление и конфликт ACK.

## Ограничение и Watch-доступ
Watch виден как available (paired); developer pair восстановлена штатной командой CoreDevice без сброса consumer pairing. Watch lockState доступен, но apps info и запуск существующего приложения Watch QA с аргументом audit истекают по тайм-ауту developer tunnel. Consumer pairing, Bluetooth/Wi-Fi и питание устройств не меняли. **Фоновая WCSession доставка от часов при закрытом iPhone UI, реальный radio-offline и Watch reboot остаются OPEN**. Данный акт подтверждает только физическое сохранение файла iPhone, не транспорт.
