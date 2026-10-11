# ChickMark 1.3 — final physical iPhone + simulator acceptance

Status: **1.3.0 (5) already installed in place on the physical iPhone; hosted CI green.** Full phone/Watch/iCloud convergence is still pending. A complete device backup is optional for non-destructive in-place updates, not a prerequisite.
This is QA only; do not update the App Store listing, publish to TestFlight, merge main or uninstall 1.2.

## Tested environment

- Physical: iPhone 13, iOS 27.0.1, ChickMark 1.2.0 present from App Store; paired Apple Watch SE, authorized via wired connection to Mac mini.
- Simulator: iPhone 18 Pro/iOS 27 paired with Apple Watch SE 3/watchOS 27.
- Candidate: local Apple Distribution **Ad Hoc** 1.3.0 (5), same bundle ID and Team as released app, production APNs and production CloudKit entitlement.
- Local protected QA artifact (not in Git): /Volumes/ArvectumSSD/Arvectum/artifacts/chickmark/1.3.0-qa/ChickMark-1.3.0-build5-release-testing.ipa
- SHA-256: d04812bc8a0f1b13eb666fd3c92eb58bd63373a4c7a852b6c49979bd1a3f9f80
- All four targets (iOS app, iOS widget, Watch app, Watch widget) were checked for version 1.3.0 (5), embedded eligible provisioning profiles and privacy manifests, with strict code-signing verification.
- This is a non-published acceptance build. Distribution signing is necessary but does not by itself prove production CloudKit convergence.

## Non-negotiable safety gates

- [ ] Fresh iCloud or encrypted Finder device backup *completed today*, confirmed after the baseline 1.2 installation. Backup as of 2026-10-08 is not fresh enough.
- [ ] Visually record **non-sensitive counts/state only** in the installed 1.2 app: habit count, group names if any, several completions/goal types, oldest history example. No data copied into public repositories or CI.
- [ ] Confirm user has access to the same Apple Account for iCloud on simulator; if simulator cannot sign in, record cross-device CloudKit test as **blocked**, not passed.
- [ ] Check new QA IPA SHA before in-place installation.
- [ ] Never delete/uninstall ChickMark on the physical device to install a test build. Never run destructive wipe/restore, change the user iCloud account or reset CloudKit production data.
- [ ] Explicitly verify current phone's last successful backup time before installing.

## In-place upgrade: 1.2 -> 1.3

- [ ] Install 1.3 signed Ad Hoc IPA **over** the existing 1.2. Confirm same bundle ID/team and no data-clear prompts.
- [ ] Open app online, then offline. Compare existing habit count, goals, dates, historical check-ins, pause/skip state and ordering with baseline.
- [ ] Verify the existing SwiftData/CloudKit database was reused, not recreated, and the app does not crash.
- [ ] Check old binary completion commands still decode with the optional desiredCount property; avoid duplicate check-offs.
- [ ] Export full 1.3 JSON backup into a user-controlled private location; verify it covers all data types. Import/merge only into an isolated test dataset, never replace production records for a smoke test.
- [ ] Check Today's N/N increments/decrements, history editing, streaks and habit goal mode counts. Repeat with app cold launch.
- [ ] Exercise rollback *plan* only, not an actual destructive restore.

## Physical Apple Watch, notification and shortcut tests

- [ ] Check 1.3 Watch app availability and installation; do not unpair the actual Watch.
- [ ] Phone online: record partial check-ins from Watch and confirm one authoritative copy on phone.
- [ ] Disconnect Watch temporarily, record 2 distinct partial commands offline, reconnect and verify queued commands applied once and only once.
- [ ] Confirm old Watch commands lacking desiredCount remain decode-compatible.
- [ ] Test reminders, system permissions, widget and shortcut actions without overwriting existing real habits.

## iPhone + simulator convergence

- [ ] Simulator signed into the same intended Apple Account and iCloud availability confirmed.
- [ ] Use only new clearly labelled temporary QA habits/groups; no destructive conflict test against existing personal habits.
- [ ] Confirm phone -> sim and sim -> phone CloudKit check-ins, day edits, group membership, LWW tombstones and delete handling.
- [ ] Repeat after app restart and with transient offline/online on one side; check conflict idempotency and preserved user habits.
- [ ] Delete *only* QA-created entities and verify both devices converge. Do not claim pass from fixture-only simulator tests.

## Advertising and privacy

- [ ] Confirm existing Today banner obeys 3-day/5-cold-launch/3-successful-check-off gate; no new placement in 1.3.
- [ ] Confirm lazy Yandex SDK startup does not load on newly ineligible account. Verify observed network behavior of enabled banner on device.
- [ ] Compare final embedded Yandex/AppMetrica privacy manifests against App Store Privacy disclosures; do not infer actual tracking from manifest capability alone.
- [ ] Check App Store signed production entitlements and watch provisioning remain valid on installed app.
- [ ] Decide release privacy disclosures explicitly; no silent privacy-label changes.

## Release gate

- [x] Full local iOS 27 UI suite: 19/19 passed, 0 failed, 0 skipped (verified using xcresulttool, iPhone 18 Pro iOS 27.0).
- [x] watchOS 27 simulator smoke: paired Apple Watch SE 3 40mm, 1.3 Watch app installed/launched, seeded Water 3/5 +/- controls shown in native screenshot; this is not physical Watch sync evidence.
- [ ] GitHub-hosted Xcode 27 CI must finish successfully.
- [ ] All above physical acceptance evidence recorded with pass/fail/blocker; zero migration/data-loss issues.
- [ ] Only **then** begin separate ASO and SEO phase.
- [ ] Publication requires explicit user approval after ASO/SEO; never automatically upload to TestFlight/App Store.
