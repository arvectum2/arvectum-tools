# ChickMark 1.3 — pre-release checklist (UNRELEASED)

**Release decision:** HOLD. No TestFlight, App Store Connect submission or external deployment without explicit approval.

## Functionality
- [x] N/N multi-check, count and duration goals, historical progress editor
- [x] 7/30-day fixed, 4/12-week flexible, 30/90-day completion-interval insights
- [x] Groups with local-first iCloud Key-Value Store transport (needs final cross-device proof)
- [x] JSON export/import with merge/replace and original reminders
- [x] Watch desired-count protocol, optimistic/offline reconciliation and interactive step controls
- [ ] Complete physical Watch/iPhone device smoke and CloudKit + KVS convergence at the **very end**
- [ ] Verify partial state and conflict merge across real iPhone + a simulator signed to the same iCloud account

## Localization/ASO
- [x] RU/EN/ES app, Watch, widgets and Shortcuts with key parity checks
- [x] Draft regional Store text: ru-RU, en-US, es-ES and es-MX
- [ ] Editorial/native review of Spanish and regional marketing copy
- [x] Captured 9 raw iPhone simulator screenshots in EN/RU/ES (1206×2622) from 1.3 synthetic app data
- [x] Captured raw Apple Watch SE 3 40mm screenshots, EN/RU/ES, 324×394
- [ ] Review raw screenshots, prepare exact App Store sizes and final Watch screenshot family; no upload
- [ ] Additional locales only when justified by organic-demand data

## Architecture and quality
- [x] Typed HabitGoalMode adapter; UI component extraction; group sync ledger isolated from SwiftData schema
- [x] Published SwiftData schema and Apple entitlement identifiers remain unchanged
- [ ] Full CI regression and TestFlight-equivalent signed-device smoke (no actual TestFlight submission)
- [ ] Verify release archive embeds all four signed targets and privacy manifests
- [ ] Recheck App Store Privacy against final exported IPA, not simulator builds
- [ ] Validate ad fill, retention and thresholds on actual production; do not increase exposure absent evidence
- [x] Public App Store page (id6818711298) links Arvectum Developer Website and Privacy Policy; official site and app-ads.txt respond HTTP 200

## Last step: one physical iPhone + iOS simulator
- [ ] iPhone existing 1.2 data backed up through user-managed encrypted iPhone backup (Xcode cannot read the App Store container)
- [ ] No destructive production-app replacement before backup, approval and rollback plan
- [ ] Verify incremental upgrades, cloud-owned habit convergence and conflict retries
- [ ] Verify group changes propagate through iCloud KVS; simulator must share same Apple Account and have iCloud capability available
- [ ] Verify backup export/import, paused and skipped day reconciliation, reconnect, duplicate commands
- [ ] Log device OS, build number and test evidence; revisit if simulator CloudKit services differ from a real second device
- [ ] Owner explicitly approves release. Until then, HOLD.
