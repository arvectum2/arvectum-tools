# Arvectum Tools — первичный аудит исходников релизов

**Дата:** 2026-10-15. **Обновление A0:** статический branch inventory ниже выполнен; [новая запись о проверенных IPA, ASC, тегах и точечной интеграции](RELEASE_PROVENANCE_20261015.md) дополняет эти исходные наблюдения. **Метод:** локальный git fetch origin, сравнение merge-base и git diff origin/main...origin/release/* на Mac mini. Это статический аудит веток, **не** тесты приложений, не свидетельство ASC/GitVerse и не разрешение на массовый merge.

| Продукт | Релизная ветка | Последний SHA | Разница истории: только main / только release | Вывод |
| --- | --- | --- | --- | --- |
| Фото и PDF под размер | release/photo-size-ios-1.0.1 | 778297e | 103 / 3 | В release есть отличия проекта Xcode, project.yml и publish-скрипта, ASO metadata, запись релиза и roadmap. Требуется выборочная проверка против main. |
| Ухват | release/what-1.0.1 | c4b700f | 103 / 32 | Крупная отдельная линия: app UI, Watch/complication, модели локального поиска, экспорт, project config, тесты и research/. Нельзя сливать ветку целиком без классификации безопасного production-кода. |
| ChickMark | release/chickmark-1.4.1-public-20261014 | историческая ветка | 30 / 0 | Релизная ветка уже является предком main. Наличие исправлений native-рекламы в main не означает, что они вошли в отправленную Apple 1.4.1(15). |

## Отличия Фото/PDF на release относительно общего предка

- photo-pdf-to-size/ios/PhotoPodRazmerIOS.xcodeproj/project.pbxproj
- photo-pdf-to-size/ios/project.yml
- photo-pdf-to-size/ios/Tools/publish_1_0.py
- photo-pdf-to-size/docs/appstore/RELEASE_1.0.1_2026-10-13.md
- photo-pdf-to-size/docs/aso/metadata-1.0.1.json
- photo-pdf-to-size/ROADMAP.md (документация отличается; live статус уже синхронизирован)

## Ухват: какие зоны требуют предметной проверки

- Релизная структура iOS/watchOS: CaptureView, WatchCaptureController, WhatComplication, Audio/MicrophoneCapturePipeline, durable queues/ACK, PhoneStore и RecordingRepository.
- Большой набор новых интерфейсов: запись на iPhone, Inbox/Archive, транскрипции, WidgetKit, RU/EN assets, экспорт.
- R&D, не переносимое без отдельного решения: research/concept_search.py и смежные файлы, RussianConceptSearch и зависимые ассеты/алгоритмы с неразрешённым коммерческим лицензированием RuWordNet.
- Конфигурация и безопасность: project.yml, Xcode project, entitlements, privacy manifests, сборка и версии всех таргетов.

## Продолжение A0

- [x] Сравнены ветки и зафиксировано расхождение исходников без изменения кода.
- [ ] Создать точный inventory production-файлов и проверенных коммитов из публичных builds для Фото/PDF и Ухвата.
- [ ] Выборочно интегрировать, подтвердить target/build metadata, протестировать diff и сохранить release provenance.
- [ ] Проверить зеркала GitVerse и настоящие release tags/SHA.
- [ ] Проверить новые решения Apple для находящихся на review версий и сохранить внешнее подтверждение.

Ссылка на порядок исполнения: [EXECUTION_PLAN.md](EXECUTION_PLAN.md).
