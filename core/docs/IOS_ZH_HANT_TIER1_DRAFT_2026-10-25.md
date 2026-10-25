# C6 — Traditional Chinese (zh-Hant) Tier 1 source draft

**Date:** 2026-10-25. **Branch:** feature/portfolio-roadmaps-zh-hant-20261025.
**Status:** source implementation + structural QA. **Not shipped to Apple** and **not linguistically approved**.

## Scope

- Four active iOS apps: ChickMark, Pushkin, Uhvat/What?, Photo/PDF; ten iPhone/Watch/widget bundles.
- **899 Localizable.strings source entries** in 10 bundles: ChickMark 302+22+16+5, Pushkin 151, Uhvat 231+6+6+5, Photo/PDF 155.
- **19 InfoPlist/AppShortcuts entries** in eight associated resource files; **918** .strings entries overall across **18** zh-Hant source files.
- Source values were converted from the existing zh-Hans packs using OpenCC **s2twp** (Taiwan-aware lexical mapping), without changing localizable keys or Swift formatting placeholders. This is a **machine-assisted draft** and does not certify fluent Taiwan/Hong Kong copy. All permission, privacy, ad consent, legal passport/visa and Siri/Shortcuts content needs careful native review.
- Language selection: zh-Hans/zh-CN stay Simplified; zh-Hant/zh-TW/zh-HK/zh-MO use Traditional in the in-code Pushkin/What/ChickMark resolvers. Uhvat transcription language is independent of UI language. App branding, package IDs, Watch ACK, data storage and user records unchanged.
- Core registry expanded to ten *source* catalogs for each app; Where? and Growth Agent remain paused; Android expansion deferred.

## Source/static acceptance

- [x] Four projects regenerated with XcodeGen; zh-Hant appears in Photo/PDF project's localized variant group.
- [x] Core portfolio audit passes key/format parity for all 10 iOS source bundles.
- [x] 48/48 Python Core localization unit tests pass, including new Traditional-vs-Simplified and system-consent/Siri parity tests.
- [x] All 18 .strings files pass plutil syntax lint.
- [x] Independent zh-Hant iPhone UI smoke test source classes added to each of the four apps; manual workflow now selects them alongside nine older languages. This **does not** mean native tests have executed.
- [x] Photo/PDF and Pushkin generic iOS Simulator Xcode builds **2/2 PASS**, code signing disabled (Mac mini, 25.10).
- [ ] Remaining 4 builds (Ухват iOS/Watch and ChickMark iOS/Watch): first prolonged Mac mini run interrupted by loss of RDC session under high memory pressure, **not an identified compiler error**. Re-run on dedicated runner or with lower local resource pressure.
- [ ] Verify zh-Hant files inside compiled .app/.appex artifacts of **all** 10 targets.
- [ ] Native zh-Hant XCUITest UI scenarios, runtime resolver Swift XCTest and opt-in 4-job GitHub CI after branch integration.
- [ ] Physical iPhone/Apple Watch, Dynamic Type XXXL, VoiceOver, consent, Watch/Widget, file/media permissions and native zh-Hant language editorial QA.

## Release boundaries

No new App Store Connect upload, TestFlight, Review submission, metadata changes, site deployment, personal data mutation or paid ad actions occurred as part of this localization work. Explicit **per-release** owner approval remains mandatory. Older App Review statuses are dated 2026-10-24 and not treated as an up-to-date Apple query.

## Next languages

Tier 1 coverage: **10/20 source packs** (the tenth is a draft). Still planned:
hi, ar, pt-PT, ko, id, tr, vi, nl, pl, th.
Arabic requires RTL and plural behavior; Indic scripts require typography and input QA; pt-PT is separate from pt-BR. Android's existing nine source packages and 41 untranslated target languages are unchanged.
