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
