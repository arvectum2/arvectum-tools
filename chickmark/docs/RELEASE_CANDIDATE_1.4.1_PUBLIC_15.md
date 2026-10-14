# ChickMark 1.4.1 (15) — public-capable candidate, **NOT SUBMITTED**

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
- Version status: **PREPARE_FOR_SUBMISSION**; release type **MANUAL** (no automatic public rollout).
- Build/version relationship read back and verified through App Store Connect API. Four locales (ru, en-US, es-ES, es-MX) have updated What's New; App Review Notes updated and persisted. No public submission or App Review decision exists for 1.4.1.

## QA state
- Accepted internal v1.4.1 (14): real numeric keyboard arrow, Watch auto-check, autonomous Watch face complication refresh without opening ChickMark; refresh required more than 25 minutes in the reported trial. Original HealthKit measurements never persist to shared stores.
- Full 173/173 iOS unit tests pass after merging into main-based release branch; Watch generic build passes. Accepted branch GitHub Habits iOS CI green. Public-branch CI still needs final green check; link: https://github.com/arvectum2/arvectum-tools/actions/runs/38613847039.
- Existing UI/Watch simulator tests and archive smoke pass. True physical offline WatchConnectivity, revoked Health authorization, midnight boundary and live Yandex ad fill not independently verified in this pass; do not silently represent them as complete.

## Privacy and publication HOLD
1. **P0: Confirm and publish accurate App Store Connect App Privacy answers via signed-in UI.** The distributed Yandex Mobile Ads SDK transitively includes AppMetrica and KSCrash privacy manifests declaring Device ID, advertising metrics, location/diagnostics and one tracking=true component. Verify whether those collection paths are active in this app's actual SDK settings, include required disclosure and ATT treatment, and publish correct App Privacy answers. The legacy release docs' “No Data Collected” statement is not sufficient, and current portal responses were unavailable for verification while Safari was signed out.
2. The official website Privacy Policy now explicitly covers local-only Apple Health processing and is live: https://arvectum.com/privacy (GitHub site PR #14, HTTP 200). It already discloses optional Yandex advertising identifiers and technical data.
3. App Store 1.4.1 draft and binary exist, but **do not submit to App Review or publish until P0 is resolved**. Keep release type MANUAL.
4. Where feasible, physical-device check of preserved history/CloudKit, Watch offline reconciliation, consent denied and Yandex ad loaded/no-fill behavior is recommended. Never uninstall or reset the user's real habit data for verification.

## Canonical documents
- chickmark/ROADMAP.md
- chickmark/app-store/metadata/release-notes-1.4.1.md
- chickmark/app-store/metadata/review-notes-1.4.1.md
- chickmark/app-store/metadata/privacy-review-1.4.1.md
