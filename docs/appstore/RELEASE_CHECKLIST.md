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
- [x] Release archive: version `0.4.2 (2)`
- [x] App Store IPA exported and distribution-signed
- [x] Three 6.9-inch iPhone screenshots captured at 1320×2868

## App Store Connect

- [x] Create App Store Connect app record (Apple ID `6816346084`)
- [x] Upload build `0.4.2 (2)` — Delivery UUID `479341f5-e89c-479c-b1d0-7825acf26eec`
- [x] Build processing completed: `VALID` for build 2
- [x] Add Russian store metadata
- [x] Upload 3 iPhone screenshots (6.5-inch slot, 1284×2778)
- [x] Complete and publish App Privacy: **Data Not Collected**
- [x] Complete age-rating questionnaire: **4+**
- [x] Confirm content rights: no third-party content
- [x] DSA trader status already configured for LLC ARVECTUM
- [x] Availability: all 175 countries or regions
- [x] Pricing: free (`$0.00` base price)
- [x] Select processed build 2 for version 0.4.2
- [x] Export compliance: non-exempt encryption = false
- [x] Submit to App Review
- [x] Release mode: automatically after approval
- [x] First review response received: **Guideline 2.1 — Information Needed**
- [x] Add all six requested information items to App Review Notes
- [x] Prepare written response for the App Review conversation
- [x] Prepare physical iPhone QA/install workflow
- [x] Prepare physical-device screen-recording workflow: CoreDevice `DisplayService` + `UniversalHIDService` + `ScreenCaptureService`, raw HEVC → H.264 MOV
- [ ] Connect iPhone 13 to Mac mini by USB
- [ ] Complete final QA of 0.4.2 (2) on iPhone 13 / iOS 27.0
- [ ] Record the complete physical-device user flow
- [ ] Attach recording and send the prepared reply to Apple
- [ ] Resubmit 0.4.2 (2) to App Review
- [ ] Apple review completed
- [ ] Version available on the App Store

**Current status: `REJECTED` — Guideline 2.1 / Information Needed. No functional defect was identified by Apple.**

## Release artifact

Local IPA: `ios/build/AppStoreExport-0.4.2-2/PhotoPodRazmer.ipa`

Verified properties:
- bundle: `ru.arvectum.tools.tosize`
- display name: `Фото под размер`
- version: `0.4.2`
- build: `2`
- signing: Apple Distribution / LLC ARVECTUM
- production provisioning profile: `Arvectum Photo Pod Razmer App Store`
- `get-task-allow = false`
- privacy manifest present
- IPA SHA-256: `b3cded0ceddf3ca0818b14dba9d8b3ae8283c7bb5b25f11bae230d34661f2ef8`
