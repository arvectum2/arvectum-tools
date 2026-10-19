# Ухват: физическое восстановление после фона, iPhone 13 / build 9

19.10.2026. iPhone 13 / iOS 27.0.1. Только изолированный `ru.arvectum.tools.what.multimodalqa` build 9, Xcode 27.1, `--ui-testing --disable-cloud-sync what-physical-qa=background-after-flips`.

Перед тестом прочитан QA-индекс с 19 заметками. Production Ухват и Watch не затронуты.

1. QA-процесс открыл штатный `VideoRecordingSheet`, сделал три настоящих front/back переключения камеры. `stage=ready-for-background`, `recordedFlips=3`.
2. На iPhone запущены системные Settings, что дало реальный `ScenePhase.background`; журнал QA: `stage=backgrounded`.
3. QA-приложение возвращено на передний план. Журнал: `stage=saved-after-background`, **одна** новая долговечная видеозаметка исходной сессии, duration **25.5567 s**.
4. Повторно скопирован *только* JSON метаиндекса. После теста **20 заметок**, потеря старых **0**, новых **1**.

**PASS**: тройное переключение → фон → штатное сохранение сессии на физическом iPhone, без потери уже существовавших заметок. Это не имитирует входящий звонок, принудительное завершение iOS, перезагрузку Watch или хранение при заполненном диске.

Артефакты: `/Volumes/ArvectumSSD/Arvectum/tmp/what-background-build9-20261019`.
