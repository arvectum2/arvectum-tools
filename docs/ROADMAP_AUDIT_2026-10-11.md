# Roadmap ownership audit — 2026-10-11

## Issues found
1. Root ROADMAP mixed portfolio navigation with duplicate app checkboxes and launch narratives.
2. Photo-size ROADMAP mixed historical v0.1 branding/color system, several superseded UI designs, outdated release gates, completed 0.5.x tasks, ASO experiment tasks and newer PDF scope.
3. Pushkin ROADMAP mixed release gate with old future phase checklists, Phase 11 Growth, App Store listing strategy and monetization hypotheses.
4. Habit Tracker ROADMAP contained its own delayed ads rules, which previously were erroneously generalized or copied to Photo Size.
5. Where? and Growth lacked independently maintained roadmap documents; What? had one.
6. Explicit distinctions were missing between repository-implemented, verified on device, submitted for review and user-confirmed published.

## Refactoring
- Core principles are owned by docs/CORE_PRINCIPLES.md; shared brand by BRAND.md; reusable engineering plan by TOOLS_CORE_ROADMAP.md.
- Portfolio index has references only; product roadmaps own app-specific features, defects and shipping verification.
- Photo, Pushkin, ChickMark legacy full documents were moved to their app-local docs/history folders without deleting content.
- Growth has its own roadmap and exclusively owns acquisition, SEO/ASO experiments, commercial KPIs and results.
- Where? and What? remain separate products.
- Product-specific ad implementation and eligibility continue in the app; common ad policies are not imposed.
- Existing release labels are not silently treated as store publication.

## Follow-up evidence gates
- Compare each roadmap against actual shipping release/tag, physical QA and App Store state.
- Confirm branch-specific feature implementations before checking completion.
- Link experiment datasets/metrics when they become available.

No production code changed in this documentation refactor.
