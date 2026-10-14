# ChickMark 1.4.1 (15) — public-capable release, **WAITING FOR REVIEW**

Date: 2026-10-14
App ID: 6818711298
Source branch: release/chickmark-1.4.1-public-20261014 (from main + tested feature/chickmark-healthkit-1.4 merge).
Source tested model: owner accepted 1.4.1 (14) internal TestFlight, 2026-10-14. After merging, actual chickmark/ios source compared equal to tested branch (before build-number bump). No migration for SwiftData Models, ChickMarkBackup or group CloudKit storage.

## Apple distribution receipt
- Public-capable IPA: /Volumes/ArvectumSSD/Arvectum/builds/chickmark/1.4.1-15-public/export-public/HabitsByArvectum.ipa
- SHA-256: c380fdbf2da5a6dd94416273dfc2e7743e717d0e90d41cc41dfe9cfa92f1c5c0
- iPhone app, iPhone Widget, Watch app and Watch complication: all **1.4.1 (15)**, strict signatures verified.
- Apple distribution/production push, Production CloudKit, get-task-allow=false. New Watch widget HealthKit read entitlement present.
- Archive audit: 0 errors; release hygiene, architecture, screenshot PNG asset checks pass.
- Public App Store distribution: **upload succeeded**; Apple API processing **VALID**, build audience **APP_STORE_ELIGIBLE** (not internal-only).
- App Store build ID: 1f59a968-bfa9-41f0-b998-100040367b6d
- App Store version ID: 4ad06087-2c8b-46e9-9e8f-b46e950d4e0e
- Version status: **Waiting for Review**, verified in authenticated ASC after submission; release type **MANUAL** (no automatic public rollout).
- Build/version relationship read back and verified through App Store Connect API. Four locales (ru, en-US, es-ES, es-MX) have updated What's New; App Review Notes updated and persisted. App Review submission accepted with 1 Item Submitted on 2026-10-14; Apple decision pending.

## QA state
- Accepted internal v1.4.1 (14): real numeric keyboard arrow, Watch auto-check, autonomous Watch face complication refresh without opening ChickMark; refresh required more than 25 minutes in the reported trial. Original HealthKit measurements never persist to shared stores.
- Full 173/173 iOS unit tests pass after merging into main-based release branch; Watch generic build passes. Accepted branch GitHub Habits iOS CI green. Public-branch CI still needs final green check; link: https://github.com/arvectum2/arvectum-tools/actions/runs/38613847039.
- Existing UI/Watch simulator tests and archive smoke pass. True physical offline WatchConnectivity, revoked Health authorization, midnight boundary and live Yandex ad fill not independently verified in this pass; do not silently represent them as complete.

## App Review submission and release hold

- App Privacy was corrected and published in ASC: from Data Not Collected to Data Not Linked to You. Eight Yandex/AppMetrica/KSCrash technical and advertising categories, purposes and associated link/tracking choices are recorded in privacy-review-1.4.1.md. Raw HealthKit readings stay on device.
- Safari App Store Connect authenticated UI accepted build 1.4.1 (15) as Item Ready to Submit and then 1 Item Submitted; version header changed to **Waiting for Review**.
- Version release setting is MANUAL. Approval, if granted, will not itself publish the update. Current public app remains 1.4.0.
- Release branch CI 38615994169 SUCCESS; changed CI runner timeout via PR #39; main CI rerun outstanding at checkpoint. No app source/binary changes since public build15 was uploaded.
- Optional extended physical QA for offline WatchConnectivity, denied HealthKit, midnight rollover, production ad fill remains. Do not represent these as confirmed and do not uninstall/reset a user's data.

## Canonical documents
- chickmark/ROADMAP.md
- chickmark/app-store/metadata/release-notes-1.4.1.md
- chickmark/app-store/metadata/review-notes-1.4.1.md
- chickmark/app-store/metadata/privacy-review-1.4.1.md
