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
- [x] **6/6 unsigned Simulator builds PASS**: Photo/PDF iOS, PUSHKIN iOS, Uhvat iOS, ChickMark iOS, Uhvat watchOS, ChickMark watchOS.
- [x] Italian source resources `it.lproj` directly verified in compiled four iOS `.app` bundles and embedded watchOS/widget targets.
- [x] Real iOS 27.0 iPhone 17 Pro Simulator Italian UI **6/6 PASS**:
  Photo/PDF synthetic image + PDF + Accessibility XXXL **3/3**, Pushkin
  tab navigation **1/1** (final corrected test), Uhvat synthetic AXXXL
  home **1/1** (no recording), ChickMark new-habit isolated store **1/1**
  (no CloudKit changes).
- [x] Real native Swift XCTest **29/29 PASS**: Pushkin CoverageCatalogTests
  12/12, Uhvat LanguageFallbackTests 10/10, ChickMark LocalizationTests
  7/7. Italian language routing and grammatically correct counters verified.

## Open gates
- [ ] Native Italian proofreading, especially ads/privacy, document
  photo requirements, data-loss language and Apple Health consent.
- [ ] Physical iPhone/Apple Watch VoiceOver, Siri/Shortcuts, permissions,
  watch background capture and non-destructive upgrade acceptance.
- [ ] App Store metadata, any upload, TestFlight or publication requires
  explicit version-specific owner approval. Nothing was released.
- [ ] Continue iOS-first: Japanese ja and zh-Hans after completing IT QA.

Stacked draft PR chain: #141 -> #142 -> #143 -> #144 -> Italian PR.

## Incident triage
The first Italian Pushkin UI test expected the English tab identifier
"Apps", but the correctly translated UI label is the invariant Italian
"App". Updated the test expectation, then **reran successfully 1/1**.
The first UI test process was stopped after its failure was logged and
its completion stalled; this is NOT counted as a passing test. Final
numbers reflect the successful rerun. No production Pushkin behavior
needed changing for this incident.

## QA provenance
Dedicated disposable iPhone 17 Pro iOS 27.0 Simulator; unsigned
Xcode 27.1 builds; all real XCTest logs and xcresult packages kept
on Mac mini SSD outside GitHub, plus this Markdown summary.
