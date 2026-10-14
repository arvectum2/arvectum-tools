# PUSHKIN — Product Roadmap

## Active checkpoint — 2026-10-14
**Last verified state:** iOS 1.0 WAITING_FOR_REVIEW in App Store Connect on 2026-10-11. No newer decision or public publication independently confirmed.
- [x] Submitted local-only notification history with Shortcuts/App Intents capture, searchable offline storage and fallback onboarding.
- [ ] Verify App Review outcome and live storefront/build version.
- [ ] Reproduce, fix and regression-test the deletion crash reported 2026-10-04; preserve existing local history.
- [ ] Physically validate offline capture and automation enablement/refresh, including Shortcuts' 25-app grouping constraint.
- [ ] Prioritize simpler guided setup and Russian in-app language after stability; snooze, Save/Done, digests and rules are later.
- [ ] Revisit monetization only with strict exclusion of notification data from advertising and analytics.


**Updated:** 2026-10-14
**Ownership:** capture/onboarding, notification store, privacy, search and product UX.
**Status:** iOS 1.0 **Waiting for Review**, verified in authenticated App Store Connect on 2026-10-11. Submission history is preserved in the release documentation; no publication confirmed.
**Full historic phases and decision evidence:** [docs/history/ROADMAP-legacy-2026-10-11.md](docs/history/ROADMAP-legacy-2026-10-11.md). Do not treat old unchecked phases as 1.0 blockers.
**Common rules:** [Core](../core/CORE_PRINCIPLES.md). **Growth:** [Growth](../growth/ROADMAP.md).

## 1.0 baseline (recorded in code planning)
- [x] Physical iPhone capture via Shortcuts/App Intents, bundled TOP-1000 catalog and local one-app micro-packages.
- [x] Manual fallback and automatic capture verification.
- [x] Local-only storage and chronological notification history.
- [x] Full-text search, copy/share/delete, clear history.
- [x] English app UI and RU/EN store metadata prepared.
- [x] Signed 1.0.0 (1) archive and App Store submission recorded.
- [x] Check App Store Connect on 2026-10-11: iOS 1.0 is **Waiting for Review**.
- [ ] Confirm future review outcome and publication; do not treat submission as publication.
- [ ] Complete/manual-record physical offline smoke testing and final visual QA.

## Immediate post-submission
- [ ] Productize app-refresh onboarding with system Add + automation-enable guidance and verified coverage.
- [ ] Investigate/delete-related crash reported 2026-10-04 and verify fix.
- [ ] Russian in-app localization (deferred from 1.0).
- [ ] Decide ad SDK integration for first post-launch update after verifying policy and UX.

## Later, subject to feedback
- [ ] Save/Done, useful filters and configurable retention.
- [ ] Snooze/remind-later and important inbox.
- [ ] Digests, app grouping and simple rules.
- [ ] Face ID protection and accessibility improvements.

## Product-specific constraints
- Notification data never becomes analytics/advertising content.
- No account, backend, cloud or live catalog lookup required for core capture.
- Prioritize reducing Shortcuts setup and coverage-refresh steps.
