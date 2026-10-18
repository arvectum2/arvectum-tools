# Arvectum Tools — Roadmap Registry

**Ownership rule:** This file is an index, not a duplicate execution plan.
Every task has exactly one owning roadmap. Cross-project dependencies use links,
not copied checkboxes. Apps release independently.

**Исполняемая очередь 2026-10-15:** [Единый план работ без Where?](EXECUTION_PLAN.md). [A5: четыре подписанных кандидата, локальный audit и блокеры отправки](A5_SIGNED_RELEASE_CANDIDATES_20261015.md). Where? поставлен на паузу; остальные продукты, Core и Growth остаются в scope.

## Срез портфеля · 18.10.2026 (по имеющимся релизным доказательствам)
**Источник:** [аудит отправок от 18 октября](https://github.com/arvectum2/arvectum-tools/blob/release/what-chickmark-20261018-rc1/what/docs/RELEASE_AUDIT_WHAT_CHICKMARK_2026-10-18.md). Это датированный документальный срез, **не новый live-опрос ASC**; WAITING_FOR_REVIEW не означает публикацию.

| Продукт | Последняя подтверждённая публичная iOS версия | Более новая ветка / кандидат | Открытый gate |
| --- | --- | --- | --- |
| ChickMark | 1.4.1(15), ASC READY_FOR_SALE 16.10 | 1.5.0(18) submitted 18.10 09:01 МСК, WAITING_FOR_REVIEW | Apple, storefront, безопасный upgrade |
| Ухват / UhWhat? | 1.0.0(5), ASC READY_FOR_SALE 15.10 | 1.1.0(8) submitted 18.10 09:01 МСК, WAITING_FOR_REVIEW | Apple, Watch/data/iPad acceptance |
| Фото и PDF под размер | 1.0.1(13), ASC READY_FOR_SALE 15.10 | 1.0.2(14) signed, upload не подтверждён | Files/PDF/РСЯ device QA |
| Pushkin | публикация не подтверждена | 1.0.0(1) WAITING_FOR_REVIEW при проверке 15.10 | повторная ASC проверка, Shortcuts/delete QA |
| Where? | нет | PAUSED, W0–W3/E0–E5 — план | команда на возобновление |

**Инфраструктура:** Xcode 27.1 и Duo runtime готовы, но Core adaptive — прототип, app-specific iPad/Duo acceptance не завершён. **Growth:** измерение реальных установок и монетизации до любых закупок трафика или автоматизации.

## Product roadmaps
- [Фото и PDF под размер](../photo-pdf-to-size/ROADMAP.md) — photo/PDF resizing, document presets, exports, app-specific UX, implementation and QA.
- [Pushkin](../pushkin/ROADMAP.md) — notifications capture, history, onboarding, search, reliability and app-specific UX.
- [ChickMark / Habit Tracker](../chickmark/ROADMAP.md) — habits, tracking, recurrence, reminders and its app-specific UX.
- [Where?](../where/ROADMAP.md) — local-only object/photo storage, OCR and semantic retrieval.
- [What?](../what/ROADMAP.md) — Apple Watch capture, transfer, transcripts, voice inbox and semantic memory.

## iPad / iPhone Duo (портфельная адаптация, 2026-10-16)

Единая [матрица устройств, приоритетов и критериев QA](DEVICE_ADAPTATION_ROADMAP.md). Конкретные задачи принадлежат пяти продуктовым ROADMAP; статус устройства **не равен** статусу публикации, а iPad-код Ухвата пока находится в отдельной feature-ветке. Where? остаётся на паузе.

**Состояние инфраструктуры (16.10.2026):** Xcode 27.1 активна, CoreSimulator 1174.9.2 работает. **iOS 27.1 Runtime установлена, iPhone Duo создан и успешно загружен.** Тесты fold/unfold и интерфейсов приложений ещё не проводились. Общий адаптивный Core пока в отдельной feature-ветке, релизы не изменены. [Чекпоинты T0–T5](DEVICE_ADAPTATION_ROADMAP.md).

## Release status snapshot — 2026-10-15

This is a dated distribution status overview, not a second feature checklist. [App Store and Git provenance evidence](RELEASE_PROVENANCE_20261015.md).
Owner reports, actual App Store Connect checks and source/build verification
are different types of evidence. Unverified new approvals must not be assumed.

| Product | Last confirmed public iOS release | Pending Apple review | Evidence and remaining work |
| --- | --- | --- | --- |
| Фото и PDF под размер | **1.0.1 (13)** READY_FOR_SALE, authenticated ASC **2026-10-15** | None | Post-release PDF rotation fix [PR #72](https://github.com/arvectum2/arvectum-tools/pull/72) merged in main **but not in public 1.0.1**; 31/31 unit + 5/5 UI, CI success; physical Files/Photos/ATT and YAN real impressions OPEN [#73](https://github.com/arvectum2/arvectum-tools/issues/73); first-use Files/Save clean-simulator failures documented, deterministic CI [#74](https://github.com/arvectum2/arvectum-tools/pull/74) merged |
| ChickMark | **1.4.1 (15)** READY_FOR_SALE, authenticated ASC **2026-10-16** (Apple одобрила последнюю отправленную) | None | Post-build15 Cloud KVS/native ads changes staged as **signed A5 1.4.2 (16) RC** (NOT uploaded); A1/A4/A6/A7 physical/external gates remain open, [A5 evidence](A5_SIGNED_RELEASE_CANDIDATES_20261015.md) |
| Pushkin | Not published | **1.0.0 (1)** Waiting for Review, ASC **2026-10-15** | Build 1 VALID; deletion source fix #68 and local Shortcuts lookup fix #69 merged into main **but not in reviewed binary**; real-device QA pending |
| Ухват / UhWhat? | **1.0.0 (5)** READY_FOR_SALE, ASC 2026-10-15 | **1.0.1 (6)** Waiting for Review, independently reconfirmed 2026-10-15 | A2 source fix #70 merged into main (not submitted build), CI PASS; physical one-tap Watch/interruption/ACK QA open |
| Where? | Not released | None | MVP W0–W3 not independently implemented |

Android publication remains independent: no confirmed public Android release
for Фото/PDF. App-specific acceptance criteria stay with their own roadmaps.

## Cross-product roadmaps
- [Arvectum Tools Core](ROADMAP.md) — shared architecture, reusable packages, release tooling, CI, brand/design primitives.
- [Growth](../growth/ROADMAP.md) — acquisition, ASO, SEO, campaigns, retention, monetization strategy and portfolio analytics.

## Ownership decision guide
- Function or bug in one app → that app's roadmap.
- Reusable infrastructure serving at least two apps → Core; do not extract early.
- Discoverability, promotion, funnel, monetization experiments and metrics → Growth.
- Installing an ad SDK or rendering an ad in a specific app → that app; Growth owns business hypotheses and results.
- Store listing campaign and SEO page → Growth; assets and technical release validation → app when applicable.
- No task/status duplication across roadmaps; link to the owner.
- Git branches represent changes, not permanent app roadmaps.

## Status integrity
Checkboxes in legacy specs are historical evidence, not proof of the current App Store release.
When updating release status, record what is independently verified versus confirmed by the owner; source/build/tag provenance remains a separate release audit gate.
