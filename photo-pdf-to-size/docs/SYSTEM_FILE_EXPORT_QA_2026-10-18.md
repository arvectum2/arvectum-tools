# Photo PDF QA — системный импорт и экспорт через Files

Дата: 18 октября 2026 года. Изолированный XcodeGen проект photo-pdf-to-size/ios/project.physical-qa.yml, bundle ru.arvectum.tools.tosize.physicalqa. Production-приложение, медиатека, iCloud и личные документы не используются.

## Подтверждённый файловый цикл

1. В приватный Documents QA-приложения засеивается только синтетический одностраничный PDF ARVECTUM_QA_INPUT.pdf (624 байта).
2. Системный SwiftUI fileImporter: локальное расположение «На iPhone» или «На iPad», только папка Photo PDF QA (или Фото PDF QA). Выбирается системная файловая ячейка с точным идентификатором ARVECTUM_QA_INPUT, pdf. Не выбирать элементы Recents.
3. Нажать «Уменьшить PDF», дождаться ГОТОВО и нажать «Сохранить файл».
4. Системный fileExporter: прежде чем сохранять, тест подтверждает breadcrumb Photo PDF QA, Меню действий и использует только системную кнопку с идентификатором DOCPicker.actionButton и подписью Сохранить.
5. Вернуться на главный экран. Через fileImporter выбрать строго pdf-do-razmera, pdf и убедиться, что PDF принят и доступен к обработке.
6. Независимо проверить появление Documents/pdf-do-razmera.pdf в контейнере ru.arvectum.tools.tosize.physicalqa. pdfinfo: PDF 1.4, 1 страница, 624 байта, без шифрования. SHA-256 исходного и экспортированного файла: 93aece5f694ff297e9b392256743c57d5a6ea3c9df35e18034243466e3f71cee.

Тест: PhotoPodRazmerUITests/PhysicalQAFilePickerUITests/testImportSyntheticPDFViaPhysicalFilesPickerAndCompress. Выбор папки и нажатие Save ограничены проверяемыми QA-идентификаторами. Тест запускается только с предварительно подготовленным тестовым контейнером.

| Среда | UI | PDF после экспорта |
| --- | --- | --- |
| iPhone Duo Simulator iOS 27.1 | PASS 1/1, 39.696 с, 0 ошибок | PASS: 624 байта, 1 страница, совпадение SHA-256 |
| iPad Air 11 M3 Simulator iOS 27.0 | PASS 1/1, 37.467 с, 0 ошибок | PASS: 624 байта, 1 страница, совпадение SHA-256 |

Локальные артефакты на ArvectumSSD, вне Git: Arvectum/tmp/photo-e2e-reimport2-20261018.{log,xcresult} и Arvectum/tmp/photo-ipad-fully-adaptive-20261018.{log,xcresult}.

Это тест **сохранения и повторного открытия**, а не уменьшения размера: 624-байтовый PDF уже ниже лимита, его байты не меняются. Физическое сжатие большого PDF 1 400 686 -> 48 736 байт с одной страницей было отдельно проверено на физическом iPhone 13 и Duo Simulator.

## Осталось

- [ ] Выполнить этот же FileImporter -> FileExporter -> повторное открытие на физическом iPhone после его подключения.
- [ ] Разные места сохранения Files и iCloud не тестировались: сейчас только приватная папка QA.
- [ ] Проверить отмену, повтор с тем же именем, недостаток места, ограничения доступа и прерывания.
- [ ] Ни один тест не должен удалять пользовательские файлы или обращаться к Recents.

Growth и Where? не изменялись; QA-компиляция ограничена Debug.
