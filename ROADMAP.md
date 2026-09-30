# Arvectum Tools — Portfolio Roadmap

**Status:** canonical portfolio roadmap
**Updated:** 2026-09-30

## Repository model

- [x] One Arvectum Tools monorepo.
- [x] Each application lives under `apps/<product>/`.
- [x] Product roadmaps live with their apps.
- [x] Shared product philosophy and brand rules live at repository root.
- [x] Git branches represent changes, not applications.
- [x] Shared-code area exists under `packages/` with extraction-on-reuse rules.

## Фото под размер

**Status:** published / post-launch iteration.

Canonical product specification: [apps/photo-size/ROADMAP.md](apps/photo-size/ROADMAP.md).

Current post-launch direction includes production advertising, improved before/after App Store screenshots, system Light/Dark adaptation, localization and regional store metadata, country-specific passport-photo requirements, regional naming, control-placement UX review and competitive feature research. Advertising may appear from the first relevant use; the preferred format is a native placement after the result, without blocking the core function.

## PUSHKIN

**Status:** active feasibility and product development.

Canonical roadmap: [apps/pushkin/ROADMAP.md](apps/pushkin/ROADMAP.md).

Current focus is a minimal-onboarding notification capture experience with broad app coverage, preserving the principle that the user should not need extra hardware.

## Habit Tracker

**Status:** backlog / discovery later.

Canonical backlog: [apps/habit-tracker/ROADMAP.md](apps/habit-tracker/ROADMAP.md).

Direction: a simple free habit tracker inspired by the genuinely useful mechanics of HabitKit Pro, intentionally smaller and faster, with minimal setup and clear progress. Core functionality stays free; advertising is delayed until an initial engagement threshold and remains outside the core habit flow.

## Shared platform

### Now

- [x] Repository layout and ownership boundaries.
- [x] Shared product principles.
- [x] Shared brand rules.
- [ ] Add path-scoped CI for each active app.
- [ ] Add repository-level release checklist/template.

### Extract when proven reusable

- [ ] `ArvectumDesign` — colors, typography, common SwiftUI primitives.
- [ ] `ArvectumAds` — ad placement/loading abstractions after production behavior is proven in more than one app.
- [ ] `ArvectumAnalytics` — privacy-safe event conventions.
- [ ] `ArvectumStore` — store/review/release helpers.
- [ ] `ArvectumPrivacy` — reusable disclosure/about surfaces.

Shared packages are created only after real reuse appears; the roadmap entry is not permission to pre-build frameworks.

## Future portfolio

After mass-market utilities establish the brand and store history, specialized power-user tools such as network/NetOps utilities can be added as separate app directories while reusing proven shared packages.
