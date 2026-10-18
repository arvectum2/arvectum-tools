# Фото и PDF под размер — физический iPhone QA (18 октября 2026)

## Изоляция

- Mac mini, Xcode 27.1, реальный iPhone 13, iOS 27.0.1.
- Исходники стабильной main после PR #90/#95 (коммит 172868a), включая адаптивный Core.
- Отдельный XcodeGen проект ios/project.physical-qa.yml с уникальным bundle ru.arvectum.tools.tosize.physicalqa и отдельным контейнером.
- Подпись Apple Development проверена. В entitlements нет доступа к HealthKit, iCloud, App Groups. Установленное пользователем приложение ru.arvectum.tools.tosize и его данные не заменялись.
- Синтетические фото/PDF создаются внутри DEBUG QA приложения через --qa-photo-fixture и --qa-pdf-fixture. Ни личные фото, ни реальные документы пользователя не выбирались.

## Проверки и результаты

| Проверка | Итог |
| --- | --- |
| ARM64 сборка с YandexMobileAds и ArvectumCore | BUILD SUCCEEDED |
| Подпись и установка изолированного приложения на iPhone | PASS |
| Все модульные PhotoPodRazmerTests: AppModel, ImageEngine, PDFEngine, ImportExportIntegrity | 31/31 PASS |
| Сжатие фото, возврат к настройкам | PASS |
| Сжатие PDF и кнопки экспорта | PASS |
| Открытие системного сохранения PDF (без записи файла) | PASS |
| Доступность кнопки импорта из Files | PASS |
| Режимы пикселей и документов | PASS |
| Открытие системного Files picker без выбора файла | PASS |
| Всего UI | 6/6 PASS, 0 ошибок |

Файлы результатов хранятся только на Mac mini в ArvectumSSD/Arvectum/tmp:
- photo-physical-build-20261018.log
- photo-physical-workflows-20261018.log и xcresult (5 UI)
- photo-physical-extra-20261018.log и xcresult (31 unit + 1 UI)

При unit тестах был некритичный StoreKit service warning; итоговый XCTest полностью зелёный. Это не проверка реальной рекламы или StoreKit.

## Ещё требуется до нового релиза

- [x] Контейнерный физический файловый цикл: синтетический PDF (1 400 686 байт, 1 страница) передан только в Documents изолированного QA-приложения через CoreDevice. Обратное копирование файла подтвердило идентичный SHA-256. Настоящий PDFEngine.inspect(fileURL:) + compressByBytes на iPhone обработал его в PDF 48 736 байт (лимит 500 000), с 1 страницей. Выходной файл забран обратно на Mac; статус QA-приложения passed, alreadyFit=false. Личные документы не читались.
- [ ] Отдельно остаётся системный Files picker -> выбор точного QA-файла -> системный fileExporter. Изолированный physical UI тест остановился до первого assert: XCTest Runner timeout enabling automation mode. Этот полный UI путь пока НЕ принят. Нельзя выбирать случайные элементы Recents.

- [ ] Системный Photos picker с тестовым изображением и отдельным разрешением, без чтения личной фототеки.
- [ ] Большие, повёрнутые PDF, ограничения места на диске, проверка сохранённого результата и EXIF.
- [ ] Реклама и согласие РСЯ, App Store review, новая подписанная сборка.
- [ ] Публикация iPad-версии; настоящий fold/unfold Duo физически не проверялся.

Существующие релизы Apple, Growth и Where? не затрагивались.

## iPhone Duo Simulator: системный Files Picker · 18.10.2026

- Реальный SwiftUI fileImporter открывает системный FileProvider на iPhone Duo Simulator, iOS 27.1. Используется только отдельное QA-приложение с локальным ARVECTUM_QA_INPUT.pdf (624 байта, 1 страница).
- Первый UI-прогон обнаружил ошибку теста: поиск «На iPhone» без учёта неразрывного пробела в DOC.sidebar.item.На iPhone.
- Второй UI-прогон дошёл до тестовой папки, но нажатие на вложенную подпись StaticText ARVECTUM_QA_INPUT не завершало импорт в FileProvider.
- После изменения теста на **точный идентификатор системной файловой ячейки** ARVECTUM_QA_INPUT, pdf и двуязычное имя папки, PhysicalQAFilePickerUITests.testImportSyntheticPDFViaPhysicalFilesPickerAndCompress **1/1 PASS, 26.152 s, TEST SUCCEEDED**.
- Проверены путь *локальная папка QA → системный выбор PDF → импорт → сжатие → экран результата → кнопка сохранения*. Никакой файл из Recents не выбран.
- Отчёт ArvectumSSD/Arvectum/tmp/photo-sim-picker-exact-cell-20261018.log и xcresult. Отдельный тест обработки байтов PDF на том же Duo Simulator также PASS: 1 400 686 → 48 736 байт с сохранением страницы.
- **Физический Files picker на iPhone остаётся отдельным открытым gate**, поскольку телефон временно недоступен. Ещё не проведено физическое подтверждение записи через системную панель fileExporter и повторного открытия сохранённого файла.

## Дополнительные артефакты физического файлового цикла

- Mac mini ArvectumSSD/Arvectum/tmp/Arvectum-QA-Files/ARVECTUM_QA_LARGE_INPUT.pdf — синтетический вход
- Mac mini ArvectumSSD/Arvectum/tmp/Arvectum-QA-Files/ARVECTUM_QA_OUTPUT.pdf — настоящий выход с iPhone, 48 736 байт
- Mac mini ArvectumSSD/Arvectum/tmp/Arvectum-QA-Files/ROUNDTRIP_RESULT.json — отчёт on-device QA
- Mac mini ArvectumSSD/Arvectum/tmp/photo-file-full-picker-20261018.log — XCTest Runner, заблокированный до assertions
- Только QA-приложение включает файловый шаринг Documents и DEBUG PHOTO_PHYSICAL_QA; production артефакты не менялись.
