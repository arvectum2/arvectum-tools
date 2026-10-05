# App Store release checklist — iOS 0.5.1 (build 7)

## Scope
- [x] Main screen: production native ad R-M-20141949-1.
- [x] Result screen: compact adaptive banner R-M-20141949-2.
- [x] No interstitial / app-open ads.
- [x] Compact native layout preserves the 300×160 pt media requirement.
- [x] Native ad is cached per app session to avoid a new network request after returning from result to settings.
- [x] Compact chips scale before truncating on narrow iPhones.
- [x] Automated no-scroll UI gate passed on iPhone 17e: RU/EN × light/dark × all 3 modes with worst-case long native copy.
- [x] Signed Release device-target build for the connected iPhone 13 completed successfully without replacing the App Store installation.
- [ ] Physical iPhone smoke test with real production ads.
- [ ] Verify App Privacy answers and public privacy page against the final archive.
- [ ] Archive 0.5.1 (7), validate, export IPA, upload and attach the correct build.
- [ ] Submit for App Review.

## Release tooling
- Version/build source of truth: ios/project.yml.
- finalize_appstore.py reads MARKETING_VERSION from the project (override: ARVECTUM_APP_VERSION).
- upload_build.py takes --ipa or selects the newest exported PhotoPodRazmer.ipa; no release-path hardcode.
