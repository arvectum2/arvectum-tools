# Pushkin 1.0.1 (5) — local release candidate, owner approval required

**Status: Built and QA-accepted, NOT uploaded or submitted to Apple.**

## Candidate identity

- Production bundle: ru.arvectum.tools.notify. Marketing version 1.0.1, build 5, minimum iOS 27.0. Apple team VML75VY94V.
- Production Xcode 27.1 Release archive: successfully built and code-signed. App Store export: successfully exported LOCAL ONLY with Apple Distribution: LLC ARVECTUM.
- Private IPA: /Volumes/ArvectumSSD/Arvectum/tmp/pushkin-final-acceptance-20261019/AppStoreExportLocalOnly/ArvectumNotify.ipa
- IPA SHA-256: 1568948e6f7d4efdc904e0354b5311828ce160e18cbd164717853e389e5c544c
- Archive: /Volumes/ArvectumSSD/Arvectum/tmp/pushkin-final-acceptance-20261019/Pushkin-1.0.1-build5.xcarchive
- Local signed exported IPA was independently extracted and its signing identity, bundle ID, build version, and Swift executable confirmed. QA-only action names are absent in production executable.

## Signed physical in-place upgrade — PASS

- Test ONLY on iPhone 13 (iOS 27.0.1) in separate app ru.arvectum.tools.notify.physicalqa, without uninstalling it or changing personal data.
- Signed QA build 7 was updated in place to QA build 8. Its same SwiftData persistence source was used.
- Before update: backup of all three SQLite DB/WAL/SHM files onto ArvectumSSD; SQLite quick_check OK; 8 synthetic records.
- After update: ModelContainer loaded; QA sentinel still present, app build 8 reported, all eight rows preserved with unchanged primary keys and all stored fields.
- Canonical row-value SHA-256 before/after matched: c6ac62dbf138d83790ca09521dc7c2602da08b8fe26ee3ada1fa5a000bf691d4. Post-update SQLite quick_check OK. No personal data included.

## Native Shortcuts E2E and cleanup — PASS

- Verified on the actual iPhone: one real local notification from QA app → native Notification-trigger iOS Shortcuts → QA-only AppIntent → production Pushkin CaptureNotificationIntent persistence → SwiftData. Marker count 0→1, total records 7→8, no duplicates.
- Both temporary QA Shortcuts deleted via native iPhone + iCloud confirmation, both absent on Mac mini and MacBook Air. Exactly the five pre-existing automations remain (read-only physical XCTest PASS).
- The QA notification pending request was cancelled. See [physical E2E protocol](PHYSICAL_NOTIFICATION_SHORTCUTS_E2E_ACCEPTED_2026-10-19.md).

## Regression suites

- A new isolated iOS 27 simulator was created. The designated project CI selection (all ArvectumNotifyTests, PushkinA6OnboardingUITests, NotificationDeletionUITests) finished TEST SUCCEEDED, exit 0, no failed tests.
- A separate exploratory run of ALL old UI test classes was stopped after fixture-dependent manual Shortcuts/import tests failed because they assume preconfigured screens/imported shortcuts. Do NOT describe that exploratory run as green. Its failures belong to test-harness maintenance and do not constitute a proven regression of the production app. All logs are retained.

## Explicit limitations and blocked Apple gate

- The connected physical iPhone does NOT have the production App Store bundle ru.arvectum.tools.notify installed (verified read-only). Therefore no in-place production-store upgrade of a person's real notification history can be conducted on this device. The isolated signed QA upgrade is strong corroboration but not a substitute. This requirement is NOT marked done.
- Do not install over a personal App Store app, wipe personal data, or alter unrelated Shortcuts without distinct approval.
- Public Pushkin remains 1.0. The earlier 1.0.1(4) was withdrawn (DEVELOPER_REJECTED). NO App Store Connect upload, review, TestFlight, live listing change or submission was performed.
- Only after owner EXPLICITLY approves **Pushkin 1.0.1 (5)** may a release upload/submission occur, and release type must be AFTER_APPROVAL (automatic public availability after Apple approval, never manual unless expressly changed).
- Local IPA and QA database remain on ArvectumSSD; do not commit QA payloads.

## Evidence

/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-final-acceptance-20261019 contains:
- qa8-exact-row-equality-PASS.json, before-qa8, after-qa8, after-qa8-model-report.json, build-qa8-retry.log
- production-archive.log, export-local-ipa.log, AppStoreExportLocalOnly/ArvectumNotify.ipa
- targeted-ci.log and RC5TargetedCITests.xcresult
- simulator-regression.log (incomplete exploratory all-UI test suite; known non-hermetic failures)


## Final source integration verification, 19 October 2026

- PR #131 was merged into GitHub main as commit 32dc3d1 (release/build-number/configuration/docs ONLY).
- Mac mini ArvectumSSD main was fast-forwarded to this exact commit; clean worktree verified.
- GitHub Actions checks remained QUEUED at the last check, not passed, failed, or completed. Local designated Xcode simulator CI suite and architecture/dependency checks passed; do NOT conflate remote queue status with green remote CI.
- Read-only Apple public iTunes lookup for app ID 6817847111, RU storefront, still reported public version 1.0.
- The externally signed IPA is local on ArvectumSSD. No upload or App Review submission occurred. Automatic after-approval release is a preference to use upon a future explicitly approved submission, not a publication already scheduled.
