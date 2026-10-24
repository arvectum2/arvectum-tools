# Arvectum Tools — актуальная очередь на 24.10.2026

> Срез составлен по исходникам, документам, реальным QA-актам и read-only проверкам на Mac mini 24.10.2026. Чекбокс [x] означает доказанный результат, а не обещание или публикацию App Store.

## Проверено сегодня

- [x] Репозиторий `arvectum-tools`: `main...origin/main`, чистое дерево; HEAD `319bca9` (24.10). GitHub Actions по текущему HEAD: Architecture contract, Localization portfolio, Uhvat capture reliability CI и GitVerse mirror — SUCCESS.
- [x] Ухват/What?: в `main` синхронизирован XcodeGen-проект; семантическая проверка 92 Swift target entries PASS, а исторический пропуск исходников обнаруживается. Обычная iOS/watchOS unsigned build ранее PASS. **Это не новый подписанный production release.**
- [x] Уже выполненные аппаратные тесты Ухвата не повторяем: 18/18 FileProtection/recovery/fault/AXXXL на iPhone 13; 132 XCTest, 0 FAIL и 3 expected SKIP для PhoneCaptures; Watch receiver 15/15; отдельный cold-background доставил 1 AAC; трасса другого `transferFile` показала ~171 с до iPhone `didReceive` при foreground. Реальная своевременная доставка в фоне всё ещё **не доказана**.
- [x] Сборка с диагностикой Background App Refresh / Low Power / protected data / scene / WCSession установлена в отдельный QA bundle на iPhone. Физические значения **не собраны**: iOS вернула RequestDenied: Locked.
- [x] Arvectum Site: [PR #15](https://github.com/arvectum2/arvectum-site/pull/15) OPEN, MERGEABLE, обе проверки SUCCESS. Это **не** merge и **не** деплой.

## P0 · Сегодня — завершить новый этап без повторов

- [ ] **T24-01 · Ухват — фоновые условия на iPhone.** После штатной разблокировки iPhone запустить уже установленный `ru.arvectum.tools.what.watchphysqa`; выполнить один цикл active → Settings/background → active; прочитать `WatchRouteQA/events.json` и зафиксировать реальные Background Refresh, Low Power Mode, protected data, scene, WCSession. Не создавать новый AAC, не менять системные настройки и не трогать production bundle.
- [ ] **T24-02 · Ухват — решение по фоновому обещанию.** Сопоставить измерения с уже задокументированным `transferFile`, отделить гарантированное сохранение на Watch/доставку с ACK от негарантируемой задержки iOS. При необходимости сформулировать честный UX-статус «на часах / ожидает доставки / на iPhone». Не перезапускать закрытые radio-offline/lost-ACK/10-second тесты.
- [ ] **T24-03 · Физический UX/безопасность.** По возможности на отдельном QA bundle закрыть VoiceOver и сценарии обычного пользовательского восстановления, не изменяя личные данные, Shortcuts, HealthKit и production приложения. Для reboot до первой разблокировки, настоящего OS kill, ENOSPC, 30+ минут, входящего звонка, encrypted backup/restore и Watch radio/reboot — отдельные контролируемые аппаратные прогоны; не отмечать выполненными без актов.

## P1 · Следующие практические задачи

- [ ] **T24-04 · Фото/PDF 1.0.2 RC.** Физический import/export: Files, Photos, HEIC/EXIF, повёрнутые PDF, consent/deny/no-fill native+banner РСЯ, VoiceOver. Ранее подтверждённые PDF orientation, 3.0 MB → 464 KB и full Files roundtrip не повторять без регрессии.
- [ ] **T24-05 · ChickMark.** Изолированно проверить живой UI привычки и HealthKit water (check-in/edit/undo, revoke/regrant); CloudKit/Watch и безопасное обновление — отдельные gates. Симулятор consent и scoped HealthKit API уже проверены, они не равны полной физической UI-приёмке.
- [ ] **T24-06 · Pushkin.** Только read-only сверка текущего Apple review/public build 1.0.1(5) против опубликованной версии; не считать статус WAITING_FOR_REVIEW от 19.10 актуальным без свежего запроса. Shortcuts E2E уже подтверждался; личные автоматизации не трогать.
- [ ] **T24-07 · Growth сайт.** PR #15 технически готов к рассмотрению: подготовить checklist smoke/rollback для SEO-страниц. Merge/deploy, фактический sitemap, HTTP и Search Console/Вебмастер — только после отдельного решения владельца о публикации сайта.
- [ ] **T24-08 · ASO/аналитика.** ChickMark изменить на Productivity только при следующем разрешённом редактируемом App Store Connect состоянии (публичная версия ранее дала HTTP 409). Analytics `403` означает нет доступа, а не нулевые показы/установки; РСЯ и индексацию измерять только после доступа/факта.

## Отложено и границы

- [ ] **P2 · Android Фото/PDF:** 41 из 50 локалей, независимый hardware QA, TalkBack. После закрытия P0/P1, не в критическом пути сегодняшнего дня.
- [ ] **PAUSED · Where?, SmartSearch, Growth Agent:** не начинать без нового продуктового решения.
- [ ] **Release gate:** ни App Store Connect/TestFlight/upload/review/publication, ни изменение live metadata, ни деплой сайта не следуют автоматически из зелёного CI, обновления дорожной карты или общего «продолжай». Требуется отдельная конкретная авторизация.

**Definition of done на сегодня:** T24-01 — реальные значения и сохранённый QA-протокол; T24-02 — обоснованное решение по гарантиям фоновой передачи; T24-03/04/05 — только фактически пройденные сценарии. Задачи без физического доступа остаются OPEN, а не объявляются выполненными.

Источники: [What? roadmap](../../what/ROADMAP.md) · [Фоновые условия](../../what/docs/WATCH_BACKGROUND_WAKE_POLICY_QA_2026-10-24.md) · [Сверка Watch](../../what/docs/PHYSICAL_WATCH_ACCEPTANCE_DEDUP_2026-10-22.md) · [Growth](../../growth/ROADMAP.md) · [Релизные ограничения](../../AGENTS.md).
