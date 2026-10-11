# Repository architecture

## Principle

Arvectum Tools is one product-family monorepo. Applications are directories; branches are temporary units of change.

## Ownership

```text
<product>/
  README.md
  ROADMAP.md
  ios/             # when applicable
  android/         # when applicable
  docs/
  store-assets/    # when applicable

core/packages/
  ...shared code only after proven reuse

core/
  ...ecosystem-wide conventions and reusable libraries

growth/
  ...ASO/SEO methods, research agent and channel analytics
```

Each application owns its product requirements, tests, bundle/application identifiers, store assets and release lifecycle.

## Git workflow

Use short-lived branches named for the change:

- `feature/<product>-<change>`
- `fix/<product>-<change>`
- `refactor/<scope>`
- `release/<product>-<version>`

Use `main` as integration and feature branches for development. Existing long-lived feature branches may be kept until their application changes are merged, but are not independent product sources of truth.

## Shared code

Promote code into `core/packages/` only after at least two apps use the same stable concept. Shared code must not depend on a specific app's product model.

## CI

CI should be path-scoped where practical: changes to one app should not require unrelated app builds, while repository-wide shared-package changes should test every dependent app.

## Release independence

A monorepo does not imply synchronized versions. Every app keeps its own version and release cadence.

## Binding enforcement

See [architecture contract](ARCHITECTURE_CONTRACT.md) and the CI gate `.github/workflows/architecture-contract.yml`. The directory layout, ownership and cross-product dependency boundaries are checked on every push and pull request.

## Parallel worktrees

The binding [branch/worktree lifecycle](ARCHITECTURE_CONTRACT.md#branch-and-worktree-lifecycle-binding-decision-2026-10-11) uses short-lived task branches and optional isolated worktrees under `ArvectumSSD/Arvectum/worktrees/`. App, Core and Growth directories always remain in `main`; an inactive product does not need a permanent feature branch.
