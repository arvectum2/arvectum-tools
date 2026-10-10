# ChickMark 1.3 — implementation notes (not released)

## Done in isolated branch

- Multi-check daily N/N (up to 5 individual slots) and count/duration goals with fixed-size steps
- Streak/reminder/history completion thresholds use full target instead of first partial tick
- Stable deterministic per-slot IDs and existing last-write-wins mutation ledger
- Watch + widget see N/N and preserve whole-goal check/undo commands
- On-device JSON export/import with explicit merge/replace decision
- 7-/30-day calendar consistency for fixed weekday schedules
- RU/EN strings kept up-to-date; Spanish localization added for app/Watch/widget/Shortcuts, with es-ES and es-MX ASO drafts (no App Store submission)
- New unit, backup, N/N and UI regression tests

## Known limits and release gates

- CloudKit habit model schema stays at V1 and interval/week recurrence mode shares a storage integer with incremental mode; explicitly migrate to typed model only after a tested upgrade path
- Count goals are integer steps (1–100) and duration goals are 5-minute increments (5–120 minutes)
- Goal type and N are locked once a habit has check-in history to avoid retroactively changing streaks
- Watch and widget whole-goal actions set N/N or 0/N; independent partial step input is iPhone-only
- Need paired physical Watch validation, 1.2 data upgrade smoke, visual accessibility audit, and full release-hygiene run
- Local-only named habit groups are implemented and participate in JSON backup; multi-device iCloud group synchronization needs a separate migration
- Need advanced weekly/interval trends, optional custom measurement units and careful ad-retention measurement
- JSON backups are plaintext: use secure storage and treat Replace as destructive / possibly CloudKit-propagated
- Typed HabitGoalMode domain adapter replaces scattered integer mode decisions without changing published storage; TodayComponents extraction reduces TodayView from 1016 to about 630 lines
- No App Store upload, no TestFlight submission, no branch merge to published baseline

## Next order

1. Finalize accessibility and behavior of optional local groups, and any evidence-backed feature gaps.
2. Complete regional localization beyond Spanish, screenshot packages, and native translation review.
3. Complete domain/persistence/sync/UI modular refactor with characterization tests and explicit migration plan.
4. Paired Watch/iPhone tests, actual CloudKit upgrade QA, and explicit separate approval before publication.
