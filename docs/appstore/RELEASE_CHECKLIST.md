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

- [ ] Create App Store Connect app record
- [ ] Upload build `0.4.2 (1)`
- [ ] Wait for build processing
- [ ] Add Russian store metadata
- [ ] Upload iPhone 6.9-inch screenshots
- [ ] Complete App Privacy: Data Not Collected
- [ ] Complete age-rating questionnaire
- [ ] Confirm content-rights answers
- [ ] Confirm DSA/trader status is complete for the organization
- [ ] Confirm app availability territories
- [ ] Confirm free pricing / tax category
- [ ] Select processed build for version 0.4.2
- [ ] Complete export-compliance questions
- [ ] Submit to App Review
- [ ] Choose release mode after approval

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
- IPA SHA-256: `a9ef53c7815b002b65183ba4dcc1c11c60cb27ecf523a143a19aec68db543fce`
