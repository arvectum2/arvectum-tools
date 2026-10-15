## Release 1.0.1 (6) — Watch capture fixes, 2026-10-15

**App Store Connect final status (2026-10-15):** Upload passed Apple's validation, build 6 processed as `VALID`, and review submission `22bceed6-2be2-41fd-be49-c01c447f6ab6` was accepted with status **WAITING_FOR_REVIEW**. App Store version ID `884bd463-07cb-4e8a-a36c-d59ed3cc471a`; build ID `f75dc11b-bffa-4c24-9b9b-4707a4994630`. The previously published 1.0.0 (5) remains READY_FOR_SALE pending approval. Existing screenshots for en-US were inherited by the new version; ru locale continues to use the existing en-US fallback. Release notes entered for ru and en-US.


- **Distribution:** public 1.0.0 (5) is READY_FOR_SALE; target 1.0.1 (6), App ID 6822476399.
- **Watch complication:** `widgetURL(what://capture)` rather than `Link`, so one tap should deliver the capture deep-link to the Watch app; `.onOpenURL` already triggers recording.
- **Branding:** use user-approved WhatGlyph on all Watch complication families and the in-app Record button; watchOS watch + widget asset catalogs confirmed included in compiled archive.
- **Watch lifecycle:** leaving the app for the watch face/background calls `finishCaptureWhenBackgrounded()`, which stops and queues completed audio. Pending mic requests are invalidated so a late callback cannot start a recording in the background.
- **Recovery limitations:** WatchQueueRecovery retains unqueued finalized AAC and never deletes incomplete files; not a proven guarantee against forced termination or power loss mid-AAC.
- **Validation:** iOS simulator 51 pass, 3 experimental skips, 2 UI pass; watchOS simulator build pass. App Store archive 1.0.1 (6) signed, exported, Apple validation passed (no errors).
- **Signed archive:** `/Volumes/ArvectumSSD/Arvectum/releases/what/What-1.0.1-rc2.xcarchive`.
- **Distribution IPA:** `/Volumes/ArvectumSSD/Arvectum/releases/what/export-1.0.1-rc2/WhatIOS.ipa`.
- **Physical Watch acceptance:** not yet executed. Specifically test one-tap capture, Crown-close autosave and one-time iPhone delivery before considering P0 physical acceptance done.
- **Privacy scope:** no collection, ads, analytics, third-party speech server, or changes to iPhone storage format.

## App Store Connect submission — 2026-10-14 (current status)

- **Submitted successfully:** App ID `6822476399`, iOS version **1.0.0 (5)**. Apple confirmed **“1 Item Submitted”** and the status **“Waiting for Review”** on 2026-10-14.
- **Listing and ASO:** Russian `Ухват: голосовые заметки` and English `UhWhat? Voice Notes`; subtitle, descriptions, keywords, support and marketing links saved. Category Productivity / Utilities; age rating 4+.
- **Media accepted:** 3 iPhone screenshots with synthetic recordings and a 416 × 496 Apple Watch Series 12 screenshot from the watchOS simulator. Original watch screenshot: `releases/what/screenshots/rc5/uhvat-apple-watch-series12.png` on Mac mini.
- **Review material:** 2,430-character English reviewer walkthrough, no sign-in, contact info reused from ChickMark; 27-second demonstration of synthetic notes accessible via https://arvectum.com/tools/what/review/index.html. Reviewer link and MP4 publicly return HTTP 200.
- **Privacy:** app declaration “Data Not Collected” was published in App Store Connect. Privacy policy `https://arvectum.com/privacy` saved for both English (U.S.) and Russian localizations.
- **Commercial setup:** free price ($0.00), public distribution in all 175 App Store countries and regions. Version 1.0.0 build 5 was selected, not the older build 4.
- **Build/device acceptance:** 51 iOS repository tests passed (3 experimental checks skipped); watchOS simulator build passed. Physical iPhone 13 updated from build 3 to build 5 **after backup** and all 33 local source files, including 23 M4A recordings, had unchanged SHA-256 hashes. The final physical Apple Watch recording, disconnection/reconnection transfer, and tap-to-first-audio timing remain unverified: **do not claim a physical Watch acceptance pass**.
- **Review outcome:** Pending Apple decision; first-pass approval cannot be guaranteed. Do not upload any personal recordings.

> Earlier RC3/RC4 “not submitted” checklist statuses below are historical and were superseded by this RC5 submission.

# What? 1.0.0 — App Store submission

- Bundle: ru.arvectum.tools.what
- Platforms: iPhone (iOS 17+) + Apple Watch (watchOS 10+)
- Category: Productivity; free; no ads or in-app purchases
- English title: UhWhat? — Voice Notes
- English subtitle: Catch thoughts in one tap
- Russian title: Ухват — Голосовые заметки
- Russian subtitle: Запиши мысль в одно касание
- Support: https://arvectum.com/contact.html
- Privacy policy: https://arvectum.com/privacy
- Marketing URL: https://arvectum.com/tools/

## English description

Catch a thought before it disappears. Tap the big microphone button in UhWhat? on your iPhone to record immediately. No Apple Watch needed. If you have an Apple Watch, the complication starts recording in one tap without taking out your iPhone. Audio stays safe and local.

On iPhone, play your voice notes, transcribe them on-device, edit text, search by words, archive and export the audio or transcription. No account, no server-side storage, no distractions.

## Русское описание

Запиши мысль, пока она не ушла. Нажми большую кнопку микрофона на iPhone — запись начнётся сразу. Apple Watch не нужны. Если часы есть, запись можно запустить одним нажатием с циферблата. Аудио сохраняется локально.

На iPhone можно слушать записи, расшифровывать их, исправлять текст, искать по словам, архивировать и экспортировать аудио или расшифровку. Без регистрации и облачного хранения записей.

## Privacy and release gate

All voice audio and transcriptions remain on the user's paired devices. No analytics, tracking, advertisements or developer cloud processing in the release source. App Store Connect privacy declarations must be checked against the final build. Original audio is retained even if transcription fails.

- [x] Release source separated from experimental semantic-search corpora.
- [x] iOS/watchOS signed debug builds installed on real paired devices.
- [x] Final build 1.0.0 (3) physically installed on iPhone 13 after backup; **18 recording records, 18 original M4A files, 16 transcripts and all 33 original app-support files preserved byte-identically**.
- [x] Watch queue backed up and preserved; no pending transfers at installation.
- [x] iOS simulator suite: 50 passed, zero failed, three optional experimental checks skipped.
- [x] Apple required-reason privacy manifests in iOS/watchOS bundles.
- [x] Release configuration xcarchive generated.
- [x] App icon supplied by user: matching mint emblem on navy rendered at opaque 1024x1024 for iPhone and Apple Watch. Circular home record button uses matching symbol.
- [ ] Localized identity: build 4 uses «Ухват» (RU), «UhWhat?» (EN) for installed apps and widget labels; verify display on physical devices before release.
- [ ] iPhone home → microphone → save → playback physically accepted; Watch and phone start-to-microphone p95 measured; target <=2 sec in warm/normal conditions.
- [ ] Offline real Watch recording and delayed transfer rechecked on the final signed build.
- [x] iPhone 18 Pro Max simulator capture-first screenshot saved at 1320x2868 in releases/what/screenshots; no user's private notes shown.
- [ ] Additional App Store screenshot review for library and recorder, with only synthetic demonstration content.
- [x] User-approved What? emblem used for iPhone/Watch icon and circular Quick Capture button; assets in Release 1.0.0 (3).
- [x] App Store Connect distribution archive and signed IPA successfully exported at releases/what/export-rc3/WhatIOS.ipa (2.3 MB). Exported app has get-task-allow=false.
- [ ] App Store Connect listing, screenshot upload and review submission (not sent yet; physical final Watch + iPhone acceptance pending).


## Release candidate 1.0.0 (3) — 2026-10-13

- Sources: branch release/what-1.0.0, iOS + watchOS apps, WidgetKit complication/phone widget.
- Capture-first iPhone screen: brand logo, large circular branded record button, local recording begins on a single tap, bottom saved-recordings card. Original inbox/archive/transcription/search/export preserved as a second screen.
- Original emblem is user-provided. Scalable recreation in ios/tools/generate_brand.swift (source artifact), with iPhone AppIcon and Watch AppIcon fully opaque 1024x1024 PNG and separate mint transparent glyph.
- Full iOS unit suite: 50 passed, 3 experimental semantic checks skipped, 0 failed.
- UI interaction test source exists but Simulator AX service failed to initialize in a dedicated attempt (test infrastructure timeout, not a tested acceptance pass). Run separately from reliable unit test scheme. Manual real-device UI acceptance still required.
- Official archive: /Volumes/ArvectumSSD/Arvectum/releases/what/What-1.0.0-rc3.xcarchive
- App Store distribution IPA: /Volumes/ArvectumSSD/Arvectum/releases/what/export-rc3/WhatIOS.ipa
- Verified signed release contains branded iPhone app icon, glyph asset, Watch app + icon, iOS recording widget; original 18/18/16 iPhone user files unchanged byte-for-byte.
- Remaining: physical iPhone mic capture + navigation, watch complication offline queue / reconnect test on final build, submission screenshots and ASC metadata upload, final Apple review. No user content uploaded anywhere.

## Release candidate 1.0.0 (4) — signed distribution verified (2026-10-14)

- **Source:** release/what-1.0.0 (localized consumer name Ухват / UhWhat?; technical bundle IDs are deliberately unchanged).
- **Automated:** 51 passed, 3 experimental skipped, zero failed; watchOS simulator build succeeded; the capture-first home/inbox navigation UI test passed on a **Russian-language** iPhone 18 Pro Max simulator.
- **Local diagnostics:** no speech or transcript content is stored in capture-timing measurements. iPhone handler-to-first-audio-buffer latency p95 appears in Sync diagnostics after repeated use. Watch records handler-to-AVAudioRecorder-start timings separately in local OS logs.
- **Archive:** /Volumes/ArvectumSSD/Arvectum/releases/what/What-1.0.0-rc4.xcarchive
- **App Store IPA:** /Volumes/ArvectumSSD/Arvectum/releases/what/export-rc4/WhatIOS.ipa
- **Checks:** distribution signature verified (get-task-allow=false); 1.0.0 build 4; localized RU/EN app display names present, bundled Watch app/complication + iPhone widget present; no derived private RuWordNet data present.
- **RU main-screen screenshot:** /Volumes/ArvectumSSD/Arvectum/releases/what/screenshots/uhvat-home-ru-1.0.0-build4.png, taken in simulator with no user recordings.
- **Not done:** app not installed as build 4 on the physical iPhone/Watch; do not claim physical capture, playback, Watch offline transfer or p95 latency accepted. The IPA has not been uploaded to App Store Connect.

## Build 1.0.0 (4) source changes — 2026-10-14

- Rebranded localized installed-app names to «Ухват»/«UhWhat?» without changing bundle identifiers, deep links, or data paths.
- Main capture screen, primary recording actions, widgets and Watch complication use the localized name.
- Tightened recovery: staged iPhone AAC audio must contain audible signal even when a crash prevented recording of Stop elapsed time; original source files are never deleted on rejection.
- RC3 archive and IPA above are **older build (3)** and must not be submitted as build (4). Rebuild and re-export after remaining checks.
