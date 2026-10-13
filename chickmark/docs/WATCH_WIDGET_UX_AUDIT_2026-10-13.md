# ChickMark — Watch & widget UX audit, 2026-10-13

Status: **device builds, installations and main-screen/gallery audits verified after RDC reconnection**. Full Lock Screen placement and live physical WatchConnectivity/HealthKit sign-off still need on-device validation.

## Reviewed scope
- watchOS: Today row, progress, 0/N track, multi-check controls, day rollover, HealthKit auto-state, VoiceOver targets and values.
- iOS widgets: small and medium Home Screen; circular, rectangular, inline Lock Screen; empty/complete and multi-habit cases; action labels and timeline/day change.
- watchOS complications: circular, rectangular, inline data code review.
- Existing simulator Watch SE 3 (40 mm) screenshot (earlier commit a9014d5) showed 0/1 track and non-duplicated 3/5; new changes below still require refreshed screenshots.

## Findings fixed in branch
- Watch step +/- zones: 38pt to 44pt minimum.
- Watch partial progress: 3/5 no longer hidden from VoiceOver; localized RU/EN/ES.
- Watch summary progress was derived only from the transmitted list, which may be shorter than totalCount: now counts the authoritative snapshot completed/skipped totals plus new device-local HealthKit completions, capped at totalCount.
- Watch can stay active across midnight: now requests refreshed snapshots shortly after midnight without minute-by-minute WatchConnectivity polling.
- iPhone medium widget can clip with three 40pt rows plus title, overflow and accessible text sizes: now shows max two rows normally and one at accessibility text sizes; correct remainder count.
- iPhone widget action hit target: 40pt to 44pt.
- All widget actions previously announced indistinguishable "Mark complete" / "Undo completion": now announce the habit name with localized RU/EN/ES formats.
- Empty small widget no longer centers a misleading 0/0 donut; shows a neutral checkmark/empty description.
- Progress donuts clamp shrinkable center text.

## Previous baseline checks
- Earlier build of Watch app and complication extension successful on watchOS simulator (commit a9014d5).
- Earlier iPhone widget extension build successful and 155 unit tests green (commit a9014d5).
- Prior Watch SE screenshot inspected; new build not yet verified.

## Device and UX sign-off
- [x] Pulled the latest remote ChickMark branch into clean Mac mini worktree.
- [x] Signed iPhone app and physical Apple Watch app builds, iPhone widget and watchOS complication builds; RU/EN/ES localization audit and 155/155 unit tests.
- [ ] Re-run Watch SE 40mm + Series 12 (46mm) screenshots in RU/EN/ES, light/dark where supported and enlarged text.
- [ ] On simulator Home Screen place ChickMark small and medium widgets, photograph empty / partial / complete / long name / XXL text.
- [ ] On Lock Screen place inline, rectangular and circular widgets; validate truncation and data.
- [ ] Verify interactive widget check/uncheck and counter refresh on iPhone (including offline/back-online and date rollover).
- [ ] On physical watch pair test device-initiated completion and ACK/resync, and watchOS HealthKit authorization.
- [x] Installed signed iPhone 13 app and Apple Watch SE app on both physical devices; watch app launched successfully through CoreDevice.

- [x] On Apple Watch SE 3 (40mm) simulator visually inspected RU and EN full watch screen (0 of 1 track empty, Water/Vода 3/5 only once).
- [x] Opened real SpringBoard widget gallery on iPhone 13 simulator, searched for ChickMark, added Small and Medium widgets; confirmed sizes and visible empty states on the rendered Home Screen and gallery.
- [x] Corrected real UI truncation: small empty label now uses concise RU/EN/ES variants instead of clipped “Nothing scheduled t...”.
- [x] Corrected misleading 0/0 values on empty medium, circular and inline iPhone widgets, and watchOS complications.
- [x] Tested widget model date rollover/optimistic commands and Watch state via 155 unit tests; non-persistent test runner deliberately has no real shared App Group access, so this does not prove filled-data widget rendering.

## Safety
No data migrations or destructive changes. Never mark this audit as physically complete without screenshots and the above checks.
