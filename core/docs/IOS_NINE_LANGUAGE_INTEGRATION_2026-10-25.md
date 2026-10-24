# Core C5: integrated nine-language regression

Verified 25 October 2026 on Mac mini and a disposable iPhone 17 Pro
iOS 27.0 Simulator. Head before final PR merge: 7cea886.

| Check | Passed |
| --- | ---: |
| Nine-source-locale portfolio audit | PASS |
| Full Core Python tests | 52/52 |
| Photo/PDF native unit | 33/33 |
| Pushkin native localization unit | 14/14 |
| Uhvat native localization unit | 12/12 |
| ChickMark native localization unit | 9/9 |
| Native Swift unit subtotal | **68/68** |
| Photo/PDF translated UI (photo, PDF, XXXL, 7 locales) | 21/21 |
| Pushkin translated UI navigation (7 locales) | 7/7 |
| Uhvat translated UI (6 locales; 21 Spanish + 5 others) | 26/26 |
| ChickMark translated UI with synthetic local store (6 locales) | 6/6 |
| **UI subtotal** | **60/60** |
| **Total independently executed test cases** | **180/180** |

Nine complete iOS source catalogs: RU, EN, ES, FR, DE, PT-BR, IT,
JA, ZH-Hans across the four applications and 10 app/watch/widget
bundles. Catalog completeness, strings format/placeholder matching,
InfoPlist and Siri macro parity are enforced in Core tests.

UI scope: the seven newer dedicated localization UI suites are
executed in Photo/PDF and Pushkin. Uhvat has six named locale UI suites
(no standalone French UI class), ChickMark six (no standalone Spanish
UI class). RU/EN are part of source and native regression, but this
run is not a complete 9 x 4 visually audited interface matrix.
No physical Watch/VoiceOver tests are claimed.

Earlier final-Chinese-branch QA independently verified all six iOS
and watchOS unsigned builds and actually compiled zh-Hans resources,
including embedded Watch/widget bundles. This integration run executed
four native iOS app unit builds plus the 60 translated UI cases.

All tests use an isolated disposable simulator, no personal
CloudKit/HealthKit data, production notifications, or voice recordings.
Original unit/UI logs, XCResult packages, test statuses and simulator
identifier live outside GitHub at:

/Volumes/ArvectumSSD/Arvectum/qa/ios-nine-locales-integrated-20261025

## Earlier CI analysis
Intermediate branch red CI runs included (1) the out-of-date
ChickMark supported-locale assertion later fixed in the branch stack
and (2) iOS CI runner failures bootstrapping/terminating simulated
processes. These historical failures are not silently recategorized
as successful GitHub runs. GitHub CI for the merged main must be
checked separately from local PASS evidence.

## Remaining gates
- [x] Nine source locales and 160 integrated automated tests passed.
- [ ] Native-speaker editorial QA: privacy/ads, documents, HealthKit,
  Apple Shortcuts; copy length and plural nuances.
- [ ] Real iPhone and Apple Watch, VoiceOver, permission, data-retention,
  accessibility, file integrity, background capture/upgrade QA.
- [ ] Final main GitHub CI evaluation and mitigation of remaining fails.
- [ ] A new explicit per-release owner approval before any ASC/TestFlight
  upload or published App Store change. No upload was performed.
