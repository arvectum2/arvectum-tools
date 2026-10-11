# Arvectum Tools Core — common principles and ownership

These rules apply to **every** app. Product-specific choices live only in each app's roadmap.

## Product defaults
- One tool, one clear user job; minimize taps and setup friction.
- Local-first processing and privacy by design; request only necessary permissions.
- Fast, native-feeling and accessible interfaces; respect device theme and system controls.
- Keep essential utility flows usable without ad interruption.
- Minimize speculative complexity and avoid premature cross-app frameworks.
- Evaluate new features by actual user utility and available evidence.

## Architecture and delivery
- Monorepo with independent apps in `<product>/`; each has its own release lifecycle.
- Shared components only when at least two apps demonstrate compatible reuse.
- Branches represent changes, never permanent app identity.
- App-specific bugs/UX/tests/release gates belong to that app.
- CI/test scope follows affected apps and shared dependencies; never couple release versions.
- Reusable design tokens belong to [core/BRAND.md](BRAND.md), repository structure to [REPO_ARCHITECTURE.md](REPO_ARCHITECTURE.md).
- Requirements, implementation evidence and store publication are separate states. Never mark published from a successful build alone.

## Ownership boundaries
- **Product:** app-specific functionality, UX, export, platform permissions and SDK implementation.
- **Core:** truly cross-app principles, brand, shared packages and engineering infrastructure.
- **Growth:** search visibility, ASO/SEO, marketing, acquisition, retention and revenue experiments.
- Keep one task in one roadmap. Use references for dependencies, never mirrored status checkboxes.
- Product-specific ad frequency and monetization constraints are not global rules.
