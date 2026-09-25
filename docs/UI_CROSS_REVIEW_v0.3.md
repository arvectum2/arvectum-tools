# «Фото под размер» — UI/UX Cross-Review v0.3

**Date:** 2026-09-24
**Scope:** UI/UX only. Product functionality remains feature-frozen.

## Review 1 — Brand integrity
**Finding:** v0.2 used a generic cobalt palette and a text-only product header.
**Correction:** added the original Arvectum wordmark asset, preserved its proportions, and moved the UI onto the current Arvectum brand system.

## Review 2 — Color and family coherence
**Finding:** the app did not visually belong to the same family as Arvectum Proxy Launcher.
**Correction:** adopted the Proxy Launcher visual grammar — deep technological background, graphite working surfaces, restrained mint accent — using the current Brand Guide v2 colors: Deep Navy #041A33, Graphite #243446, Mint #43E5C5, Mint Light #7AF1DD, Soft Gray #F3F5F7, White #FFFFFF.

## Review 3 — Information architecture
**Finding:** the three modes behaved like unrelated filter chips and could wrap.
**Correction:** converted them into a single fixed segmented row: По весу · По пикселям · На паспорт. Equal widths, single-line labels, selected mint state, no wrapping.

## Review 4 — Hierarchy and action clarity
**Finding:** Material defaults produced too many equally weighted controls and cards.
**Correction:** introduced one dominant mint CTA per state, graphite task cards, navy inset status blocks, compact technical labels, and secondary outline actions. Reduced vertical noise while keeping 18 dp side margins.

## Review 5 — Passport workflow consistency
**Finding:** the crop screen looked like a separate utility.
**Correction:** applied the same Arvectum header/footer, graphite card, mint crop frame, primary/secondary button hierarchy, and technical result copy. No new photo-processing capability was introduced.

## Review 6 — Accessibility and responsive review
**Finding:** a three-column mode selector can become fragile on narrow screens and with larger text.
**Correction:** raised mode controls to a 48 dp touch target, reduced label size only inside the selector, added selected/tab semantics, retained full-size typography elsewhere, and kept every mode in one row.

## Review 7 — System-level polish
**Finding:** status/navigation bars and the launcher icon still used the old generic palette.
**Correction:** aligned Android system chrome and the existing utility icon with Arvectum Deep Navy + Mint. Added a persistent Arvectum.com footer and kept the product title subordinate to the master-brand wordmark.

## Final acceptance

- Original Arvectum logo at the top.
- Arvectum.com at the bottom.
- Current Arvectum Brand Guide v2 palette.
- Same visual grammar as Proxy Launcher without copying its product-specific controls.
- Three mode buttons always in one row.
- Light/dark system variants preserved.
- No product features added during the UI pass.
- Core task remains usable without network access.
- v0.3 is a visual/interaction revision only; feature freeze remains in force.
