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
- [ ] Create signed App Store archive from the final frozen source commit.
- [ ] Generate and inspect Xcode Privacy Report from that exact archive in Organizer.
- [ ] Update App Store Privacy answers only after reconciling the report with the actual Yandex runtime configuration.
- [x] Verify no ATT prompt / tracking implementation is present in ChickMark 1.1 source/configuration.
- [x] Verify Privacy Policy URL is https://arvectum.com/privacy.
- [ ] Export Apple Distribution IPA and record its SHA-256.
- [ ] Upload build to App Store Connect.

## Metadata
- [x] RU/EN descriptions include one-time reminders and completion-relative intervals.
- [x] RU/EN What's New prepared.
- [x] Review notes for 1.1 prepared.
- [x] Privacy notes for 1.1 prepared.
- [x] Refresh Today screenshot in RU/EN because 1.1 visibly adds Reminders; Progress/Manage/Watch screenshots remain unchanged.
- [ ] Update App Review video only if useful for the new one-time reminder flow.

## Submission
- [ ] Attach processed build to version 1.1.
- [ ] Confirm age rating/content rights/export compliance remain applicable.
- [ ] Submit for review only after explicit approval to do so.
