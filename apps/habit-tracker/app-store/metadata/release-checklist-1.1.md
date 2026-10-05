# ChickMark 1.1.0 (Build 3) — Release checklist

## Scope frozen
- [x] One-time reminders on iPhone.
- [x] One-time reminders do not affect habit streaks/statistics.
- [x] One-time notification Done action.
- [x] Edit/delete one-time reminders.
- [x] Existing habit CloudKit schema remains unchanged; one-time reminders are local-only.
- [x] Sticky Yandex banner on Today only.
- [x] No App Open / interstitial / Progress native ad in 1.1.
- [x] Canonical Privacy Policy URL: https://arvectum.com/privacy.

## Before archive
- [x] Full unit-test suite green: 103 tests, 0 failures.
- [x] Simulator regression / core UI smoke green: 11 UI tests, 1 expected iOS-27-only skip on iOS 26.5, 0 failures.
- [x] Release build embeds iPhone app, Watch app and widgets with 1.1.0 / build 3.
- [x] V1 published-store upgrade smoke test green.
- [x] RU/EN localization completeness green.
- [x] Final Today UI reviewed with reminder and fixed-bottom ad; App Store screenshot intentionally uses the clean no-ad state.

## Exact App Store archive
- [ ] Create signed App Store archive from the frozen commit.
- [ ] Inspect Xcode Privacy Report from that exact archive.
- [ ] Update App Store Privacy answers for advertising SDK data collection.
- [ ] Verify no ATT prompt / tracking declaration unless implementation changed.
- [ ] Verify Privacy Policy URL is https://arvectum.com/privacy.
- [ ] Export IPA and record SHA-256.
- [ ] Upload build to App Store Connect.

## Metadata
- [x] RU/EN descriptions include one-time reminders.
- [x] RU/EN What's New prepared.
- [x] Review notes for 1.1 prepared.
- [x] Privacy notes for 1.1 prepared.
- [x] Refresh Today screenshot in RU/EN because 1.1 visibly adds Reminders; Progress/Manage/Watch screenshots remain unchanged.
- [ ] Update App Review video only if useful for the new one-time reminder flow.

## Submission
- [ ] Attach processed build to version 1.1.
- [ ] Confirm age rating/content rights/export compliance remain applicable.
- [ ] Submit for review only after explicit approval to do so.
