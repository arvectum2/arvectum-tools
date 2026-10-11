# Arvectum Tools Core — Roadmap

**Owner:** shared engineering infrastructure only.
**Scope:** common brand/design standards, path-scoped CI, release templates, platform-wide diagnostics, and packages that are proven reusable by at least two apps.
**Exclusions:** individual app functionality, app-specific defects, ASO, SEO, ads revenue targets, marketing campaigns.

## Foundations
- [x] Monorepo with isolated app folders.
- [x] Shared product principles and brand rules.
- [x] Path-scoped CI and repository release checklist (see repository history).

## Extract only on demonstrated reuse
- [ ] ArvectumDesign — common tokens and stable SwiftUI primitives.
- [ ] ArvectumAds — only after two apps prove compatible ad-placement/loading needs.
- [ ] ArvectumAnalytics — privacy-respecting event conventions.
- [ ] ArvectumStore — shared review/release helpers.
- [ ] ArvectumPrivacy — shared disclosure/about surfaces.

Product work remains in apps/<product>/ROADMAP.md.
Promote to packages/ only when reuse and API boundaries are established.
See [repository architecture](REPO_ARCHITECTURE.md).
