# C5.2 — German source localization across active iOS apps (24 October 2026)

## Scope and limits

Priority iOS -> watchOS -> Android. German is now the fifth
source catalogue for all four active iOS apps, not an App Store
release. Earlier stacked draft PRs #141 and #142 add Photo/PDF FR/DE.

| Product | iPhone entries | Watch entries | Phone widget | Watch widget/complication |
| --- | ---: | ---: | ---: | ---: |
| Pushkin | 151 | - | - | - |
| Uhvat | 231 | 6 | 6 | 5 |
| ChickMark | 302 | 22 | 16 | 5 |
| Photo/PDF (PR #142) | 155 | - | - | - |

All **10 active bundles** have full source EN/RU/ES/FR/DE catalogs;
899 German Localizable strings entries across the portfolio.
**744 newly added German entries** in this PR. Also DE InfoPlist
permission descriptions and ChickMark Siri AppShortcuts with
applicationName placeholder preserved.

## Runtime fixes

- Pushkin: DE added to PushkinCopy bundle resolver; appCount now
  reports 1 App / N Apps for German.
- Uhvat: DE added to CaptureBrand interface resolver and real bundle;
  localized de_DE formatting, Notiz/Notizen plural counts.
  Speech recognition locale remains separately chosen. This does
  NOT imply offline German dictation is available.
- ChickMark: menu already discovers full source catalogues
  dynamically. German is now eligible for selection.

## Verified

- [x] Core localization --audit and --report source parity PASS.
- [x] Python Core localization regressions 37/37 PASS.
- [x] German strings and companion permission/Siri source keys
  and sprintf formats checked.
- [x] XcodeGen regenerated projects.
- [x] Pushkin iOS Simulator unsigned build PASS.
- [x] Uhvat iOS and watchOS Simulator unsigned build PASS.
- [x] ChickMark iOS and watchOS Simulator unsigned build PASS.
- [x] Isolated iOS 27.0 iPhone 17 Pro Simulator: **German iOS UI 3/3 PASS**
  across Pushkin navigation, Uhvat AXXXL home, ChickMark synthetic new habit.
  Each test observed German UI copy and never changed real user data.
- [x] Pushkin Xcode unit CoverageCatalogTests **10/10 PASS** (includes
  explicit DE bundle and count assertions), and German UI test 1/1 PASS.
- [x] Uhvat Xcode unit LanguageFallbackTests **8/8 PASS**, including German
  interface and Notiz/Notizen; German UI 1/1 PASS.
- [x] ChickMark German synthetic-store UI test 1/1 PASS.
- [x] Verified de.lproj resources inside compiled iOS application,
  embedded Watch application, iPhone widget and Watch complication
  bundles; German InfoPlist/AppShortcuts files pass plutil -lint.
- [ ] Real-device / Watch UI and accessibility QA, plus editorial review.
- [ ] Professional proofreading for DE safety/privacy, HealthKit,
  Shortcut permissions and long UX instructions.
- [ ] Real Watch/widget rendering and VoiceOver/AXXXL + device
  integration physical acceptance, non-destructive data upgrade.
- [ ] Explicit owner authorization on each App Store release.

The initial build using a forcibly supplied iphonesimulator SDK
produced unrelated watch target errors. Rebuilding iOS and watchOS
with per-destination SDK selection succeeded. No personal data,
production metadata, signed submission, or public release modified.

## Test triage and reproducibility

An initial Pushkin and Uhvat German UI test failed because the
runtime language resolvers only supported RU/EN/ES/FR. Their runtime
selectors were fixed; both German UI tests then passed on rerun.
The old Uhvat test expected German to fall back to English; after
DE became supported, that expectation was updated to real German,
and all 8 unit tests passed. ChickMark's existing bundled-language
selector worked without code changes.

The QA reports intentionally distinguish real Simulator UI evidence
from Watch/VoiceOver physical device testing. No new App Store
submission or public release occurred. Logs and xcresult bundles
are retained on the Mac mini test evidence volume.
