# «До размера» — UI/UX cross-review v0.2.1

Date: 2026-09-24

Scope: visual/interaction polish only. Product feature freeze remains in force.

## Review 1 — Brand / visual identity
Reviewer lens: brand designer.

Changes:
- canonical Arvectum wordmark from the existing Proxy Launcher assets is used at the top;
- Arvectum brand palette is applied to the Compose theme;
- layout language is aligned with Proxy Launcher: deep navy, graphite surfaces, mint as an accent rather than a full-page fill;
- `Arvectum.com` is fixed at the bottom of the app shell.

## Review 2 — Accessibility / touch
Reviewer lens: mobile accessibility QA.

Changes:
- three mode selectors are kept in one row;
- each mode target is 48 dp high;
- tab semantics and selected state are exposed;
- secondary actions are 56 dp high;
- mode text size is kept readable without wrapping in normal phone widths.

## Review 3 — Information hierarchy / copy
Reviewer lens: UX writer + information architect.

Changes:
- Russian UI copy is made consistent;
- empty states use one task-oriented headline and one explanation;
- result screen explicitly names the mode and completion state;
- technical details are grouped inside one result card rather than scattered.

## Review 4 — Product-family consistency
Reviewer lens: product design systems.

Changes:
- launcher identity reuses the canonical Arvectum app icon from Proxy Launcher;
- card radii, dark surfaces, mint action color and restrained borders are aligned with the Proxy Launcher visual language;
- no decorative UI was added.

## Review 5 — Light/dark contrast
Reviewer lens: visual QA.

Changes:
- the header uses a Deep Navy brand surface in both themes so the canonical mint wordmark remains legible;
- footer text uses the theme's high-contrast secondary text rather than mint on a light background;
- light mode remains White/Soft Gray based; dark mode remains Deep Navy/Graphite based.

## Review 6 — Mobile ergonomics
Reviewer lens: interaction designer.

Changes:
- custom file-size input opens a decimal numeric keyboard;
- custom pixel input opens an integer numeric keyboard;
- both use Done IME actions;
- passport crop completion copy is changed from ambiguous «Сделать фото» to «Подготовить фото».

## Review 7 — Final design QA / freeze guard
Reviewer lens: senior product designer + QA.

Changes:
- small accent labels and large result values use contrast-safe theme colors;
- mint remains reserved for high-value signals and actions;
- no new feature, setting or workflow was introduced during UI polish;
- feature freeze remains active after this review.

## Final screen grammar

1. Brand header: canonical Arvectum logo + «До размера».
2. Mode row: «По весу» / «По пикселям» / «На паспорт».
3. One main task card.
4. One primary mint action.
5. Secondary action only when needed.
6. Persistent `Arvectum.com` footer.
7. No onboarding, menu, account, backend or extra settings.
