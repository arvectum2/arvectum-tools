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
- [x] Privacy Policy URL: https://arvectum.com/privacy
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

### Preventive review audit against prior Arvectum rejections

- [x] New-app information request covered proactively in App Review Notes: purpose/audience, setup/access, external services, regional differences, regulated/protected content
- [x] Business model explicitly documented: free, no IAP/subscription/paid unlock/external checkout
- [x] Sign-in required is disabled; no reviewer credentials are needed
- [x] Privacy/data path documented: no Arvectum backend, no analytics/ads/tracking; private iCloud/CloudKit optional sync only
- [x] Submitted IPA entitlements audited: production APS, Production CloudKit, App Group; no unrelated network/VPN/server entitlement
- [x] App Store screenshots show the actual app in use (Today, progress/history, Manage, Apple Watch), not title/splash-only art
- [x] Support and Privacy Policy URLs return HTTP 200
- [x] No Apple trademark/product term is used in the app name
- [x] Physical-device App Review recording attached from iPhone 13 / iOS 27.0.1, recorded against the exact submitted commit b0ee73b / build 1

- [x] Draft review submission created
- [x] iOS 1.0 / build 1 added to review submission
- [x] Submit for Review completed
- [x] App Review physical-device video attached: `ChickMark-Physical-iPhone13-Build1-AppReview.mov` (24.3 s, H.264); App Store Connect attachment asset state `COMPLETE`
- [x] Review attachment ID: `d2c27acf-84ea-4c0d-b294-abd25813f686`
- [x] Review submission state: `WAITING_FOR_REVIEW`
- [x] App version state: `WAITING_FOR_REVIEW`
- [x] Submitted on 2026-10-03

## Next

- [ ] Do not modify/re-upload build 1 while it is under review unless Apple requests a change
- [ ] Before the first ad-enabled build, update App Privacy from "Data Not Collected" using the Xcode privacy report from that exact archive
- [x] Canonical Privacy Policy URL for all Arvectum apps: https://arvectum.com/privacy
- [ ] Watch App Store Connect / Apple review email for state changes or reviewer questions
- [ ] If approved, verify automatic release and public App Store listing
- [ ] If rejected, address only the reviewer issue and keep the V1 scope frozen
