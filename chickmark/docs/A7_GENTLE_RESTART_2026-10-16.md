# A7 / ChickMark P1 — Gentle Restart, 2026-10-16

## Source and Apple approval

The owner reports Apple approval of the latest submitted **ChickMark 1.4.1 (15)**. A fresh authorized read-only App Store Connect API call on 2026-10-16 confirms `READY_FOR_SALE` (App ID `6818711298`); no later build was uploaded. The separate signed A5 `1.4.2 (16)` IPA is NOT in Apple. The present P1 implementation is source-only and does not alter these binaries.

## Scope

- Opt-in local iPhone-only setting in Manage Habits; OFF by default. Choose a quiet period of **3 / 7 / 14 days**.
- Existing habits only: a hint appears only if at least one genuine **fully completed** past occurrence exists, the habit is due today, not already completed/skipped today, and not archived or currently paused.
- The comparison uses calendar/day keys (not seconds), ignores neutral **paused and skipped days**, and excludes unfinished partial quantitative check-ins from completed-history evidence. Today uses the **same resolved HealthKit/manual check-in projection as the visible habit row**: a habit auto-completed from authorized Health samples must not receive a stale restart hint.
- For completion-relative routines, an on-time due day is **not** a lapse. Hints require the configured completion deadline to be overdue for the threshold interval.
- Card contains a link to the existing habit detail, not an automatic check-off. `Maybe tomorrow` silences it for **today only**; next calendar day re-evaluates without changing the recorded history.
- `@AppStorage` keys stay local and are absent from CloudKit/JSON backups. **No new SwiftData model, migration, HealthKit request, check-in or day mutation.**
- RU/EN/ES strings and accessibility labels. Respect the existing non-shaming language.

## Verification

- [x] **Xcode 27 iOS simulator build PASS**, without production signing or changing any user's iPhone.
- [x] **6/6 targeted XCTest PASS:** due/not yet due, gentle threshold, nonexistent history, archive/pause, current completion, skipped/paused neutral, rolling interval on due day and after overdue, partial multi-check, New York DST/calendar day.
- [x] **222/222 complete ChickMark iOS unit tests PASS;** localization RU/EN/ES audit PASS. **1/1 new Gentle Restart settings UI PASS** on isolated fresh iPhone17e/iOS27 simulator: enable/disable and threshold. First test launch on a busy reused iPhone18Pro could not initialize XCTest AX, subsequent first run on fresh simulator found an XCTest-centred switch tap issue (test only), corrected by tapping actual trailing control. Old UI smoke/Watch generic CI gates still to be checked independently.
- [x] [PR #77](https://github.com/arvectum2/arvectum-tools/pull/77) merged as `fcc05e6` after two independent fully **SUCCESS** GitHub Habits CI runs: [38856169226](https://github.com/arvectum2/arvectum-tools/actions/runs/38856169226), [38856175245](https://github.com/arvectum2/arvectum-tools/actions/runs/38856175245). Both included unit tests, Essential UI smoke and archive; architecture/catalog/mirror green. Local watchOS generic simulator build PASS. GitHub/GitVerse main SHA both `fcc05e6` verified.
- [ ] **Physical acceptance issue [#78](https://github.com/arvectum2/arvectum-tools/issues/78):** optional enable/turn-off UI and regression with **disposable** habit before any later App Store build. Do not modify existing iCloud, HealthKit or user history.

## Scope boundary

`afterCompletion` rolling-repeat scheduling **already exists** with tests; A7 should not reimplement it. Weekly summary is P2. HealthKit water export is a **separate opt-in write** feature requiring per-habit volume/unit mapping, write permissions, stable association with an app-owned HK sample, revocation and duplicate/undo/retry QA. It is not enabled or simulated as success in this patch. Where? remains paused.
