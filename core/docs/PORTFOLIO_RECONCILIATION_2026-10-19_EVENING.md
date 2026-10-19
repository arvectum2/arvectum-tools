# Arvectum Tools — единая сверка релизов и очереди, 19 октября 2026, вечер

**Канонический текущий срез.** Ниже статусы из официального публичного Apple RU Lookup, authenticated App Store Connect для Пушкина, GitHub PR и протоколов физического QA. Старые датированные абзацы во вложенных дорожных картах — история, а не текущие команды к действию. Исходники в main, сборка на устройстве, загрузка в ASC, App Review и публичная App Store-версия — пять разных состояний.

## Проверено позднее 19.10 — приоритетные задачи (поверх исходного среза)

- [x] Pushkin App Review read-only повторно **WAITING_FOR_REVIEW**, releaseType **AFTER_APPROVAL**; решение Apple остаётся внешним блокером.
- [x] **ChickMark**: Water settings/consent **2/2 simulator UI PASS**, на физическом iPhone XCUITest Runner дважды timeout при включении automation, реальный Settings revoke/regrant не зачтён. [Протокол](../../chickmark/docs/WATER_SETTINGS_QA_RECHECK_2026-10-19.md).
- [x] **Фото/PDF**: настоящий iPhone QA PDF 0/90/180/270 градусов, 4 страницы **2 999 791→464 545 байт**, визуальная корреляция страниц min **0.99257**, прежние тестовые файлы восстановлены. [Протокол](../../photo-pdf-to-size/docs/PHYSICAL_ROTATED_FOUR_PAGE_PDF_2026-10-19.md). Физический Files exporter roundtrip также был ранее PASS.
- [x] **Growth site**: [PR #15](https://github.com/arvectum2/arvectum-site/pull/15), commit **8b5dc3f**, оба GH checks **SUCCESS** и полный локальный npm run verify PASS. Исправлена область действия CI для noindex /schlam и оптимизированы два скриншота Ухвата. **PR не merged, сайт не deployed**. Прежняя красная CI проверка ниже — архивное состояние.
- [ ] Ухват: реальные входящий звонок, 30+минутное видео, радио-offline/reboot Watch и production upgrade остаются открыты. Безопасные 420s/watch-ACK QA уже проверены.
- [ ] Следующий physical QA: ChickMark real UI + разрешения/CloudKit/Watch, Фото/PDF Photos picker/ad permissions. Новых Apple отправок/сброса данных/деплоя сайта не делали.

## Светофор продуктов и инфраструктуры

| Направление | Статус | Публично / фактически | Ближайшие незавершённые критерии |
| --- | --- | --- | --- |
| Pushkin / Пушкин | 🟡 На проверке Apple | Public 1.0, **1.0.1 (5) WAITING_FOR_REVIEW**, submission 19.10.2026 16:19:18 UTC, **AFTER_APPROVAL** | Дождаться Apple, сверить READY_FOR_SALE + rollout; реальный upgrade личной App Store-установки не проверялся |
| Ухват / What? | 🟡 Выпущен, новые исправления в main | Public **1.1.0 (8)**; более новые видео/Watch фиксы и QA не доказаны как опубликованные | Сложный звонок/interruption, 30+ мин, реальный Watch offline/reboot, Speech permission, safe production upgrade, напоминания/связка ChickMark |
| ChickMark | 🟡 Выпущен, новая функция в main | Public **1.5.0 (18)**; HealthKit dietaryWater в main, PR #94 MERGED, но не в public 1.5.0 | Живой UI check-in/undo + revoke/regrant, CloudKit/Watch/data-preserving production upgrade; категория Productivity в следующей редактируемой версии |
| Фото и PDF под размер | 🟡 Выпущен, следующий RC локально | Public **1.0.1 (13)**; signed **1.0.2 (14)** с поворотами PDF не опубликован | Реальные Files/Photos импорт и экспорт, rotated/large PDF, native/banner РСЯ/consent/no-fill, согласование отдельного выпуска; Android статус отдельно не доказан |
| Where? | ⚪ Пауза по решению владельца | Нет подтверждённого релиза; local-only MVP и expiry/PAO спланированы, не реализованы | Не начинать разработку до новой команды владельца |
| Core | 🟡 База интегрирована | AdaptiveLayout + 4 активных продукта в main через PR #90, 38/38 CI PASS | App-specific iPad/VoiceOver/system QA, реальная Duo fold/unfold не проверена, provenance выпусков и безопасные upgrade-тесты |
| Growth | 🟡 Есть материалы, нет достоверной базы метрик | App Store карточки доступны; сайт [PR #15](https://github.com/arvectum2/arvectum-site/pull/15) OPEN, CI **verify SUCCESS** и Mirror SUCCESS, PR OPEN, **не deployed** | CI исправлен; согласовать merge/deploy отдельно; снять базовые ASO/RСЯ/SEO показатели; категория ChickMark |
| Growth Agent | ⚪ Пауза | Проектная карта есть, агент не активирован | Не запускать парсеры/посты/платные действия без baseline и отдельного решения |

**Итог по 8 направлениям:** 🟡 **6 активных / частично готовых**, ⚪ **2 на паузе** (Where? и Growth Agent). В единой очереди **4 P0**, **5 P1**; решённые релизы и тесты отмечены выполненными внутри своих направлений, поэтому не приравниваются к «закрыто всё приложение».

*Условные обозначения:* 🟢 пройдено для указанного этапа; 🟡 частично / следующий проверяемый этап открыт; 🔴 конкретный блокер; ⚪ осознанная пауза. «Неизвестно» не означает ноль. Данные и выполненные QA разных продуктов не взаимозаменяемы.

## Read-only публичные версии Apple RU на 19.10

| Приложение | Apple ID | Публичная версия | Опубликована (UTC) | Категория в Apple RU |
| --- | --- | --- | --- | --- |
| [Pushkin](https://apps.apple.com/ru/app/id6817847111) | 6817847111 | 1.0 | 2026-10-18 21:34:41 | Utilities |
| [Ухват](https://apps.apple.com/ru/app/id6822476399) | 6822476399 | 1.1.0 | 2026-10-18 22:21:56 | Productivity |
| [ChickMark](https://apps.apple.com/ru/app/id6818711298) | 6818711298 | 1.5.0 | 2026-10-18 22:22:41 | Health & Fitness |
| [Фото/PDF](https://apps.apple.com/ru/app/id6816346084) | 6816346084 | 1.0.1 | 2026-10-14 16:47:31 | Utilities |

Публичный Lookup не доказывает build number; он берётся из предыдущего authenticated ASC / релизных протоколов. География этого чтения — Apple RU; другие storefronts не следует автоматически считать сверенными.

## Pushkin: новый статус App Review

- [x] После отдельного согласия владельца 19.10 загружена **именно 1.0.1 (5)** с проверенным SHA-256; Apple processing **VALID, APP_STORE_ELIGIBLE**.
- [x] PR #131: **8/8 GitHub checks SUCCESS**; локальные unit/A6/delete, подписанный QA update 7→8 сохранил **8/8** записей со строгим хеш-сравнением; физический incoming notification → iOS Shortcuts trigger → AppIntent → SwiftData **PASS**. Оба временных Shortcut удалены и все пять исходных автоматизаций сохранены.
- [x] ASC new review submission **c62cc2d3-a78c-4563-b09b-f32a7c05e196**: independent GET returned **WAITING_FOR_REVIEW** at 16:19:18 UTC. AppStore version also **WAITING_FOR_REVIEW**. Release policy **AFTER_APPROVAL** read back, NOT manual.
- [ ] Промежуточный статус не равен релизу. После решения Apple проверить конкретный build, дату и READY_FOR_SALE в RU и при необходимости других storefronts, записать фактические метрики в Growth.
- [ ] На подключённом iPhone **нет production-bundle Пушкина**; не объявлять реальный апгрейд пользовательской Store-базы проверенным. Не переустанавливать/не очищать пользовательские данные.
- [ ] Любой **другой** билд/новая ревью-подача — только после нового согласия. Одобрение 1.0.1 (5) не даёт права отправлять последующие версии.

[Официальный акт принятия Apple](../../pushkin/docs/APPLE_REVIEW_SUBMISSION_1_0_1_BUILD5_2026-10-19.md) · [акт RC5](../../pushkin/docs/PUSHKIN_1_0_1_BUILD5_RELEASE_CANDIDATE_2026-10-19.md).

## Рабочая очередь после отправки Pushkin (без новых публикаций)

| Очередь | Владелец | Конкретное действие | Как зачесть | Блокер |
| --- | --- | --- | --- | --- |
| P0-1 | Core / Growth | Read-only дождаться решения Apple по Pushkin и зафиксировать public vs review | Build5 READY_FOR_SALE + страна/время либо точная причина reject | Решение Apple |
| P0-2 | Ухват | Изолированное безопасное тестирование звонка, 30+ мин, Watch offline/reboot | Результаты реальные, медиа playable, старые UUID без потери | Watch/телефон и тестовое окно; production личные данные не трогать |
| P0-3 | ChickMark | Довести HealthKit UI check-in/edit/undo + Settings revoke/regrant и синхронизацию с Watch/CloudKit | Device-evidence, idempotence, нет чужих HealthKit samples, безопасный апгрейд | Физические разрешения/второе устройство |
| P0-4 | Фото/PDF | Files/Photos, rotated PDF, исходники и экспорт на физическом iPhone | Вход/результат/оригинал, корректная ориентация, размер и доступы | Физические системные picker/Files |
| P1-1 | Growth / Site | **CI исправлен 8b5dc3f, 2/2 GH PASS.** Теперь подготовить безопасный merge/deploy с отдельным разрешением | После согласования: работающий сайт/URL/SEO/index checks | Без согласования не деплоить; /schlam остаётся noindex |
| P1-2 | Growth | Baseline просмотров/показов/загрузок/конверсии, индексации, РСЯ дохода по приложениям | Таблица с датой, источником, регионом, «недоступно» вместо 0 | Доступ к статистике, наличие новых данных |
| P1-3 | ChickMark / Growth | Подготовить смену Health & Fitness → Productivity для следующей editable App Store версии | ASC приняла изменение и публичная категория изменилась после отдельного релиза | Публичная READY_FOR_SALE редакция ранее отклонила PATCH HTTP 409 |
| P1-4 | Core + все активные приложения | Доказать iPad Split View/Dynamic Type/VoiceOver и безопасные scene transitions | App-specific UI/physical acceptance; Duo — только при наличии железа | Нельзя приписывать поддержку из одного merge адаптивного Core |
| P1-5 | Ухват / ChickMark | Напоминание +1/2/3 часа по голосовой заметке, транскрипция и one-off handoff | Реальное уведомление, отказ разрешения, повтор/отмена, тихие часы, межприложное открытие | Интеграционный QA на установленных версиях |
| PAUSED | Where? / Growth Agent | Сохранить backlog, не исполнять | Только явная новая команда владельца | Решение владельца |

## Следствия и границы

1. **Нет ручной публикации Pushkin.** После Apple approval выпускается автоматически. Не создавать дополнительные автоматизации для отслеживания вручную.
2. **HealthKit water в коде ChickMark, не в опубликованном 1.5.0.** Исходная реализация + mock и отдельный real QA не равно production acceptance.
3. **1.0.2 Фото/PDF — кандидат, не Apple-релиз.** РСЯ demo/test не доказывает revenue; Android publication не подтверждена.
4. **Growth site PR #15 не merged и не deployed.** Его красный verify запрещает считать SEO-страницы опубликованными.
5. **Where? и Growth Agent остаются на паузе**; Growth как измерение/SEO/ASO активен.
6. **Никаких самостоятельных App Store upload, Review, изменения карточек, массовых постов, платежей и деплоя по этому обновлению дорожных карт.** Для последующих внешних действий требуются согласование и проверка эффекта.

## Источники, связи и ведение статуса

- Текущий release ledger — этот документ; исполнение — [EXECUTION_PLAN](../EXECUTION_PLAN.md), архитектура — [Core ROADMAP](../ROADMAP.md).
- Продуктовая ответственность: [Pushkin](../../pushkin/ROADMAP.md), [Ухват](../../what/ROADMAP.md), [ChickMark](../../chickmark/ROADMAP.md), [Фото/PDF](../../photo-pdf-to-size/ROADMAP.md), [Where?](../../where/ROADMAP.md).
- Дистрибуция: [Growth](../../growth/ROADMAP.md), [Growth Agent](../../growth/agent/ROADMAP.md).
- Исторические пометки вроде «Pushkin 1.0.1(4) ждёт ревью», «HealthKit only draft PR #94», «8 минут видео не доказаны» относятся к **ранним проверкам 19 октября** и уступают более поздним подтверждённым тестам. Не изменять старые артефакты для выдуманной сплошной истории.
