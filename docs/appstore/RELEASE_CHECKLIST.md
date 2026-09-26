# App Store release checklist — iOS 0.4.2

## Product and build

- [x] Native SwiftUI iPhone app created
- [x] Frozen three-mode Product Contract preserved
- [x] Local processing only
- [x] No ads, analytics, account, backend, or cloud processing
- [x] Unit tests: 4/4 passing
- [x] Simulator QA on iPhone 17 Pro Max
- [x] Privacy manifest included
- [x] App icon included
- [x] Bundle ID registered: `ru.arvectum.tools.tosize`
- [x] App Store distribution profile created
- [x] Release archive: version `0.4.2 (1)`
- [x] App Store IPA exported and distribution-signed
- [x] Three 6.9-inch iPhone screenshots captured at 1320×2868

## App Store Connect

- [x] Create App Store Connect app record (Apple ID `6816346084`)
- [x] Upload build `0.4.2 (1)`
- [x] Build processing completed: `VALID`
- [x] Add Russian store metadata
- [x] Upload 3 iPhone screenshots (6.5-inch slot, 1284×2778)
- [x] Complete and publish App Privacy: **Data Not Collected**
- [x] Complete age-rating questionnaire: **4+**
- [x] Confirm content rights: no third-party content
- [x] DSA trader status already configured for LLC ARVECTUM
- [x] Availability: all 175 countries or regions
- [x] Pricing: free (`$0.00` base price)
- [x] Select processed build for version 0.4.2
- [x] Export compliance: non-exempt encryption = false
- [x] Submit to App Review
- [x] Release mode: automatically after approval
- [ ] Apple review completed
- [ ] Version available on the App Store

**Current status: `WAITING_FOR_REVIEW` (submitted 2026-09-26).**

## Release artifact

Local IPA: `ios/build/AppStoreExport/PhotoPodRazmer.ipa`

Verified properties:
- bundle: `ru.arvectum.tools.tosize`
- display name: `Фото под размер`
- version: `0.4.2`
- build: `1`
- signing: Apple Distribution / LLC ARVECTUM
- production provisioning profile: `Arvectum Photo Pod Razmer App Store`
- `get-task-allow = false`
- privacy manifest present
- IPA SHA-256: `bd09c03d70a18b1debc2400243155287c28a365d16d76060f319bd49cc8d590e`
