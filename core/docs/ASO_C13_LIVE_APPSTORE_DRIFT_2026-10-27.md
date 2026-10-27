# C13 — публичный App Store и черновики ASO

27.10.2026. Публичные страницы App Store, просмотр read-only. Это не App Store Connect: web-кэш и карточки разных стран могут обновляться с задержкой.

| Приложение | Опубликованные языки | Черновик ASO | Публичная версия и устройства |
| --- | --- | --- | --- |
| Фото/PDF | RU, EN (2) | 16 регионов / 12 языков планируемого RC | 1.0.0; iPhone |
| PUSHKIN | RU, EN, ES, FR (4) | 16 / 12 | 1.0.2; iPhone; iOS 27.0+ |
| UhWhat? | EN, FR, RU, ES (4) | 16 / 12 | 1.1.1; iPhone, iPad, Watch |
| ChickMark | EN, FR, DE, IT, JA, PT, RU, zh-Hans, ES, zh-Hant (10) | 16 / 12 | 1.5.2; iPhone, iPad, Watch |

Публичные URLs:
- https://apps.apple.com/ru/app/id6816346084
- https://apps.apple.com/ru/app/id6817847111
- https://apps.apple.com/us/app/id6822476399
- https://apps.apple.com/gb/app/id6818711298

## Существенный блокер PUSHKIN

В pushkin/ios/project.yml и сгенерированном pbxproj действительно установлен deployment target iOS 27.0, а у остальных трёх iPhone-приложений — iOS 17.0. Снижение минимума без аудита новых API и испытаний на старых версиях OS не выполнять автоматически.

## Выпуск

- [ ] Сверить метаданные, App Privacy и скриншоты в App Store Connect для точных локалей (read-only).
- [ ] Проверить, что обещанные языки присутствуют в подписанном RC, а не только в ASO-черновиках.
- [ ] Проверить текст рекламы, HealthKit, Watch, privacy по подписанному бинарнику.
- [ ] Решить отдельной инженерной задачей, оправдан ли минимум iOS 27 у PUSHKIN.
- [ ] Не менять live ASO без приёмки RC.

[Матрица C13](ASO_C13_LINGUISTIC_EDITORIAL_2026-10-27.md).
