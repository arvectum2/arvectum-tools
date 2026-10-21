# Arvectum Tools — portfolio localization (50 locales)

**Status: target registry and initial extraction/audit, NOT 50 completed translations.**
Four active iOS apps: ChickMark, Pushkin, Ухват, Фото/PDF под размер; the Android version of Фото/PDF is also in scope. Where? is registered but paused.

## Rules

- English must be the default fallback for unsupported system languages. A custom speech-recognition language is a separate setting, never a reason to claim that the interface is translated.
- Do not add language directories that simply copy English. App UI, notices, permissions, widgets, watchOS, notifications, Shortcuts and accessibility all need real translations.
- Format-string parameters, plurals, gender, truncation, RTL layout (ar, fa, he, ur), CJK and Indic scripts and VoiceOver must be checked before publishing.
- Privacy/consent wording requires editorial review. Automated translation alone is not sufficient.
- App Store metadata languages and binary UI languages differ. Apple offers fewer metadata languages than the 50 target UI packs.
- No App Store/TestFlight distribution or listing changes without separate per-release authorization (AGENTS.md).

## The 50 target locale packs

Tier 1 (20): en, ru, es, zh-Hans, zh-Hant, hi, ar, pt-BR, pt-PT, fr, de, ja, ko, id, tr, vi, it, nl, pl, uk.

Tier 2 (20): fa, ur, bn, pa, ta, te, mr, gu, kn, ml, th, ms, fil, sw, ro, hu, cs, sk, el, he.

Tier 3 (10): ha, am, sv, da, fi, nb, bg, sr, hr, ca.

The machine-readable source of truth is `portfolio-locales.json`. Script and regional variations (e.g. zh-Hans vs zh-Hant, pt-BR vs pt-PT) count as distinct UI packs. This is a reach-based product selection, not a claim to the precise top 50 languages by native speaker population.

## Commands

```bash
python3 core/tools/localization_portfolio.py --extract-english
python3 core/tools/localization_portfolio.py --inventory-dynamic > core/localization/dynamic-source-inventory.json
python3 core/tools/localization_portfolio.py --audit
python3 core/tools/localization_portfolio.py --report
python3 core/tools/localization_portfolio.py --export-sources /Volumes/ArvectumSSD/Arvectum/tmp/i18n-sources
python3 -m unittest discover -s core/tests -p 'test_localization_portfolio.py'
```

The English extraction covers **only unambiguous static SwiftUI literals** and non-interpolated `CaptureBrand.text(ru, en)` pairs. Dynamic strings and inline messages need separate conversion to stable localization keys. A complete set of files does not itself prove complete UI translation. Audit checks key and placeholder parity, not translation quality.

## Status — 20 October 2026

| App | Source baseline | Outstanding |
| --- | --- | --- |
| ChickMark | en/ru/es across iPhone, Watch and widgets | 47 languages and real-device QA |
| Фото/PDF | en/ru, corrected English fallback | 48 languages, visual QA |
| Pushkin | extracted English static UI catalog | Dynamic keys, 49 translated catalogs |
| Ухват | extracted English baseline; fixed unsupported-language fallback | Dynamic keys, 49 translations, separate interface and speech choices |
| Фото/PDF Android | EN default + RU and ES draft resources (93 keys per catalog) | Android device/visual QA, 47 more translations, RTL/plurals and permission check |
| Where? | no active app binary | adopt shared registry when resumed |

### Android baseline — 20 October 2026

In integration branch feature/portfolio-design-i18n-20261020, Android Photo Resizer now has an English default resources catalog, a Russian catalog and a Spanish draft (93 keys each). Compose UI, file sizes and typed processing errors use resources. The decimal unit calculation stays JVM-testable.

Verified locally on Mac mini with JDK 17 and SDK 37: assembleDebug and testDebugUnitTest BUILD SUCCESSFUL, plus catalog audit. Spanish is in a machine-linted draft pack, unreviewed on a physical Android device. No other 47 translations or store release has happened.

Next stages for **each app**: finish dynamic string extraction → translate each target locale → review sensitive wording and plural/RTL rules → check permissions, watch/widgets and screenshots → approve individual release. No new locales are claimed as shipped by this change.


## Dynamic interpolation audit (source-only)

The inventory file tracks interpolated SwiftUI and bilingual CaptureBrand
phrases still requiring deliberate formatting/plural/RTL review. It includes
app/file/line and does **not** mark a language pack complete. Generated rows
are not translation entries or proof of complete coverage of computed text,
notifications, Shortcuts, consent, or watchOS. New strings called with
Pushkin's pc() helper are now automatically included in the canonical
English source keys; Russian remains the existing code-based mapping.

Completed runtime microcopy fixes: plural-sensitive note count in Ухват
(RU/EN), and a single format template for Pushkin's numbered group title.
All further languages require actual strings and language-specific QA.


### Spanish Android source pack

The Android values-es/strings.xml contains 93 translated UI and error texts,
with positional placeholders. This is not a linguistic proofreading, device
QA, or store release. Source catalogs now cover EN, RU and draft ES.
Remaining Android languages: 45.


## Native RU source packs across all active iOS apps (20 October)

- ChickMark: existing EN, RU, ES source catalogs across four targets.
- Pushkin: new Russian source catalog with 151 keys (143 reused from
  existing bilingual copy). The runtime copy helper is still retained.
- Ухват: EN/RU catalogs for iPhone (204), Watch (6), Phone Widget (6)
  and Watch Complication (5). New dynamic messages format whole bilingual
  sentences and preserve placeholder types.
- iOS Фото/PDF: EN/RU catalogs have 155 keys, with four full UI metadata
  format templates and correct Russian PDF page-count forms.
- Android Фото: EN/RU/ES/pt-BR/fr development catalogs (93 keys each).
- The integration branch now passes iOS Simulator builds for all 4 apps;
  targeted Photo and What unit tests passed as well.
- These catalog counts and builds are NOT approval for a release or proof
  of native-speaker review, VoiceOver, RTL, Dynamic Type or live services.

When adding further iOS .lproj directories, regenerate the checked-in
Xcode projects from their corresponding project.yml files. The Pushkin
and What projects were regenerated and built with these localizations.
Remaining 45 Android languages and other iOS target languages are pending.

## Next Tier 1 translation slice — Spanish iOS + Brazilian Portuguese Android

- Spanish iOS Photo/PDF has 155 translated Localizable.strings entries,
  plus two Spanish InfoPlist entries including the advertising-tracking
  permission message. The localized catalogs appear in the compiled app
  bundle; the iOS Simulator build succeeds.
- Spanish simulator photo and PDF workflows pass two XCUITest cases,
  including localized processing actions, result and reachable export CTA.
  A real simulator screenshot of the initial ad-consent sheet confirmed
  the entire Spanish disclosure and two buttons fit on screen. Screenshot
  stored alongside QA logs on ArvectumSSD, not in the distributable app.
- The Android photo app now has source packs for EN default, RU, ES,
  pt-BR and fr, 93 strings each. Locale qualifier values-pt-rBR is recognized
  in the compiled APK. pt-BR placeholder type safety and registry
  membership are CI checked; Gradle build and JVM tests pass.
- These are *development language-pack candidates*, not approved store
  releases or proof of native editorial review. 45 Android target
  languages remain not translated. iOS Spanish coverage is currently
  Photo/PDF and the existing ChickMark catalog only; other apps pending.


## Accessibility-size Spanish iOS regression + French Android (21 October)

At the system's maximum AXXXL Dynamic Type, mode titles and six size
presets were cut off as ellipses. The Photo/PDF iOS controls now use:

- a stable two-column/four-item mode grid for accessibility text sizes
  (with full localized VoiceOver labels and equal-height button frames);
- an adaptive two-column size-preset and file-format chip grid, including
  a multiline accessibility-size label path;
- vertically stacked photo/library Files import choices at AXXXL instead
  of two fixed-height half-width controls; the PDF import can grow.
- The compact layout at normal type sizes remains a single row.

The proof is a real es_ES iOS simulator running
accessibility-extra-extra-extra-large; screenshot comparison is stored on
the external SSD. The resulting XCUITest suite now verifies three cases
with a full xcresult **3/3 PASS**: Spanish photo workflow, PDF workflow
and AXXXL mode-grid buttons. The test simulator was reset to its previous
large content size. These are simulator-only checks; physical VoiceOver
and full oversized-type navigation remain open.

Android Photo/PDF has a fifth development catalog, French values-fr
(93 keys), including actual translated error messages and all numeric
format strings. Android assembleDebug and testDebugUnitTest pass;
AAPT2 resource dump confirms French resources in the resulting APK.
Python catalog and fallback suite: 11/11 PASS. A human native-language
review and Android device layout assessment are still needed.


## 21 October: ChickMark locale discovery and Spanish Pushkin

ChickMark iOS discovers only languages with complete Localizable.strings
bundled catalogs (key parity to its EN source). Unsupported/stale
preferences resolve to a bundled system language or EN, and a future
complete language pack no longer needs a Swift picker edit. ChickMark
build and 4/4 targeted localization tests PASS. This does not add
translations beyond the existing EN/RU/ES catalogs.

Pushkin now has a 151-key Spanish catalog in addition to EN/RU. The
pc() runtime uses the Spanish compiled bundle for es and still supports
the Russian dictionary and English fallback. The Spanish count
formats 1 aplicación / 2 aplicaciones. Build and embedded es.lproj
checks PASS, 2 Swift unit tests PASS, and Python 12/12 PASS. A real
Spanish simulator screenshot confirms the History/search/tab labels.
Notification text itself is user data and is never translated by this
UI localization.

The Pushkin Spanish navigation UI XCTest was added but its two test
invocations were interrupted before valid results were written.
These attempts are neither PASS nor assertion failures; retest on
a stable runner. Android French emulator visual review also remains
blocked after remote session shutdowns and a temporary launchd
agent EX_CONFIG. The launch agent was removed.

Native Spanish proofreading, physical VoiceOver, all remaining
translations and per-app release approval are still pending.
