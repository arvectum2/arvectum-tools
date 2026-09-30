# Arvectum Tools — Shared Brand Rules

This document defines the common visual language for the consumer utility family. Product-specific roadmaps may add local rules but should not silently redefine the master brand.

## Core palette

- Mint Primary: `#43E5C5`
- Mint Light: `#7AF1DD`
- Deep Navy: `#041A33`
- Graphite: `#243446`
- Soft Gray: `#F3F5F7`
- White: `#FFFFFF`

Mint is primarily an action/signal color. Deep Navy and Graphite provide structure. Light/Dark mode should follow the system.

## Visual character

Precise, calm, compact and functional. The interface should look like a dependable utility, not a generic “AI app” or an overloaded control panel.

## Brand hierarchy

1. Product name and current task.
2. User action/result.
3. Arvectum attribution.
4. Arvectum Tools family identity at store/about/website level.

The Arvectum corporate mark is the source of truth. Do not create competing product-level corporate logos.

## App icon family

Icons should share a recognizable container/visual language, use no text, remain legible at small sizes and differ primarily through the product action symbol.

## Interaction defaults

- one primary action per state;
- large touch targets;
- minimal decoration;
- rounded task surfaces;
- clear result states;
- no fake progress animation;
- system accessibility and Dynamic Type;
- no visual element may make advertising look like a product control.

## Source-code rule

Brand tokens may live inside an app until they are reused. Once two apps use the same stable token/component API, promote it to a shared package under `packages/`.
