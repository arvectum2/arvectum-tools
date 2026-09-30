# Repository architecture

## Principle

Arvectum Tools is one product-family monorepo. Applications are directories; branches are temporary units of change.

## Ownership

```text
apps/<product>/
  README.md
  ROADMAP.md
  ios/             # when applicable
  android/         # when applicable
  docs/
  store-assets/    # when applicable

packages/
  ...shared code only after proven reuse

docs/
  ...repository-wide conventions
```

Each application owns its product requirements, tests, bundle/application identifiers, store assets and release lifecycle.

## Git workflow

Use short-lived branches named for the change:

- `feature/<product>-<change>`
- `fix/<product>-<change>`
- `refactor/<scope>`
- `release/<product>-<version>`

Do not keep permanent branches whose only purpose is to represent an application.

## Shared code

Promote code into `packages/` only after at least two apps use the same stable concept. Shared code must not depend on a specific app's product model.

## CI

CI should be path-scoped where practical: changes to one app should not require unrelated app builds, while repository-wide shared-package changes should test every dependent app.

## Release independence

A monorepo does not imply synchronized versions. Every app keeps its own version and release cadence.
