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

- [ ] Настоящий Files import -> сжатие -> сохранение -> повторное открытие специально созданного тестового файла. Нельзя выбирать произвольный файл в Recents, там могут быть личные данные.
- [ ] Системный Photos picker с тестовым изображением и отдельным разрешением, без чтения личной фототеки.
- [ ] Большие, повёрнутые PDF, ограничения места на диске, проверка сохранённого результата и EXIF.
- [ ] Реклама и согласие РСЯ, App Store review, новая подписанная сборка.
- [ ] Публикация iPad-версии; настоящий fold/unfold Duo физически не проверялся.

Существующие релизы Apple, Growth и Where? не затрагивались.
