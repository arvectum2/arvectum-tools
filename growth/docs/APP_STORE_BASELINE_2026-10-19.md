# Growth — первая подтверждённая база App Store RU, 19 октября 2026

**Источник:** официальный публичный Apple iTunes lookup, country=ru, с данными as-of 19.10.2026. Названия, версии, рейтинг и количество оценок относятся к **RU-витрине**, не являются глобальной аналитикой и не показывают число скачиваний.

| Приложение | Apple ID | RU публичная версия | RU средняя оценка | RU количество оценок |
| --- | --- | --- | --- | --- |
| Pushkin | 6817847111 | 1.0 | Нет оценок (Apple возвращает 0) | **0** |
| Ухват | 6822476399 | 1.1.0 | Нет оценок (Apple возвращает 0) | **0** |
| ChickMark | 6818711298 | 1.5.0 | **5.0 / 5** | **2** |
| Фото/PDF | 6816346084 | 1.0.1 | **5.0 / 5** | **2** |

Примечание: рейтинг 0 при количестве оценок 0 — отсутствие оценок в этом API/storefront, **не «низкая оценка»**. Эти малые выборки не являются доказательством качества/органического ранжирования.

## App Store Connect Analytics — недоступны через текущий ключ

- Read-only GET для analyticsReportRequests выполнен по каждому из четырёх Apple app ID.
- В каждом случае API ответил **HTTP 403, FORBIDDEN_ERROR, This request is forbidden for security reasons**.
- Поэтому **impressions, product page views, first-time downloads, conversion и retention не удалось получить**. Эти поля в базовой таблице надо записывать как **нет доступа**, а не 0.
- Доступ к App Store versions/builds/reviews у текущего ключа есть, но это не означает доступа к Analytics.
- По документации Apple [Analytics Reports API](https://developer.apple.com/help/app-store-connect-analytics/overview/analytics-reports-api/) и [Downloading Analytics Reports](https://developer.apple.com/documentation/appstoreconnectapi/downloading-analytics-reports), запрос новой категории отчётов впервые требует ключа с ролью **Admin**; для чтения подготовленных отчётов предусмотрены ключи **Sales and Reports** или **Finance**. Не менять существующий publishing key и не расширять ему права вслепую: предпочтительнее отдельный минимально привилегированный ключ для отчётов, после согласования владельца.
- На этом этапе новый запрос генерации Analytics не создавался и никакие права/ключи не изменялись.

## Следующие строго измеримые шаги

- [x] Датированный read-only Apple RU с версиями, категориями, средними оценками и числом оценок.
- [x] Зафиксирована точная проблема доступа Analytics: 403 во всех четырёх приложениях.
- [ ] Получить отдельно согласованный доступ к Analytics Reports, затем начать ежедневную baseline таблицу по RU и другим интересующим storefronts.
- [ ] Отдельно снять РСЯ fill, impressions, real revenue (SDK тестовые показы не зачесть).
- [ ] После фактического деплоя сайта снять индекс/показы/клики в Google Search Console и Яндекс Вебмастер; зелёный site CI не означает начатую индексацию.
- [ ] Не запускать стимуляцию платных/фиктивных загрузок, спам или Growth Agent без явного решения.

**Локальные подтверждения без секретов:** на ArvectumSSD, в Arvectum/tmp/growth-baseline-20261019, лежат public-ratings-and-versions.json и analytics-discovery.json. Токены и API private keys не добавляются в Git.
