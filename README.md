# Arvectum Tools

Monorepo for the Arvectum consumer utility family.

**Product rule:** one tool, one job, done.
**Engineering rule:** app = directory; change = branch.
**Privacy rule:** local-first unless a product genuinely needs a backend.

## Repository layout

```text
apps/
  photo-size/       # «Фото под размер» — iOS + Android
  pushkin/          # PUSHKIN — iOS notification utility
  habit-tracker/    # backlog / discovery
packages/           # shared code promoted only after real reuse
docs/               # repository-wide architecture and release conventions
BRAND.md            # shared visual language
PRODUCT_PRINCIPLES.md
ROADMAP.md           # portfolio roadmap
```

Each app owns its bundle/application IDs, versioning, store metadata, tests, release cycle and product roadmap. Shared rules and reusable code stay at repository level.

## Active products

- [Фото под размер](apps/photo-size/README.md) — published utility; post-launch iteration.
- [PUSHKIN](apps/pushkin/README.md) — active feasibility/product development.
- [Habit Tracker](apps/habit-tracker/README.md) — backlog; discovery later.

## Shared-code policy

Do not extract abstractions speculatively. A component becomes shared only when at least two real apps need the same behavior and the common API is clear. See [packages/README.md](packages/README.md).

## Branch model

Long-lived product branches are not the repository structure. Product source lives under `apps/<product>/`; branches describe changes, for example:

- `feature/pushkin-custom-app`
- `feature/photo-size-localization`
- `fix/photo-size-dark-mode`
- `refactor/shared-design-tokens`

`main` remains the releasable integration line.

See [docs/REPO_ARCHITECTURE.md](docs/REPO_ARCHITECTURE.md) and the [portfolio roadmap](ROADMAP.md).
