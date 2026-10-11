# Shared packages

This directory is the promotion target for code that has become genuinely common across Arvectum Tools apps.

## Extraction rule

A shared package should normally be created only when:

1. at least two real apps need the same behavior;
2. the behavior is stable enough to name;
3. sharing reduces maintenance more than it increases coupling;
4. the package can remain independent of one app's product model.

Small duplication is preferred over a premature abstraction.

## Expected candidates

- `ArvectumDesign` — visual tokens and reusable UI primitives.
- `ArvectumAds` — ad loading/placement policy primitives.
- `ArvectumAnalytics` — common privacy-safe analytics events.
- `ArvectumStore` — release/store helpers.
- `ArvectumPrivacy` — reusable privacy/about UI.

These are candidates, not pre-approved frameworks.

[ArvectumPersistence](ArvectumPersistence/README.md) — shared wire-compatible JSON codec for ChickMark and What?.

[ArvectumDiagnostics](ArvectumDiagnostics/README.md) — private-by-default local OSLog failures.

**Core test gate:** run `cd core && swift test`. The [Core CI](../../.github/workflows/core-ci.yml) builds all four iOS apps when shared sources change.

The Core CI matrix also exercises ChickMark/What? persistence behavior tests, builds both watchOS app schemes, and runs Android tests, lint, and APK generation. Physical-device WatchConnectivity and CloudKit remain release acceptance checks.
