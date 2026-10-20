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
Remaining Android languages: 47.
