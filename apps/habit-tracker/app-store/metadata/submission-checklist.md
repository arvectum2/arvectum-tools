# ChickMark 1.0.0 — Submission checklist

## Binary — done

- [x] App: ChickMark / bundle ID `ru.arvectum.tools.habits`
- [x] Version: 1.0.0
- [x] Build: 1
- [x] Signed App Store archive created
- [x] IPA exported with Apple Distribution signing
- [x] Apple Watch app included
- [x] Home/Lock Screen widgets included
- [x] Privacy manifests included in all four targets
- [x] Production entitlements verified: Push, CloudKit and App Group
- [x] Final ChickMark icon embedded for iPhone and Watch
- [x] Simulator regression: 100 unit tests + 11 UI methods, 0 failures; iOS-27-only VoiceOver test skips by design on iOS 26.5
- [x] Physical iPhone 13 / Apple Watch SE validation passed
- [x] Second-endpoint CloudKit convergence is explicitly not a V1 release gate
- [x] Upload to App Store Connect succeeded; package entered processing on 2026-10-03

Canonical release artifact:
- Source commit: `b0ee73bd98995c6a455d133a0cff4129354cfd2a`
- Archive: `/Users/master/ChickMarkRelease/1.0.0-build1-final/ChickMark.xcarchive`
- IPA: `/Users/master/ChickMarkRelease/1.0.0-build1-final/export/HabitsByArvectum.ipa`
- IPA SHA-256: `80f11039292e213a7d987a1cc10121da2b4374c9b565c1bb3515c6fe29004b0b`

## App Store metadata — prepared

- [x] Primary locale: Russian
- [x] English localization prepared
- [x] RU description / subtitle / keywords prepared
- [x] EN description / subtitle / keywords prepared
- [x] RU iPhone screenshots: 3 × 1320×2868
- [x] EN iPhone screenshots: 3 × 1320×2868
- [x] RU Apple Watch screenshot: 416×496
- [x] EN Apple Watch screenshot: 416×496
- [x] Screenshots are opaque PNGs without alpha
- [x] Support URL: https://arvectum.com/contact.html
- [x] Privacy Policy URL: https://arvectum.com/privacy.html
- [x] Review/support email: info@arvectum.com
- [x] App Review notes prepared
- [x] App Review credentials: none required
- [x] Export compliance predeclared in Info.plist: `ITSAppUsesNonExemptEncryption = NO`

## App Store Connect — remaining

- [ ] Wait until build 1 finishes processing and select it for version 1.0.0
- [ ] Add Russian metadata and screenshots
- [ ] Add English localization metadata and screenshots
- [ ] App Privacy: select “No, we do not collect data from this app”
- [ ] Age rating: apply prepared all-none / no-social-media answers from `portal-answers.md`
- [ ] Primary category: Health & Fitness
- [ ] Price: Free
- [ ] In-App Purchases: None
- [ ] Complete review/contact fields using `portal-answers.md` and `review-notes.md`
- [ ] Submit for App Review
