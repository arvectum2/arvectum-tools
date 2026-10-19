# ChickMark — первичная категория App Store (19 октября 2026)

- App ID 6818711298, публичная iOS версия 1.5.0 READY_FOR_SALE, Apple RU storefront (read-only): первичная категория `HEALTH_AND_FITNESS`.
- Решение владельца: сменить на `PRODUCTIVITY`.
- Авторизованная ASC API read-only проверка: ровно один current appInfo с состоянием `READY_FOR_SALE`; обе категории присутствуют в `appCategories` как доступные для `IOS`.
- Единственная **попытка** API `PATCH /v1/appInfos/{id}`, только relationship `primaryCategory = PRODUCTIVITY`: **HTTP 409 ENTITY_ERROR.RELATIONSHIP.INVALID_STATE**. Изменение **не применено**; не предпринимать повторных запросов к тому же состоянию.
- Следующий шаг — открыть редактируемую информацию новой версии ChickMark в App Store Connect и установить Primary Category Productivity до отправки следующего бинарника; сверить по ASC и затем по публичной витрине. Не изменять HealthKit/Privacy/Price/другие категории автоматически. Для опубликованной версии оставить текущую категорию до успешного следующего релизного цикла.
- Источник API контракта: https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-appinfos-_id_ .

Ни API-токены, ни приватные ключи, ни учётные данные не сохранялись в этом документе.
