# C18 — авторизованная read-only проверка App Store Connect, 28.10.2026

Проверены только `GET /v1/apps/{id}/appStoreVersions?limit=25` с авторизованным токеном ASC, созданным локальным `core/tools/asc_c17_release.py`. Токен и секреты не выводились, запросов POST/PATCH/DELETE или Apple uploads не было. Публичные версии по 16 регионам подтверждены отдельно одиночными iTunes Lookup в [C18](ASO_C18_PUBLIC_STORE_QA_2026-10-28.md).

| Приложение | C17 версия | ASC appStoreState | releaseType | Публичный Lookup (16/16) |
| --- | --- | --- | --- | --- |
| Фото под размер | 1.0.4 | `READY_FOR_SALE` | `AFTER_APPROVAL` | 1.0.4 |
| Pushkin | 1.0.3 | `READY_FOR_SALE` | `AFTER_APPROVAL` | 1.0.3 |
| Ухват | 1.1.2 | `READY_FOR_SALE` | `AFTER_APPROVAL` | 1.1.2 |
| ChickMark | 1.5.3 | **`WAITING_FOR_REVIEW`** | `AFTER_APPROVAL` | **1.5.2** |

Вывод: **три C17 версии опубликованы**, ChickMark 1.5.3 **остаётся на проверке Apple**, нет основания объявлять её опубликованной или отклонённой. `WAITING_FOR_REVIEW` — не `REJECTED` и не гарантия будущего одобрения. Apple может изменить review state после этого снимка, поэтому проверка и уведомление о решении остаются отдельной задачей.

Ограничения: перечень статусов из версии приложения, а не полный архив App Review сообщений; здесь не проверялись живые App Privacy questionnaire, аналитика, доход РСЯ, Apple review notes, реальная поддержка iOS/Watch или TestFlight. Никаких физических устройств не использовано и никаких новых релизных действий не выполнялось.
