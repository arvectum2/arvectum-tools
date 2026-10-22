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
- Core -> any product or Growth code: **forbidden**. An explicit, reviewable allowlist for repository-wide source-inspection tools and QA fixtures may refer to product paths without importing product modules or introducing runtime dependencies.
- Growth -> private app code as imports: **forbidden**. Reading *documented output/manifests* is allowed; modifying app metadata or public publishing requires explicit approval.
- Never put app-specific design, monetization thresholds or release tasks in Core. A single app's enhancement cannot silently become a shared policy.
- Do not extract shared code until two products actually need the same stable API. Shared brand tokens live in `core/packages/ArvectumDesignTokens/`; keep product-specific semantics inside product targets.
- External dependency versions must come from the catalogs in `core/dependencies/`. Build files may contain pinned application/toolchain versions and generated projections only; floating production dependencies (`latest`, `+`, unreviewed major upgrades) are prohibited.
- Each app owns its `ROADMAP.md` and releases; no copied checkboxes/statuses across roadmaps. Cross-project dependencies are links.
- One repository, shared `main` integration, short-lived feature/fix/release branches. Existing app branches remain until merged and are not canonical independent codebases.

## Branch and worktree lifecycle (binding decision 2026-10-11)

- **Directories are permanent owners. Branches are temporary change sets.** Do not create permanent `feature/core`, `feature/growth`, `feature/pushkin`, etc. merely to represent a domain.
- `main` in `ArvectumSSD/Arvectum/repos/arvectum-tools` is the canonical integration branch and contains all seven domains.
- Start an independent task with a branch from the current `main`: `feature/<domain>-<goal>`, `fix/<domain>-<issue>`, `refactor/<domain>-<scope>`, or `release/<domain>-<version>`. Names should describe real, bounded work, not indefinite ownership.
- When work proceeds in parallel or requires an isolated build, attach the branch as a Git worktree under `ArvectumSSD/Arvectum/worktrees/<domain>-<goal>`. All such worktrees share the **same** canonical Git object database.
- Legacy task branches are retired after their contents are integrated (What? and ChickMark merged on 2026-10-11); a branch is not an independent canonical repository.
- An inactive domain (including Core, Growth, Pushkin, Photo/PDF and Where?) needs **no dedicated branch or worktree**. Create them when a concrete implementation task begins.
- Keep the branch's changes scoped to its owning domain plus necessary `core/` interfaces or CI changes. Cross-domain changes require explicitly documented coordination and per-domain validation.
- Before integration: sync with `main`, run architecture validation, run relevant build/tests, review the diff and release impact; merge through reviewed PR or equivalent documented review.
- After merge: confirm GitHub and GitVerse SHAs, remove obsolete worktrees and completed task branches. Preserve published source via annotated release tags and archival evidence; never keep a duplicate checkout just for historical retention.
- Do not delete dirty worktrees or unique commits. Audit and preserve valuable state first. Do not force-push or rewrite published history as part of routine cleanup.

This model allows independent concurrent development **without fragmenting the ecosystem into seven permanently diverging codebases**.

## Automated policy enforcement
`core/tools/check_architecture.py` checks the exact top-level structure, roadmap presence, symlink escapes, cross-domain source path references, Swift module imports and invalid local project references. It uses a source-only scan to avoid punishing historical prose. Run with `python3 core/tools/check_architecture.py`. CI trigger impact is independently checked by `python3 core/tools/check_ci_coverage.py`; this read-only orchestration check is permitted to name product workflow paths, not import product code.

Changes to this contract or allowlist require review in Core. Do not disable or suppress the CI check to get unrelated code merged.

## Delivery gates
1. Run architecture check before committing and in every PR/push.
2. Run scoped application tests for changed directories. Updating Core shared code must trigger dependent app checks; dependency update PRs are reviewed, not auto-merged.
3. Check release/build number provenance before marking an App Store build published.
4. Push `main` and relevant feature branches to GitHub; confirm mirrored branch SHA in GitVerse.
