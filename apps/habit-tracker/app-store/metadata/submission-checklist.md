# ChickMark 1.0.0 — Submission checklist

## Binary — done

- [x] App: ChickMark / bundle ID `ru.arvectum.tools.habits`
- [x] Version: 1.0 / binary CFBundleShortVersionString 1.0.0
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
- [x] Upload to App Store Connect succeeded
- [x] Build processing completed: VALID / APP_STORE_ELIGIBLE
- [x] Build 1 attached to iOS version 1.0

Canonical release artifact:
- Source commit: `b0ee73bd98995c6a455d133a0cff4129354cfd2a`
- Archive: `/Users/master/ChickMarkRelease/1.0.0-build1-final/ChickMark.xcarchive`
- IPA: `/Users/master/ChickMarkRelease/1.0.0-build1-final/export/HabitsByArvectum.ipa`
- IPA SHA-256: `80f11039292e213a7d987a1cc10121da2b4374c9b565c1bb3515c6fe29004b0b`

## App Store metadata — done

- [x] Primary locale: Russian
- [x] English localization
- [x] RU description / subtitle / keywords
- [x] EN description / subtitle / keywords
- [x] RU iPhone screenshots: 3 × 1320×2868
- [x] EN iPhone screenshots: 3 × 1320×2868
- [x] RU Apple Watch screenshot: 416×496
- [x] EN Apple Watch screenshot: 416×496
- [x] All screenshot assets uploaded and COMPLETE
- [x] Screenshots are opaque PNGs without alpha
- [x] Support URL: https://arvectum.com/contact.html
- [x] Privacy Policy URL: https://arvectum.com/privacy.html
- [x] App Review notes and contact details
- [x] App Review credentials: none required
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = NO`
- [x] Primary category: Health & Fitness
- [x] Age rating questionnaire completed: 4+
- [x] Content rights: no third-party content
- [x] Regulated Medical Device declaration: No
- [x] App Privacy: Data Not Collected
- [x] App Privacy responses published
- [x] Price schedule and availability configured
- [x] 175 territories enabled
- [x] Release behavior: automatically release after approval

## App Review — submitted

- [x] Draft review submission created
- [x] iOS 1.0 / build 1 added to review submission
- [x] Submit for Review completed
- [x] Review submission state: `WAITING_FOR_REVIEW`
- [x] App version state: `WAITING_FOR_REVIEW`
- [x] Submitted on 2026-10-03

## Next

- [ ] Do not modify/re-upload build 1 while it is under review unless Apple requests a change
- [ ] Watch App Store Connect / Apple review email for state changes or reviewer questions
- [ ] If approved, verify automatic release and public App Store listing
- [ ] If rejected, address only the reviewer issue and keep the V1 scope frozen
