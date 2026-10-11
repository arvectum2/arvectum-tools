# ChickMark — Product Roadmap

**Updated:** 2026-10-11
**Status:** v1.2.0 (build 4) published (owner-confirmed 2026-10-10); v1.3.0 (build 5) submitted 2026-10-11, WAITING_FOR_REVIEW, manual release. Publication of 1.3 **not confirmed**.
**Authoritative feature evidence:** active [ChickMark branch snapshot](docs/history/ROADMAP-chickmark-branch-2026-10-11.md) from `feature/chickmark-multicheck`; [earlier planning archive](docs/history/ROADMAP-legacy-2026-10-11.md).
**Shared rules:** [Core](../../docs/CORE_PRINCIPLES.md). **Promotion and ASO metrics:** [Growth](../../docs/GROWTH_ROADMAP.md).

## Published baseline: 1.2
- [x] Local-first SwiftData habit tracking, daily check-off, scheduling and progress.
- [x] Apple Watch and widget integration; app-specific release checks.
- [x] One-off reminders with isolated local persistence.
- [x] First unobtrusive Today ad; keep published schema and 1.2 rollback compatibility.

## 1.3: implemented and submitted, not yet publicly released
- [x] Multiple check-offs, incremental goals and extended statistics (implementation recorded in branch).
- [x] RU/EN/ES localized UI and localized store assets prepared.
- [x] Signed 1.3.0 (5) candidate and device installation recorded.
- [x] App Review submission recorded 2026-10-11.
- [ ] Confirm Apple's review result and separately confirm live rollout/manual release.
- [ ] Record outstanding physical-device/cloud data-preservation and ad/privacy QA evidence and any review fixes.
- [ ] Verify branch documentation and final release notes against the exact uploaded binary.

## Product backlog
- [ ] Sliding recurrence: next due date N days after **actual completion**, not a fixed calendar interval (verify implementation before marking done).
- [ ] Define timezone, late completion, overlapping and partial completion semantics with regression tests.
- [ ] Evaluate extra monetization placements only after retention evidence; do not add a second native Progress ad by default.

## Product-specific ad guardrails
Core features stay free. No interruptions during creation, check-off, widgets or reminders.
Delayed initial advertising and its thresholds are **ChickMark-specific**, not portfolio policy.

No app-specific tasks are duplicated in Core or Growth.
