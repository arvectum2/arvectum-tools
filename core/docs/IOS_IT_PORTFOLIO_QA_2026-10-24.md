# Core C5.4 — Italian iOS-first localization (2026-10-24)

## Scope and boundary
Italian (it) source locales added for all **four active iOS apps** and
their Apple Watch/widget components. This is **not an App Store release**
nor native Italian editorial sign-off.

| App | iOS strings | watchOS | iPhone widget | Watch widget/complication |
| --- | ---: | ---: | ---: | ---: |
| Photo/PDF | 155 | — | — | — |
| Pushkin | 151 | — | — | — |
| Uhvat | 231 | 6 | 6 | 5 |
| ChickMark | 302 | 22 | 16 | 5 |

Total: **899 Italian Localizable.strings entries** across all 10 app bundles.
The seven complete source locales are EN, RU, ES, FR, DE, pt-BR, IT.
Android's existing 9 source locales remain unchanged.

## Engineering scope
- [x] All 10 Italian source catalogs include genuine localized copy, full
  key parity and placeholder safety against English source.
- [x] Localized companion InfoPlist permission text, including ad/ATT,
  microphone/camera/transcription, HealthKit, and Siri AppShortcuts.
- [x] Real runtime Italian locale resolution in PushkinCopy and Uhvat
  CaptureBrand; Italian noteCount forms and number formats.
- [x] ChickMark in-app language menu autonym Italiano, supported only
  when the full it.lproj catalog exists.
- [x] Core locale-registry and 7-language required-source regression:
  **41/41 unit tests PASS** (source/placeholder/language registry).
- [x] Added native Swift localization assertions and four Italian
  iOS XCUITest classes for synthetic no-user-data workflows.
- [x] XcodeGen regenerated projects.
- [ ] Four iOS/two watchOS Simulator build result — verify logs.
- [ ] Italian iOS Simulator UI photo/PDF/AXXXL, Pushkin tabs,
  Uhvat AXXXL, ChickMark isolated habit form — verify logs.
- [ ] App-specific Swift language/routing test totals — verify logs.

## Open gates
- [ ] Native Italian proofreading, especially ads/privacy, document
  photo requirements, data-loss language and Apple Health consent.
- [ ] Physical iPhone/Apple Watch VoiceOver, Siri/Shortcuts, permissions,
  watch background capture and non-destructive upgrade acceptance.
- [ ] App Store metadata, any upload, TestFlight or publication requires
  explicit version-specific owner approval. Nothing was released.
- [ ] Continue iOS-first: Japanese ja and zh-Hans after completing IT QA.

Stacked draft PR chain: #141 -> #142 -> #143 -> #144 -> Italian PR.
