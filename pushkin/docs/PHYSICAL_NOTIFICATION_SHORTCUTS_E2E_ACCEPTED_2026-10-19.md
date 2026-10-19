# Pushkin — physical native Notification → Shortcuts → AppIntent → SwiftData E2E

**PASS, 19 October 2026, physical iPhone 13, iOS 27.0.1, Xcode 27.1.**

## Exact acceptance

- Tests ran exclusively in a disposable QA bundle: ru.arvectum.tools.notify.physicalqa, Debug build 7. The installed App Store Pushkin and its personal history were untouched.
- A temporary iOS 27 native Shortcuts trigger "When I receive a notification from PUSHKIN QA" was configured to call the explicitly QA-named PushkinQAOnlyNotificationIntent action. That action calls the actual CaptureNotificationIntent.perform() and production SwiftData persistence actor, while using only the QA app data container. Physical UI evidence shows the source app and action.
- An ambiguous "Archive Notification" action was removed from the temporary Shortcut BEFORE the end-to-end run; its removal and retention of the named QA-only action passed physical XCTest.
- Before sending, baseline QA SwiftData audit: markerCount=0 and totalCount=7.
- NotificationSenderQAProbe scheduled ONE real local UNUserNotificationRequest with title PUSHKIN-QA-E2E-20261019, 45-second delay. It returned status=SCHEDULED.
- The test runner switched to native Shortcuts and waited for delivery. It did NOT invoke capture AppIntent manually.
- After delivery, independent QA SwiftData audit: markerCount=1 and totalCount=8. One new persisted record UUID: 9967A347-CD7E-4D0B-99B8-8EC324F97491.
- A final independent audit AFTER cleanup still returned markerCount=1, totalCount=8 and the same UUID: no extra duplicate records.

## Mandatory cleanup — fully passed

- Both ephemeral QA Shortcuts, "Новая команда 4" (real Notification trigger with one QA action) and "PUSHKIN QA E2E 20261019" (extra empty test Shortcut), were deleted via native iOS Shortcuts, each with iCloud deletion confirmation.
- Scoped physical XCUITest: FinalQAOwnShortcutsCleanupRetry.xcresult, 2 tests, 0 failures, TEST SUCCEEDED. Both tests verified all other visible Shortcuts were retained.
- Native Shortcuts CLI on BOTH Mac mini and MacBook Air shows ZERO instances of either temporary test name after iCloud sync.
- Separate read-only physical XCUITest: FinalFiveOriginalAutomations.xcresult, QA_AUTOMATION_POST_CLEANUP_CELL_COUNT=5, PASS. Exactly the five baseline automations remained.
- Canceled any still pending QA notification by its own unique request identifier. Report: status=PENDING-QA-ONLY-CLEARED.
- Personal automations were not enabled or edited. Production Pushkin, personal notes, notifications and CloudKit data were not changed.

## Limits and release gate

This proves true notification-trigger delivery into production capture/persistence CODE on an isolated signed QA iPhone app. It does NOT verify an in-place signed upgrade of the real App Store installation with the user's personal history. Such a production migration is an independent test gate and should never be destructive.

Public Pushkin remains 1.0. App Store Connect review of Pushkin 1.0.1(4) was withdrawn. No new IPA upload, TestFlight/App Review submission or publication is authorized until the owner gives explicit approval for the exact version/build. Once approved for submission, use automatic release AFTER_APPROVAL, never manual unless the owner changes this preference.

## Evidence on ArvectumSSD (QA-only)

Folder: /Volumes/ArvectumSSD/Arvectum/tmp/pushkin-real-e2e-20261019

- pre-send-audit.json, scheduled-single.json, post-single-notification.json, final-audit-after-cleanup.json
- send-and-audit.command, pending-qa-cancel-result.json
- RemoveAmbiguousQAAction2.xcresult, FinalQAOwnShortcutsCleanupRetry.xcresult, FinalFiveOriginalAutomations.xcresult
- final-cleanup-retry.log, final-inventory.log, build-qa7.log

QA-only Swift test sources remain outside the production target. Screenshots of the Shortcuts library are not published to Git.
