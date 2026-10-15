# Arvectum Tools — Roadmap Registry

**Ownership rule:** This file is an index, not a duplicate execution plan.
Every task has exactly one owning roadmap. Cross-project dependencies use links,
not copied checkboxes. Apps release independently.

**Исполняемая очередь 2026-10-15:** [Единый план работ без Where?](EXECUTION_PLAN.md). Where? поставлен на паузу; остальные продукты, Core и Growth остаются в scope.

## Product roadmaps
- [Фото и PDF под размер](../photo-pdf-to-size/ROADMAP.md) — photo/PDF resizing, document presets, exports, app-specific UX, implementation and QA.
- [Pushkin](../pushkin/ROADMAP.md) — notifications capture, history, onboarding, search, reliability and app-specific UX.
- [ChickMark / Habit Tracker](../chickmark/ROADMAP.md) — habits, tracking, recurrence, reminders and its app-specific UX.
- [Where?](../where/ROADMAP.md) — local-only object/photo storage, OCR and semantic retrieval.
- [What?](../what/ROADMAP.md) — Apple Watch capture, transfer, transcripts, voice inbox and semantic memory.

## Release status snapshot — 2026-10-15

This is a dated distribution status overview, not a second feature checklist. [App Store and Git provenance evidence](RELEASE_PROVENANCE_20261015.md).
Owner reports, actual App Store Connect checks and source/build verification
are different types of evidence. Unverified new approvals must not be assumed.

| Product | Last confirmed public iOS release | Pending Apple review | Evidence and remaining work |
| --- | --- | --- | --- |
| Фото и PDF под размер | **1.0.1 (13)** READY_FOR_SALE, authenticated ASC **2026-10-15** | None | Exact build 13 VALID; post-release export and live ads QA open |
| ChickMark | **1.4.0 (8)** | **1.4.1 (15)** **IN_REVIEW**, authenticated ASC 2026-10-15 | A3 Cloud KVS duplicate safety [PR #71](https://github.com/arvectum2/arvectum-tools/pull/71) merged into main; local history 4/19/20 verified, A1/A4/A6/A7 physical/external gates remain open; patches not in Apple's build 15 |
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
