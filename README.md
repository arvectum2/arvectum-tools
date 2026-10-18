# Arvectum Tools

A single monorepo for the Arvectum Tools ecosystem. **Git branches describe changes; directories own products.**

| Domain | Canonical location |
| --- | --- |
| Ecosystem-wide principles, brand, CI standards, shared packages | [core/](core/) |
| Adaptive iPad + foldable iPhone Duo roadmap and QA matrix | [core/DEVICE_ADAPTATION_ROADMAP.md](core/DEVICE_ADAPTATION_ROADMAP.md) |
| Habit tracker | [chickmark/](chickmark/) |
| Notifications inbox | [pushkin/](pushkin/) |
| Photo & PDF sizing | [photo-pdf-to-size/](photo-pdf-to-size/) |
| Apple Watch voice inbox | [what/](what/) |
| Offline object finder | [where/](where/) |
| ASO, SEO, acquisition, growth agent | [growth/](growth/) |

Canonical code and roadmaps are in this repository on ArvectumSSD. Only `.github/`, Git metadata, legal license and the index README remain at root.

[Portfolio status](core/PORTFOLIO.md) · [Core baseline 2026-10-18](core/BASELINE_2026-10-18.md) · [Core principles](core/CORE_PRINCIPLES.md) · [Growth roadmap](growth/ROADMAP.md).

Release branches and working trees must not duplicate app source directories. GitHub `main` is the source of truth; GitVerse is a mirror.

**Required architecture:** [Core architecture contract](core/ARCHITECTURE_CONTRACT.md) (validated in CI).
