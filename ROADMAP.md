# Arvectum Tools — Roadmap Registry

**Ownership rule:** This file is an index, not a duplicate execution plan.
Every task has exactly one owning roadmap. Cross-project dependencies use links,
not copied checkboxes. Apps release independently.

## Product roadmaps
- [Фото и PDF под размер](apps/photo-size/ROADMAP.md) — photo/PDF resizing, document presets, exports, app-specific UX, implementation and QA.
- [Pushkin](apps/pushkin/ROADMAP.md) — notifications capture, history, onboarding, search, reliability and app-specific UX.
- [ChickMark / Habit Tracker](apps/habit-tracker/ROADMAP.md) — habits, tracking, recurrence, reminders and its app-specific UX.
- [Where?](apps/where/ROADMAP.md) — local-only object/photo storage, OCR and semantic retrieval.
- [What?](apps/what/ROADMAP.md) — Apple Watch capture, transfer, transcripts, voice inbox and semantic memory.

## Cross-product roadmaps
- [Arvectum Tools Core](docs/TOOLS_CORE_ROADMAP.md) — shared architecture, reusable packages, release tooling, CI, brand/design primitives.
- [Growth](docs/GROWTH_ROADMAP.md) — acquisition, ASO, SEO, campaigns, retention, monetization strategy and portfolio analytics.

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
Before updating release status, verify the shipping build/tag and store state.
