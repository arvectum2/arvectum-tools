# ChickMark — Product Roadmap

**Updated:** 2026-10-11
**Status:** v1.3.0 (build 5) **published — owner-confirmed 2026-10-11**. Installed on paired physical iPhone 13 and Apple Watch SE, verified via CoreDevice app inventory 2026-10-11. Independent public App Store availability/rollout not re-verified in this audit.
**Authoritative feature evidence:** historical [ChickMark branch snapshot](docs/history/ROADMAP-chickmark-branch-2026-10-11.md) formerly from `feature/chickmark-multicheck`, now integrated into `main`; [earlier planning archive](docs/history/ROADMAP-legacy-2026-10-11.md).
**Shared rules:** [Core](../core/CORE_PRINCIPLES.md). **Promotion and ASO metrics:** [Growth](../growth/ROADMAP.md).

## Published baseline: 1.2
- [x] Local-first SwiftData habit tracking, daily check-off, scheduling and progress.
- [x] Apple Watch and widget integration; app-specific release checks.
- [x] One-off reminders with isolated local persistence.
- [x] First unobtrusive Today ad; keep published schema and 1.2 rollback compatibility.

## 1.3: published (owner-confirmed); physical acceptance remains ongoing
- [x] Multiple check-offs, incremental goals and extended statistics (implementation recorded in branch).
- [x] RU/EN/ES localized UI and localized store assets prepared.
- [x] Signed 1.3.0 (5) candidate and device installation recorded.
- [x] App Review submission recorded 2026-10-11.
- [x] Owner confirmed public release of 1.3.0 (5) on 2026-10-11; physical iPhone and Watch installed versions also match.
- [ ] Independently confirm store rollout in each intended region when relevant.
- [ ] Complete physical-device CloudKit/data-preservation, Watch offline reconciliation and ad/privacy QA evidence. No destructive migration or overwrite of published app.
- [ ] Verify branch documentation and final release notes against the exact uploaded binary.

## Product backlog
- [ ] Sliding recurrence: next due date N days after **actual completion**, not a fixed calendar interval (verify implementation before marking done).
- [ ] Define timezone, late completion, overlapping and partial completion semantics with regression tests.
- [ ] Evaluate extra monetization placements only after retention evidence; do not add a second native Progress ad by default.

## Product-specific ad guardrails
Core features stay free. No interruptions during creation, check-off, widgets or reminders.
Delayed initial advertising and its thresholds are **ChickMark-specific**, not portfolio policy.

No app-specific tasks are duplicated in Core or Growth.
