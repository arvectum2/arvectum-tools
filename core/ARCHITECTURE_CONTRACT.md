# Arvectum Tools — architecture contract (v1)

**Binding for every application and every branch.** Canonical repository: `ArvectumSSD/Arvectum/repos/arvectum-tools` (`main`). GitHub is the source remote, GitVerse is a mirror. Git worktrees are not separate repositories.

## Ownership
| Owner | Scope |
| --- | --- |
| `core/` | Shared policy, brand, release/CI conventions and genuinely reusable libraries in `core/packages/` |
| `chickmark/` | ChickMark app, its data, source, tests, UX, roadmap, release |
| `pushkin/` | Pushkin app, its data, source, tests, UX, roadmap, release |
| `photo-pdf-to-size/` | Photo/PDF tool, iOS+Android, tests, assets, roadmap, releases |
| `what/` | What? voice inbox, Watch/iPhone, source and roadmap |
| `where/` | Where? offline finder and roadmap |
| `growth/` | Acquisition, ASO, SEO, experiments, metrics and growth agent |
| `.github/` | Repository-level automation; checks must follow ownership boundaries |

Root may contain only repository metadata, `LICENSE` and `README.md`.

## Dependency direction
- Product -> platform/system frameworks and explicitly supported `core/packages/`: **allowed**.
- Product -> another product's source/module/private assets: **forbidden**, including relative imports, symlinks and build-time filesystem access.
- Core -> any product or Growth code: **forbidden**.
- Growth -> private app code as imports: **forbidden**. Reading *documented output/manifests* is allowed; modifying app metadata or public publishing requires explicit approval.
- Never put app-specific design, monetization thresholds or release tasks in Core. A single app's enhancement cannot silently become a shared policy.
- Do not extract shared code until two products actually need the same stable API.
- Each app owns its `ROADMAP.md` and releases; no copied checkboxes/statuses across roadmaps. Cross-project dependencies are links.
- One repository, shared `main` integration, short-lived feature/fix/release branches. Existing app branches remain until merged and are not canonical independent codebases.

## Automated policy enforcement
`core/tools/check_architecture.py` checks the exact top-level structure, roadmap presence, symlink escapes, cross-domain source path references, Swift module imports and invalid local project references. It uses a source-only scan to avoid punishing historical prose. Run with `python3 core/tools/check_architecture.py`.

Changes to this contract or allowlist require review in Core. Do not disable or suppress the CI check to get unrelated code merged.

## Delivery gates
1. Run architecture check before committing and in every PR/push.
2. Run scoped application tests for changed directories. Updating Core shared code must trigger dependent app checks.
3. Check release/build number provenance before marking an App Store build published.
4. Push `main` and relevant feature branches to GitHub; confirm mirrored branch SHA in GitVerse.
