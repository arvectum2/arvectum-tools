# ChickMark 1.1.0 (Build 3) — Release checklist

## Scope frozen
- [x] One-time reminders on iPhone.
- [x] Completion-relative habits: next due date is N days after the actual completion day, without changing the published Habit/CloudKit field schema.
- [x] One-time reminders do not affect habit streaks/statistics.
- [x] One-time notification Done action.
- [x] Edit/delete one-time reminders.
- [x] Existing habit CloudKit schema remains unchanged; one-time reminders are local-only.
- [x] Sticky Yandex banner on Today only.
- [x] No App Open / interstitial / Progress native ad in 1.1.
- [x] Canonical Privacy Policy URL: https://arvectum.com/privacy.

## Before archive
- [x] Full unit-test suite green: 109 tests, 0 failures.
- [x] Simulator regression / core UI smoke green: 12 UI tests, 1 expected iOS-27-only skip on iOS 26.5, 0 failures.
- [x] Release build embeds iPhone app, Watch app and widgets with 1.1.0 / build 3.
- [x] V1 published-store upgrade smoke test green.
- [x] RU/EN localization completeness green.
- [x] Final Today UI reviewed with reminder and fixed-bottom ad; App Store screenshot intentionally uses the clean no-ad state.

## Exact App Store archive
- [x] Signed App Store archive created from frozen source commit `594d8c10a2e4815bfd50f784cafcc77b711d61dc`.
- [x] Archive path: `/Users/master/ChickMarkRelease/1.1.0-build3-final-594d8c1/ChickMark.xcarchive`.
- [x] Exact exported IPA inspected: iPhone / Watch / widget are all 1.1.0 (3), App Intents are embedded, push + CloudKit use Production entitlements, App Group is present.
- [x] Production banner ID verified in exported bundle: `R-M-20183085-1`; 228 SKAdNetwork identifiers are present.
- [x] Verify no ATT prompt / tracking implementation is present in ChickMark 1.1 source/configuration; `NSUserTrackingUsageDescription` is absent from the exported app.
- [x] Exact embedded privacy-manifest audit saved beside the release artifact as `PRIVACY_MANIFEST_SUMMARY.json`.
- [x] App Store Privacy reconciled against the exact artifact, Apple collection definition, Yandex's documented default iOS collection behavior, and ChickMark runtime settings.
- [x] Privacy decision for 1.1: keep `Data Not Collected`; Tracking = No. No App Store Privacy data-type change is required for this release.
- [x] Organizer “Generate Privacy Report” is optional final visual verification, not a submission blocker; there is no supported CLI and the exact bundled manifests were audited directly.
- [x] Verify Privacy Policy URL is https://arvectum.com/privacy.
- [x] Apple Distribution IPA exported: `/Users/master/ChickMarkRelease/1.1.0-build3-final-594d8c1/export/HabitsByArvectum.ipa`.
- [x] IPA SHA-256: `726c9599c982e387e76c0a1ab4b0e5d39cd55ca727056aa5c3b911017037d345`.
- [x] Upload build to App Store Connect.
- [x] Apple delivery UUID: `29ca941d-5639-4f7a-80d9-580887ddfcfc`.
- [x] App Store Connect processing completed: `VALID`, `APP_STORE_ELIGIBLE`, build 3 is present in App Store Connect.

## Metadata
- [x] RU/EN descriptions include one-time reminders and completion-relative intervals.
- [x] RU/EN What's New prepared.
- [x] Review notes for 1.1 prepared.
- [x] Privacy notes for 1.1 prepared.
- [x] Refresh Today screenshot in RU/EN because 1.1 visibly adds Reminders; Progress/Manage/Watch screenshots remain unchanged.
- [ ] Update App Review video only if useful for the new one-time reminder flow.

## Submission
- [x] Attach processed build 3 to version 1.1.
- [x] Confirm age rating/content rights/export compliance remain applicable; content rights updated for third-party advertising content.
- [x] Submit for review after explicit approval.
- [x] Review Submission ID: `4a52b1b2-8b5d-481e-9011-b03622fde019`.
- [x] Final App Store Connect state: `WAITING_FOR_REVIEW`.
