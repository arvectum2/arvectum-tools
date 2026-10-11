# Arvectum Tools Core — Roadmap

**Updated:** 2026-10-11. **Owner:** common rules, brand, code reuse, CI and release infrastructure.

## Current baseline
- [x] Monorepo with independent apps and release cycles.
- [x] Shared brand rules and a canonical common-principles document.
- [x] Path-scoped CI and release checklist recorded in repository.
- [x] Separate portfolio roadmap registry with single ownership.

## Engineering follow-ups
- [ ] Audit CI path filters for newly added apps Where? and What?.
- [ ] Verify shared dependency impact testing and standard release tagging.
- [ ] Define common cross-app crash and privacy-safe telemetry interfaces only when used by multiple apps.
- [ ] Extract UI, ads, analytics, store or privacy packages **only** after at least two real consumers require them.
- [ ] Keep brand/design tokens in [core/BRAND.md](BRAND.md), not repeated in app roadmaps.

## Hard boundaries
No app feature prioritization, app-specific ad activation policy, acquisition metrics, ASO/SEO or marketing experiments.
Canonical policies: [CORE_PRINCIPLES.md](CORE_PRINCIPLES.md) and [REPO_ARCHITECTURE.md](REPO_ARCHITECTURE.md).
