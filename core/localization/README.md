# Arvectum Tools — portfolio localization (50 locales)

**Обновлено 29.10.2026:** 13/50 iOS source languages are now structurally present in all 4 active applications and 10 declared iPhone/Watch/widget bundles (52 app×locale source pairs). Full native-speaker approval, physical QA and public App Store release are separate. The earlier intermediate steps below are historical. See [Core localization + regional ASO roadmap](../docs/CORE_50_LOCALES_AND_REGIONAL_ASO_2026-10-29.md).

## 29.10.2026 · Indonesian в PUSHKIN — второй продукт

- [x] 159 Bahasa Indonesia UI строк, точные идентификаторы действий Shortcuts не переводятся, вручную включаемые автоматизации названы без ложных гарантий. Обновлены `PushkinCopy` и `id-ID`/`id_ID` fallback, plural/counters, Swift test и synthetic UI smoke.
- [ ] Структурный счёт: **54/200 app×locale**, Фото/PDF и PUSHKIN 14, Ухват и ChickMark 13. Индонезийская source-волна для Watch и HealthKit впереди, native-speaker/physical/Apple approval не пройден.

## 29.10.2026 · Bahasa Indonesia (`id`) — начало следующего Tier 1

- [x] Photo/PDF: 161 Bahasa Indonesia UI строк и две системные строки, включая прозрачное разрешение на рекламу и предупреждение о растрировании PDF; source bundle `id.lproj`, native iPhone UI smoke 3 сценария, проверка printf parity.
- [ ] Другие продукты (PUSHKIN, Ухват/Watch, ChickMark/Watch) ещё **без** Indonesian source; это **53/200**, не 14 языков во всех четырёх. Независимая редактура и physical/ASO acceptance не проведены.

## 29.10.2026 · Dutch в ChickMark: все 4 продукта × 13/50 source locales

- [x] `nl` для ChickMark: iPhone 315, Watch 22, iPhone widget 16, Watch widget 5 строк, а также оба HealthKit permission catalog. Locale picker допускает только действительно полный пакет. Тесты проверяют backup/HealthKit/Ухват privacy copy, без каких-либо изменений данных.
- [x] Итоговый source baseline: **52/200** пар app×locale и **13/50** исходных пакетов в каждом из 4 iOS приложений. Следующий Tier 1 `hi, ar, id, tr, vi, pl, th`. Независимая вычитка носителем/VoiceOver/физические Apple Health/Watch и App Store metadata остаются отдельными этапами.

## 29.10.2026 · Dutch для Ухвата/What? — iPhone и Watch/widgets

- [x] `nl` каталоги для всех 4 bundles Ухвата (iOS 246, Watch 6, iPhone widget 6, Watch complication 5) и системные строки; `CaptureBrand` routing и `noteCount` без привязки к настройке распознавания речи.
- [ ] Source матрица: Photo 13, Pushkin 13, Uhvat 13, ChickMark 12 = **51/200**. Dutch ещё не завершён для всего портфеля. Отдельный NL App Store draft и физическая Watch/микрофон/камера QA — не выполнены.

## 29.10.2026 · Dutch в PUSHKIN — source-only второй продукт

- [x] PUSHKIN `nl`: 159 переводов UI и инструкций Shortcuts, полноценный `PushkinCopy` language routing + quantity inflection, XcodeGen resources, native XCTest/XCUITest.
- [ ] Общая матрица: Фото/PDF 13, Pushkin 13, Ухват 12 и ChickMark 12 = **50/200 source app×locale пар**. Dutch ещё не покрывает весь портфель. Отдельные native-speaker, physical-device и App Store выпускные гейты остаются.

## 29.10.2026 · Apple: 50 metadata localizations, не меньший список

Официальная [новость Apple от 31 марта 2026](https://developer.apple.com/news/?id=97t4mt64): поддерживаются 50 вариантов локализации метаданных. Это число совпадает с нашей целью UI=50, но состав и коды различаются. Проверенный пример: UI `nl` и App Store metadata `nl-NL`; для Netherlands Dutch — основной язык ([Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/)). Отдельный Dutch ASO copy draft — в `core/appstore/locale-expansion-2026-10-29/`, без утверждения, что уже опубликован.

## 29.10.2026 · Начало Tier 1: нидерландский только для Фото/PDF

- [x] Новая source-локаль `nl` в Photo/PDF: 161 переведённых UI-ключей и 2 системные строки (в том числе отслеживание/ATT), ключи/форматы совпадают с EN, технические идентичные единицы отдельно классифицированы. XcodeGen включает `nl` в проект; Dutch XCUITest для фото, PDF, Dynamic Type.
- [ ] **Остальные три приложения ещё без `nl`**. Общий счёт: Photo/PDF **13**, остальные **12**, всего **49** app×locale source-пар из будущих 200. Это source draft, не native-speaker sign-off и не опубликованная локаль App Store; нидерландский storefront metadata пока не подготовлен.

## 26.10.2026 · PT-PT и KO native QA

- [x] PT-PT 6/6 UI и KO 4/4 UI PASS в доступных приложениях; Pushkin KO routing fixed и Swift regression PASS.
- [x] 31 EN identical машинный разбор, 0 новых неразобранных текстов, Core 63/63.
- [ ] Корейский в Ухвате/ChickMark, native proofread, физическая Watch/VoiceOver QA и новая подписанная четвёрка RC.

[QA](../docs/IOS_PTPT_KO_NATIVE_QA_2026-10-26.md).


## 26 October 2026 — verified progress

- [x] 11 full-key iOS source locales across 4 apps (including draft pt-PT); KO is partial in two apps.
- [x] Zh-Hant native iPhone Simulator XCUITest **6/6 PASS**; PT-PT corrections, Core **62/62 PASS**.
- [ ] Human editorial sign-off, physical Watch/VoiceOver/privacy QA and GitHub manual CI; new signed device candidates and independent Apple approvals.
- [ ] Remaining Tier 1: KO (2/4), HI, AR, ID, TR, VI, NL, PL, TH. Ukrainian excluded; Thai remains its replacement. Android on hold.

[Report](../docs/IOS_ZH_HANT_NATIVE_QA_2026-10-26.md).


## 25 October 2026 — zh-Hant draft, tenth iOS source locale

- [x] Four active iOS apps/ten iPhone/Watch/widget bundles now have 10 complete-key source catalogs, including preliminary OpenCC s2twp zh-Hant. Script conversion is NOT native editorial validation.
- [x] UI language routing distinguishes zh-Hans/zh-CN from zh-Hant/zh-TW/HK/MO, without changing the independent speech transcription setting.
- [x] Added dedicated zh-Hant Swift and native UI test sources; manual CI workflow now selects 10 languages, retaining its historic filename.
- [ ] Build and actual Simulator/Watch testing; traditional Chinese human proofreading of consent, privacy, Shortcuts, typography and VoiceOver; physical acceptance.
- [ ] Tier 1 remainder: hi, ar, pt-PT, ko, id, tr, vi, nl, pl, th. Android expansion stays deferred.

[Draft evidence](../docs/IOS_ZH_HANT_TIER1_DRAFT_2026-10-25.md).



## 25 October 2026 C5.8 - GitHub on-demand native UI QA

- [x] Manual (not automatically triggered) 4-job Xcode locale UI workflow for all 36 app×language smoke pairs.
- [x] YAML/bash/test-target static verification PASS. Native GitHub run pending.
- [Evidence](../docs/IOS_NINE_LANGUAGE_MANUAL_CI_2026-10-25.md).


## 25 October 2026 - C5.7 source UI matrix
- [x] 36/36 iPhone app x locale pairs covered by native XCUITest source.
- [x] Ten new tests passed 10/10 on iPhone Simulator.
- [ ] Native proofreading and physical Watch/VoiceOver remain blockers.
- [Evidence](../docs/IOS_NINE_LANGUAGE_UI_MATRIX_2026-10-25.md).


## 25 октября 2026 - сквозная регрессия 9 языков

- [x] Проверены все 9 исходных каталогов; Core 52/52, Swift 68/68, переведённые UI 40/40 PASS.
- [x] [Подробный QA-протокол](../docs/IOS_NINE_LANGUAGE_INTEGRATION_2026-10-25.md); сырые XCTest и логи на Mac mini.
- [ ] Реальные устройства и профессиональная языковая редактура остаются до релиза.


## 24 октября 2026 · Девятый язык исходников — ZH-Hans

- [x] Переведены все 10 iOS/Watch/Widget bundles (899 строк), полная девятка языков в исходниках.
- [x] InfoPlist, Siri AppShortcuts, Core locale/printf gate **45/45 PASS**.
- [x] zh-Hans и zh-CN выбирают упрощённый; zh-Hant не подменяется упрощённым.
- [x] Native iOS/watchOS 6/6 builds PASS, Chinese UI 6/6 PASS, Swift 35/35 PASS.
- [ ] Нативная китайская вычитка и физический VoiceOver/Watch QA.
- [ ] Android пока без новых языков.

[QA](../docs/IOS_ZH_HANS_PORTFOLIO_QA_2026-10-24.md).


## 24 октября 2026 — японский JA, исходный язык №8

- [x] JA доступен во всех 10 iOS/Watch/Widget bundles: 899 исходных переводов.
- [x] EN/RU/ES/FR/DE/PT-BR/IT/JA каталоги complete; Core 43/43 PASS.
- [x] JA iOS/watchOS builds 6/6, Japanese UI 6/6 и Swift unit 32/32 PASS.
- [ ] Профессиональная японская редактура и физическая VoiceOver/Watch QA.
- [ ] Android остаётся на 9 языковых каталогах.

[QA](../docs/IOS_JA_PORTFOLIO_QA_2026-10-24.md).


## 24 октября 2026 — итальянский (IT), язык №7 для iOS

- [x] IT во всех 10 активных iOS/Watch/Widget bundles: 899 переведённых строк. Полный набор EN/RU/ES/FR/DE/PT-BR/IT.
- [x] InfoPlist, Apple Health, Siri, runtime it/it-IT, Core source QA 41/41 PASS.
- [x] Шесть iOS/watchOS сборок PASS, итальянский UI 6/6 PASS, Swift language XCTest 29/29 PASS.
- [ ] Нативная редактура и физическая приёмка (Apple Watch, VoiceOver, permissions) открыты.
- [ ] Android остаётся без добавления новых языков.

[Акт](../docs/IOS_IT_PORTFOLIO_QA_2026-10-24.md).


## 24 октября 2026 — pt-BR: шестой язык в исходниках iOS

- [x] RU/EN/ES/FR/DE/PT-BR во всех 10 iOS/Watch/Widget bundles; pt-BR 899 строк.
- [x] Переведены разрешения, Siri-подстановки и региональный pt-BR в коде.
- [x] Core locale QA 39/39 PASS.
- [x] pt-BR Simulator UI 6/6 PASS; шесть iOS/watchOS unsigned builds PASS, все compiled bundles включают pt-BR.lproj.
- [x] Swift XCTest pt-BR: Pushkin 11/11, Ухват 9/9, ChickMark 6/6 PASS.
- [ ] Физический VoiceOver/Watch QA, профессиональная вычитка и отдельное разрешение релиза.
- [ ] Android остаётся на девяти исходных пакетах.

[QA](../docs/IOS_PTBR_PORTFOLIO_QA_2026-10-24.md).


## 24 октября 2026 — исходные DE во всех четырёх iOS-приложениях

- [x] Полные de.lproj source каталоги во всех 10 iOS/Watch/Widget bundles: Фото/PDF 155, Pushkin 151, Ухват 248, ChickMark 345.
- [x] InfoPlist разрешения, Siri AppShortcuts, исправления runtime DE у Pushkin и Ухвата, Core 37/37, iOS/watchOS сборки PASS.
- [x] Немецкие iOS UI smoke: Pushkin/Ухват/ChickMark **3/3 PASS**. Xcode unit Pushkin 10/10 и Uhvat 8/8 PASS.
- [ ] Редакторская вычитка, физическая Watch/UI QA, VoiceOver и разрешение App Store для каждой версии.
- [ ] Android остается на девяти исходных пакетах; дальнейшая iOS волна PT-BR/IT/JA/ZH-Hans.

[Акт](../docs/IOS_DE_PORTFOLIO_QA_2026-10-24.md).


## 24 октября 2026 — пилот немецкого iOS Фото/PDF

- [x] Фото/PDF iOS DE: 155 строк и InfoPlist, 35/35 Core unit PASS, de_DE iOS Simulator UI 3/3 PASS. [Акт](../docs/IOS_GERMAN_PHOTO_QA_2026-10-24.md).
- [x] Исправлено усечение длинного немецкого названия пресета, добавлена UI-регрессия.
- [ ] Остальные три iOS-продукта остаются с четырьмя исходными языками; немецкий для них еще не реализован. Android без новых локалей.

## 24 октября 2026 — проверка первого общего набора

- [x] iOS FR Фото/PDF 155 ключей, FR / ES UI QA по **3/3 PASS** и общий Core locale audit 34/34 PASS. [Акт](../docs/IOS_FIRST_FR_ES_UI_QA_2026-10-24.md).
- [ ] Редактура FR и физическая accessibility QA до релизного разрешения.

## 24 октября 2026 — приоритет iOS перед Android

Решение владельца: приоритет разработки и локализации — **iOS → watchOS → Android**. Наличие 9/50 исходных Android-каталогов у одного приложения — результат прежних этапов, а не подтверждение публикации девяти языков.

- [x] P0: RU/EN/ES/FR для всех четырех активных iOS-приложений, включая Watch/widgets; теперь в source.
- [ ] P0: физическая и редакторская проверка FR, privacy/consent, Dynamic Type и VoiceOver.
- [ ] P1: довести **каждое** активное iOS-приложение до 9 каталогов, добавив DE, PT-BR, IT, JA, ZH-Hans. Только реальные переводы с форматными проверками, не английские заглушки.
- [ ] P2: остальные языки Tier 1 (до 20), Tier 2 (20) и Tier 3 (10) для iOS, с проверкой UI и редактурой.
- [ ] Android: новые 41 языка отложены до следующей iOS-волны; поддержка существующих 9, исправления ошибок, CI и безопасность продолжаются.

Встраивание языковых каталогов в исходники не равно их публикации. Для каждого релиза требуется отдельное согласование.

## 24 октября 2026 — единая первая волна iOS

- [x] Четыре активных iOS-продукта содержат RU/EN/ES/FR source-каталоги: ChickMark (4 bundle), Pushkin (1), Ухват (4), Фото/PDF (1).
- [x] Фото/PDF FR: 155 ключей и InfoPlist для отображаемого имени/рекламного разрешения.
- [x] Добавлена регрессия присутствия RU/EN/ES/FR во всех 10 iOS bundles.
- [ ] Требуется проверка носителем языка, особенно текстов согласия и конфиденциальности.
- [ ] Нужны французские UI/AXXXL/VoiceOver тесты и физическая QA перед публикацией.
- [ ] Приложение не публиковать без отдельного разрешения на новую версию.

Android Фото/PDF: 9 исходных языковых каталогов из 50, это не 9 опубликованных локализаций. Остальные 41 остаются в плане.



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

Tier 1 (20): en, ru, es, zh-Hans, zh-Hant, hi, ar, pt-BR, pt-PT, fr, de, ja, ko, id, tr, vi, it, nl, pl, th.

Tier 2 (20): fa, ur, bn, pa, ta, te, mr, gu, kn, ml, uz, ms, fil, sw, ro, hu, cs, sk, el, he.

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
| Фото/PDF Android | EN + RU/ES/pt-BR/FR/DE development catalogs (93 keys each) | Android device/visual QA, 44 more translations, RTL/plurals and permission check |
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
Remaining Android languages: 44.


## Native RU source packs across all active iOS apps (20 October)

- ChickMark: existing EN, RU, ES source catalogs across four targets.
- Pushkin: new Russian source catalog with 151 keys (143 reused from
  existing bilingual copy). The runtime copy helper is still retained.
- Ухват: EN/RU catalogs for iPhone (204), Watch (6), Phone Widget (6)
  and Watch Complication (5). New dynamic messages format whole bilingual
  sentences and preserve placeholder types.
- iOS Фото/PDF: EN/RU catalogs have 155 keys, with four full UI metadata
  format templates and correct Russian PDF page-count forms.
- Android Фото: EN/RU/ES/pt-BR/fr/de development catalogs (93 keys each).
- The integration branch now passes iOS Simulator builds for all 4 apps;
  targeted Photo and What unit tests passed as well.
- These catalog counts and builds are NOT approval for a release or proof
  of native-speaker review, VoiceOver, RTL, Dynamic Type or live services.

When adding further iOS .lproj directories, regenerate the checked-in
Xcode projects from their corresponding project.yml files. The Pushkin
and What projects were regenerated and built with these localizations.
Remaining 44 Android languages and other iOS target languages are pending.

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
  releases or proof of native editorial review. 44 Android target
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


## 21 October: UhWhat? Spanish runtime + accessibility UI QA

The third supported language now has actual translations in every
What target: iPhone 213 strings, Watch 6, iPhone Widget 6, and Watch
Complication 5 (230 Spanish keys total). Speech selection es-ES drives
Spanish user-facing UI and formatted text (0 notas, 1 nota, 2 notas).
Unsupported system languages still fall back to English.

Real Spanish simulator screenshots revealed four English phrases and
VoiceOver labels remaining in the home screen from a legacy direct
RU/EN conditional. Nine uncataloged English phrases were added and
translated in all RU/EN/ES iPhone resources. The home now says
Captura esa idea, Toca para grabar audio, Todas las notas and 0 notas.
This highlights source-scanner limitations beyond direct calls.

At accessibility5, the Texto action split a word and the Video button
grew excessively. The compact action typography now has a bounded
accessibility size, without shrinking the main content. Simulator
screenshots show the issue and its correction, and system font size
was restored to large. A debug-only fixture tests the actual AXXXL
layout without touching recordings or permissions.

Xcode build with all ES/watchOS bundles PASS, LanguageFallbackTests
5/5 PASS, UI home and forced accessibility5 tests 2/2 PASS, Python
localization suite 13/13 PASS. Spanish proofreading, full physical
VoiceOver, microphone/Watch synchronization and releases remain open.


## Current addendum, 21 October — German Android and direct-language source audit

Android photo-resizer now has six complete development locale packs:
EN (default), RU, ES, pt-BR, FR and DE, each with 93 resource keys.
German values-de includes translated controls, errors, image/file units,
numbered format placeholders and Gosuslugi context. An AAPT2 dump
verifies German resources are in the compiled APK. Offline Gradle
assembleDebug and testDebugUnitTest BUILD SUCCESSFUL (6/6 existing
JVM tests, 0 failures, up-to-date target). 44 of 50 Android target
languages remain untranslated. Human proofreading and live device
French/German accessibility/layout QA are not yet done.

The source-risk inventory now catches plain Russian/English Boolean
ternaries and explicit locale comparisons: the kind of shortcut that
left the original Spanish What capture screen partially in English.
It excludes only the consciously bilingual UhWhat?/Ухват brand identity.
The regression suite is now Python 16/16 PASS. This is a best-effort
static heuristic, not complete source/translation coverage.

Standalone Pushkin Spanish UI test-without-building hung during Xcode
runner orchestration on a separate simulator. The test process was
terminated without valid result, so its XCUITest PASS remains open.
No Android emulator visual test completed during this iteration.

## QA addendum — 21 October, 09:45 (Italian Android and Pushkin Spanish)

- Android Photo/PDF now contains seven real development resource packs:
  EN fallback, RU, ES, pt-BR, FR, DE and IT. The Italian package has
  93 translated strings with positional parameters preserved. Android
  assembleDebug and testDebugUnitTest succeeded (6 JVM tests), and
  AAPT2 confirmed Italian values in the APK. Python localization tests
  pass 17/17. A native-language review and device visual QA are open.
  43 planned Android locales remain unimplemented.
- Pushkin Spanish navigation XCUITest is now PASS 1/1, confirmed by
  the 09:45 Xcode xcresult. The two previous failed tests checked
  incorrect UI expectations: the selected History tab was treated as
  hittable, and the tab label 'Aplicaciones' was mistaken for the
  distinct destination title 'Aplicaciones y configuración'.
  The test now exercises both navigation transitions and the actual
  translated titles. Simulator success is not physical VoiceOver QA.
- No remote pushes, main merge, App Store changes or releases.

## 21 October follow-up — Dutch and Polish Android

The Android Photo/PDF app now has 9 authentic development catalogs:
EN fallback, RU, ES, pt-BR, FR, DE, IT, NL and PL. Both new packs
include 93 natural-language translations, all numeric format
arguments, errors, privacy and document-photo disclosures.
Android Gradle assembleDebug and testDebugUnitTest succeeded,
6/6 existing JVM tests; AAPT2 confirms NL/PL values in the
assembled APK. The Python structure and placeholder parity
suite now passes 19/19. There are 41 still-untranslated
Android targets. Native-language review and device QA are
required before any production release.

An Android 16 small_phone emulator did boot with
sys.boot_completed=1 and adb install -r of the debug APK
returned Success. The remote control link dropped *before*
the intended app locale change or screenshot, and the emulator
did not remain available. Therefore FR/NL/PL Android visual QA
is still open. No screenshot, in-app language switch, on-device
accessibility or real Android text-size fitting is claimed.
All work stays in the feature branch, without store actions.


## Android visual QA and responsive-mode fix (21 October)

Android 16 small_phone emulator finally provided real screenshot evidence
at 720x1280 for FR, NL and PL. French and Polish first-run photo-selection
screens have complete visible labels. Dutch revealed a real defect:
the word Bestandsgrootte broke across lines in three equal-width tabs.

Android Photo/PDF now uses actual Compose TextMeasurer metrics to choose
a three-, two-, or one-column mode layout. Each mode keeps its full
translated label and tab selection semantics for enlarged fonts.
Selection and result views scroll within the available viewport;
the purely decorative footer is hidden when system fontScale >= 1.3.
At 160% the original screen clipped the bottom of the file-picker
action. Afterwards the whole Foto kiezen CTA is visible, and a
swipe exposes the on-device privacy notice.

QA screenshots on external SSD:
- android-fr-visual-20261021.png: French normal initial screen
- android-nl-normal-20261021.png: Dutch before word-split bug
- android-nl-adaptive-20261021.png: Dutch after 2-column fix
- android-pl-adaptive-20261021.png: Polish after layout fix
- android-nl-adaptive-font160-20261021.png: original 160% clipping
- android-nl-font160-scroll-top-20261021.png: repaired 160% CTA
- android-nl-font160-scroll-bottom-20261021.png: privacy after scroll

Android assembleDebug and testDebugUnitTest PASS, 9/9 JVM after three
new deterministic 3/2/1-column unit tests. Localization audit PASS.
The representative initial-screen smoke is not full accessibility
or end-to-end QA: document processing, RTL, TalkBack, all text sizes,
and physical device test matrix still require review.


## French Pushkin — development bundle and UX smoke (21 October)

Pushkin now ships EN, RU, ES and FR source localizations in the
feature branch (151 string keys each). Added authored French UI copy
for all extracted source keys, including Shortcuts-based setup
disclosures, privacy and troubleshooting; printf format specifiers
remain in parity with the English source. The runtime PushkinCopy
loader reads its built fr.lproj bundle and leaves the old Russian
dictionary and Spanish behavior unchanged. Single/plural French
counts read as 1 application and 2 applications.

After XcodeGen regeneration, iOS simulator Debug build PASS.
Focused French native Xcode test PASS. The French UI smoke navigates
Historique -> Apps et configuration -> Réglages and confirms translated
tabs in a simulator. Xcode result at 15:15, 1/1 PASS with zero failures.
Python localization tests now 20/20 PASS.

This is a development draft, not a native-language editing signoff.
Physical VoiceOver, larger Dynamic Type, live Shortcuts integrations
and release approval remain pending. No release or main merge.

## 21 October: complete French ChickMark across all four targets

ChickMark's French development catalog is complete on all bundled
targets: iPhone 302 keys, Apple Watch 22, iPhone Widget 16,
Watch complication 5. The iPhone and Watch Health permission prompts
also have real French InfoPlist.strings (2 keys in each).
The existing automatic, completeness-gated language picker discovers
French without hardcoding a new choice; system/app language fallback
remains English when no catalog exists.

The translation is a human-authored draft, with every key and format
placeholder matching the English source. To avoid incorrect singular
forms for count-only templates (for example 1 jours, 1 semaines),
French uses neutral unit labels and templates where necessary.
These are UX copy choices, not proof of native-language editing.

The iOS simulator Debug scheme build succeeded including watch and both
widget extensions; all four products' embedded fr.lproj files were
verified in the generated app. ChickMark localization unit tests 5/5
and French empty-state/new-habit UI XCUITest 1/1 pass; the UI test uses
a synthetic store with Cloud sync disabled. The shared Python
localization regression suite now passes 21/21.

Physical VoiceOver, actual watch hardware, more screens, editorial
review and each individual release approval remain open. No changes
were merged or published.


## 21 October Android production image-engine proof (separate from picker UX)

A debug-only, DUMP-permission guarded BroadcastReceiver now runs real
production ImageStorage and CompressionEngine methods on a deterministic
synthetic 900x700 RGB PNG. No gallery/real user data are read. Three
image operations and saves to app-local JPEGs completed successfully on
Android 16 Emulator: 2,199,482-byte PNG compressed to 479,009-byte
JPEG under a 500,000-byte cap; image resized to 400x311 pixels; and
passport image produced at 620x797 with verified 450 DPI EXIF. Three
saved JPEGs were re-opened and checked for expected pixel dimensions
and sizes. Machine-readable run result is in the external QA directory:
android-pipeline-qa-result-final.json, status passed, savedOutputs=3.

The special receiver is in app/src/debug ONLY, restricted with Android
permission DUMP, and absent from the merged Release AndroidManifest.xml
(processReleaseMainManifest PASS). Debug APK and existing 9 JVM tests
build/pass offline. New Python structural tests guard debug/release
isolation and the actual QA method usage; combined Python suite 24/24
PASS. A standalone script in photo-pdf-to-size/android/tools/
qa_image_pipeline_emulator.sh was added to rerun the same test on a
stable host: its syntax is verified but its first invoked run lost the
RDC connection before producing a new result. That interrupted run
is not marked successful. The earlier direct command with the same
Debug receiver produced the valid PASS report.

Scope limit: this is production image-processing AND local file-save
engine coverage, not a successful tap through Android's Photo Picker or
system SaveDocument UI. Full media picker to result to export UX,
TalkBack and physical device matrix still need QA.


## Android actual Photo Picker partial GUI QA (21 October)

The Android system Photo Picker really opened; topResumedActivity
identified com.google.android.photopicker. A screenshot showed the
generated synthetic PNG tile. Tapping it then Done returned to
the production Compose interface, which displayed 900x700 pixels,
1.84 MB. Switching to 500 KB displayed the PNG-to-JPG notice and
Compress to 500 KB action, which was tapped. RDC disconnected before
the result or SaveDocument UI could be confirmed.

Evidence on ArvectumSSD in portfolio-design-i18n-qa-20261020:
android-picker-20261021-diagnostic.png, android-e2e-imported-preview.png,
android-photo-e2e-preset.png, android-photo-e2e-selected.xml,
android-photo-e2e-preset.xml, android-picker-selection-to-save-20261021.log.

The independently repeatable full GUI runner now lives at
photo-pdf-to-size/android/tools/qa_photo_picker_emulator.sh and
qa_photo_picker_e2e.py. It only generates a synthetic image, never reads
private photos, refuses to replace a running emulator, and refuses
test outputs outside ArvectumSSD. It drives actual system Photo Picker
and SaveDocument controls and validates an exported JPEG <=500000 bytes
before reporting status=passed. Structural tests pass; its actual
complete E2E run does NOT yet pass due RDC interruptions. A launchctl
attempt exited EX_CONFIG 78 and its stale job was removed.

## Android end-to-end completed, export filename localized — 21 Oct 17:00

Full production Android16 UI E2E PASSED after using a detached tmux
terminal session instead of tying emulator lifetime to RDC. On a
disposable emulator, generated 900x700 PNG → actual Google Photo Picker
→ selected image → Compose 500 KB compression → actual result screen →
Android SaveDocument in Downloads → exported JPEG read back on Mac.
7 of 7 stages complete in machine report status=passed, output
479169 bytes, valid 900x700 JPEG. Evidence/screenshots preserved on
the external SSD under:
portfolio-design-i18n-qa-20261020/tmux-photo-picker-qa.

The successful first pass also discovered a real localization bug:
the EN application exported a Russian-suffixed name. Replaced
hardcoded Russian suffixes in MainViewModel with Android resources,
adding values*/export_filenames.xml in all 9 shipping development
language folders (3 extra strings per locale; now 96 keys each).
Localized-source audit was updated to read both resource XMLs.
The 500 KB test passed a SECOND time with the rebuilt package:
7/7 completed, 479169-byte JPEG, correct file name
19-compressed.jpg, from system SaveDocument and confirmed in Downloads.
Second report/screenshots: tmux-photo-picker-localized-qa2.

Android Gradle assembleDebug + testDebugUnitTest PASS, 9/9 JVM;
29/29 Python localization and structural regressions PASS. The two
Android GUI passes are real proof for this one synthetic PNG and mode,
not for all real-world file formats, all three modes, TalkBack,
physical Android devices, all screen sizes or linguist signoff.
Nothing was published or merged to main.

## What/Uhvat UI locale decoupled from speech locale — 21 Oct 17:15

The iPhone/Watch voice inbox previously used its selected dictation
language RU/EN/ES to switch the entire UI. A user with Spanish system
language who wanted English speech was unexpectedly switched to English
interface labels. CaptureBrand now resolves the visual language from
iOS preferred app/system languages, independently of the persisted
what.transcription.locale SpeechRecognizer setting. EN fallback applies
for unsupported visual locales, preserving the three existing
transcription locales and the original recordings.

The library settings language picker now says "Speech recognition
language" and separately links to the iOS app Settings for interface
language. Today/Yesterday/Earlier inbox group headings are translated
in RU/EN/ES (Hoy/Ayer/Anteriores in Spanish); the prior isRussian
special case that left ES day headings in English is removed. iPhone
localization catalogs now contain 217 keys each; the Watch/PhoneWidget
and Watch complication source bundles are unchanged.

After this change, iOS Xcode simulated build/test succeeded:
10/10 focused Swift unit + XCUITest checks, including Spanish UI with
English dictation and Russian UI with English dictation. The actual
xcresult and screenshots are in isolated-what-v2/Logs/Test on
ArvectumSSD. Shared Python localization/QA suite passes 30/30.

Migration/UX risk: existing users who previously selected a speech
language primarily to change the interface will now see their iOS app
language instead. This should be reviewed and explained before a
per-release owner approval, and physically validated on iPhone/Watch.
No recording repository or audio data migrated or deleted; no release.


## 21 October 17:49 — live What/Uhvat screens: diagnostics and iPad AX

Follow-up QA to separate iOS interface language from SpeechRecognizer:
previous SyncDiagnosticsLocalizationUITests still asserted the legacy
combined-language behavior. Updated it to use iOS per-app language
for diagnostics, Russian speech-language menu labels for in-UI
selection, and to assert the visible Russian interface survives
choosing English transcription and relaunch. Expanded the actual
diagnostics view checks from RU/EN to RU/EN/ES. XCResult
Test-WhatIOS-2026.10.21_17-46-28-+0300.xcresult: 10/10 passed.

A second isolated iPad simulator (device 3484211E-7501-4BF0-9F19-
BC933521F024) exercised the Spanish populated notes library with
accessibility5 (AXXXL) typography and English dictation. It checked
translated Spanish filters, the Hoy day group, 44pt+ settings target,
and Apple system accessibility audit covering descriptions, hit
regions, traits and text clipping. Uses debug-only metadata fixture:
no existing notes, microphones or iCloud modified. XCResult
Test-WhatIOS-2026.10.21_17-49-08-+0300.xcresult: 1/1 passed with
retained screenshot attachment.
Combined core Python tests: 31/31 pass.

A separate SmartSearchView source scan revealed some dynamic
English-only strings, but it has no call site outside its own
declaration: that experimental view is not currently reachable from
shipping navigation. Localization/UX QA for it remains a distinct
pre-enablement item, not a purported current-screen bugfix.

Open gates: on-device VoiceOver and real iPad/iPhone, all screen
combinations and editorial review; no main merge or release.


## 21 October — Spanish accessibility-size text editor and settings

A real UI test found a genuine usability problem in What/Uhvat:
UIKit constrained the navigation Done action to 36 pt at AXXXL,
below the project acceptance target of 44 pt. Adding a frame inside
the ToolbarItem did not resolve it. On subsequent iPhone QA it again
measured 36 pt, confirming toolbar clipping.

Fixed the production TextNoteSheet: at system accessibility Dynamic
Type sizes, the localized Done action moves into a bottom safe-area
action bar (minWidth 88, minHeight 52) above the keyboard, with
stable what.text.done identifier. At normal text size the usual
navigation toolbar action remains. The QA launch now sets the
*system-wide* UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge:
a prior debug-only accessibility5 environment on ContentView did not
propagate into the modal sheet, which explains earlier false AXXXL
coverage.

Actual passing simulator proof:
- iPhone 17 Pro ES AXXXL empty editor: 1/1 PASS,
  Test-WhatIOS-2026.10.21_18-30-44-+0300.xcresult.
- Independent iPad ES editor + speech Settings menu: 2/2 PASS,
  Test-WhatIOS-2026.10.21_18-31-37-+0300.xcresult.
The tests avoid writing any note or changing dictation preferences.
Editor QA confirms Spanish VoiceOver label, hit area >=44 pt, closing
without saving a blank note; settings QA confirms translated controls.
The previous full four-category Apple accessibility audit of the
synthetic Spanish library remains separately passed.

Python regression suite 32/32 PASS, localization audit PASS.
Ordinary-size iPhone capture/text editor regression also PASSED 1/1,
Test-WhatIOS-2026.10.21_18-33-04-+0300.xcresult. Physical
VoiceOver and device matrix are still open; no release/main merge.


## 21 October 19:03 — What/Uhvat video accessibility without camera

At AXXXL, UIKit constrained the navigation Discard button to 36pt.
VideoRecordingSheet now moves Discard to a bottom safe-area action
(minimum 88x52pt) for accessibility Dynamic Type and reduces preview
height to 38% of available space to prioritize controls. Normal
type retains the original top-bar action. Camera-switch remains a
labelled 52x52pt button and Stop now has a stable test identifier.

Debug-only simulator QA flags disable real AVFoundation startup and
capture journal initialization. The accessibility test fixture now
also sets the large text environment for the whole ContentView;
otherwise the modal video sheet would receive normal Dynamic Type.
A second no-camera flag checks default text sizes without creating
recordings or touching a user microphone/camera. No QA-only behavior
exists in Release.

Actual Xcode Simulator XCResults, all PASS:
- iPhone ES AXXXL: Test-WhatIOS-2026.10.21_19-00-20-+0300.xcresult 1/1.
- iPad ES AXXXL: Test-WhatIOS-2026.10.21_19-01-39-+0300.xcresult 1/1.
- iPhone ES normal: Test-WhatIOS-2026.10.21_19-02-53-+0300.xcresult 1/1.
Checks include localized title/labels, 44pt+ controls at large type,
Stop disabled in QA-only no-recording mode, and safe cancellation.
Initial pre-fix 36pt failure is retained in earlier XCResult.
Core Python localization/structural checks: 33/33 PASS.

No physical video capture, camera switching or VoiceOver signoff
has been inferred from simulator UI tests. No merge or publication.


## 21 October 19:09 — audio-capture accessibility-size controls (no mic)

What/Uhvat PhoneRecordingSheet's top-bar Close/Discard used the same
UIKit-constrained navigation toolbar as the text and video sheets.
It now shows a bottom safeAreaInset action, minimum 88x52pt, in
accessibility Dynamic Type. At regular type size it retains the
normal toolbar. Both Start and Stop are accessible through stable
IDs what.audio.start/stop and a 52pt minimum height.

DEBUG-only command-line flags allow viewing the real SwiftUI audio
sheet without ever starting the PhoneRecordingController microphone,
requesting permission, saving audio, or creating a capture journal.
The Start control is disabled in this QA-only condition so a test
cannot accidentally turn on the microphone. A separate normal-size
fixture tests preserved toolbar behavior. The AXXXL fixture is
scoped to the DEBUG application entry point; Release has no QA mode.

Confirmed genuine XCUITest results:
- iPhone Spanish AXXXL plus normal type:
  Test-WhatIOS-2026.10.21_19-07-18-+0300.xcresult, 2/2 PASS.
- iPad Spanish AXXXL:
  Test-WhatIOS-2026.10.21_19-08-15-+0300.xcresult, 1/1 PASS.
Checks: localized Voice note, New recording, Start recording,
Close labels; hit targets at AXXXL, microphone action disabled,
no permission alert, safe close to capture home. Combined Python
locale/security regression suite 34/34 PASS and localization
structure/placeholder audit PASS.

Simulator visual checks are not proof of physical microphone
recording, real permissions, saved audio or VoiceOver on devices;
these remain separate release QA. No merge or store publishing.


## 21 October 19:38 — What/Uhvat transcript editor Dynamic Type

The live transcript editor's native Cancel and Save toolbar buttons
were constrained by UIKit at accessibility text sizes. Production
TranscriptEditorSheet now renders fully tappable bottom safe-area
controls (minimum 88x52 pt each) when Dynamic Type is an
accessibility category; regular-size navigation actions are retained.
Both actions and TextEditor gained stable accessibility identifiers.

To QA without touching personal notes, a #if DEBUG-only screen uses
a synthetic RecordingEnvelope and test string with a no-op save
closure. It bypasses the real recording repository and media, and
is inaccessible from the production Release app. Separate fixtures
render AXXXL and medium text sizes.

Real iOS Simulator Xcode test evidence:
- iPhone ES AXXXL + medium: Test-WhatIOS-2026.10.21_19-33-51-+0300.xcresult,
  2/2 PASS (editor/transcript labels, 44+ pt actions, Cancel, disabled Save).
- iPad ES AXXXL: Test-WhatIOS-2026.10.21_19-35-55-+0300.xcresult, 1/1 PASS.
- iPhone ES edited synthetic draft: Test-WhatIOS-2026.10.21_19-37-35-+0300.xcresult,
  1/1 PASS (Save enables on edit and dismisses; no actual persistence).
Shared Python localization/security tests 35/35 PASS, format/catalog
audit PASS. These do NOT substitute for physical VoiceOver or real
error/recovery/persistence acceptance with user-provided transcripts.
No TestFlight, App Store or main merge.

## 21 October 21:03 — transcript catalog fail-closed writes and recovery

Data-loss path identified in RecordingRepository: loadTranscripts()
returns an empty dictionary on corrupt/unreadable transcripts.json
for display. Previously saveTranscript and updateTranscript reused
that empty dictionary for an atomic overwrite, potentially erasing
unrelated transcripts. Both write methods now call strict
loadTranscriptsForMutation(), which rejects a present but corrupt or
unreadable JSON catalog, throwing transcriptStoreUnreadable. The
existing file bytes and original audio remain intact. A missing
catalog can correctly begin empty; no automatic repair is attempted.

A localized EN/RU/ES error message is included; the What iPhone
catalogs now have 218 key-complete strings each. The existing editor
preserves its draft on callback failure and displays the error. An
isolated DEBUG-only synthetic save-failure callback and Spanish
XCUITest verified the correct localized alert, Aceptar action and
retained draft without writing any personal notes.

Five repository XCTest checks use disposable unique temporary roots:
normal edit/reopen and unaffected other notes/audio; empty,
unknown and deleted note guards; corrupt JSON preserved on both
manual and speech writes; unreadable catalog path preserved; and
correction after known-good backup restoration without losing other
transcripts or original audio.

Verified iOS 27 simulator:
Test-WhatIOS-2026.10.21_21-01-51-+0300.xcresult,
58 passed, 3 skipped, 0 failed (61 total).
Python regression 36/36 PASS, localization/format audit PASS.
Read-only display still falls back to empty if corrupt; writes are
blocked until a trusted repair. No automatic backup/recovery is
claimed. Physical iPhone/Watch, crash/power-loss fault injection and
real device VoiceOver remain open; no release or main merge.

## 21 October 21:36 — transcript shadow copy and explicit safe recovery

RecordingRepository now persists a shadow catalog alongside main
transcripts.json under transcripts.backup.json. Each save, edit and
deleted-transcript cleanup writes a complete encoded catalog to
the backup using an atomic replacement BEFORE atomically replacing
the primary. Both files use the existing repository storage lock.
Backup-write failure preserves the valid original primary.
If the primary update is interrupted, an explicit recovery path
can use the shadow.

Deletion cleanup now calls strict loadTranscriptsForMutation instead
of forgiving loadTranscripts. No automatic empty-dictionary overwrite
of a corrupt main catalog is allowed. Durable deletion tombstones
remain authoritative, even when cleanup is interrupted. The internal
restoreTranscriptCatalogFromBackup method refuses to replace a
readable or missing primary, validates the complete shadow catalog,
filters tombstoned IDs before restoration, and completes any pending
index/audio deletion cleanup. It is an explicit internal operation,
NOT a startup automatic recovery or shipping user interface.

Seven new XCTest checks use disposable synthetic temporary roots:
backup matches the latest saved/edited catalog with audio intact;
corrupt main explicitly restores all surviving texts; corrupted or
missing backup cannot overwrite main bytes; failed backup writes
preserve the primary; deletion cleans BOTH catalogs; interrupted
deletion of a damaged main does not resurrect a tombstoned ID and
finishes deferred audio cleanup on explicit restore.

Xcode evidence: Test-WhatIOS-2026.10.21_21-35-29-+0300.xcresult
65 passed / 3 skipped / 0 failed (68 total), iOS 27 iPhone simulator.
Core Python regression 37/37 PASS; localization audit PASS.

Atomic replacement is not proof of physical power-loss durability.
There is no recovery UI or automatic backup repair. The shadow
contains sensitive transcripts in the app sandbox and its file
protection needs release review. Physical storage fault-injection,
VoiceOver, and Watch/phone integration remain release gates.
No main merge, push, TestFlight or App Store upload.


## 21 October 23:02 — What/Uhvat recovery UI, localization and outstanding gates

Added a user-visible Transcript Recovery screen accessible from the
library settings menu, with EN/RU/ES copy (228 iPhone keys each).
The screen reads only a status/number; it does not display recovered
transcript text or begin recovery on appear. It distinguishes healthy
or absent main catalog (no recovery needed), corrupt main with
missing/invalid/empty backup (unavailable), and corrupt main with a
nonempty valid backup (number of recoverable entries). Durable
deletion tombstones are filtered from counts and restored data.
The Restore button appears only for the last case and requires
an additional destructive confirmation with warning about possible
lost recent edits. SwiftUI uses a full-size 52pt bottom Done target.

PhoneStore delegates the explicit operation to RecordingRepository
and refreshes published transcript data after a successful restore.
No automatic startup restore was added. DEBUG-only UI fixture creates
two entirely synthetic transcripts in an isolated temporary root
then corrupts only its disposable main JSON. Real personal notes,
audio, and Watch sync data are never touched by QA fixture.

Unit tests verify safe read-only status, healthy/missing primary,
empty/absent backup, and successful explicit recovery. The Spanish
XCUITest confirms the AXXXL preview and full-size action without
invoking destructive restoration. Xcode Simulator:
Test-WhatIOS-2026.10.21_23-01-45-+0300.xcresult:
67 passed, 3 skipped, 0 failed. Python 38/38 PASS, i18n audit PASS.

Known blocker: the separate attempt to automate the native iOS
destructive confirmation dialog timed out, after an earlier test
failed to locate the system-rendered action by custom identifier.
Do NOT claim the full confirmation-to-restored-library UI is tested.
It requires targeted real-device/iPad VoiceOver/normal UX acceptance
and recovery failure injection. File protection and power-loss
atomicity are also open. No merge, push, TestFlight or publication.

## 21 October 23:26 — Uhvat transcript file protection, L4.18a

New transcript main, shadow backup and durable deletion-ledger JSON
files are written as protected atomic replacements, using
completeFileProtectionUntilFirstUserAuthentication.
Legacy files are upgraded without rewriting their contents; if
migration fails, later transcript writes are blocked.
This class preserves background Watch processing after first unlock.

Test-WhatIOS-2026.10.21_23-24-48-+0300.xcresult:
67 PASS, 6 SKIP, 0 FAIL. Three new skips concern NSFileProtectionKey:
iOS Simulator omits that hardware attribute. Three other skips
were preexisting. Debug iOS build and Python 39/39 PASS; locale audit
PASS. macOS Foundation smoke returned the desired protection type,
but only a physical iPhone can validate device encryption.

Outstanding: real iPhone attributes and legacy migration, behavior
before first unlock, Watch background delivery, media/index
protection, backup policy and power-loss fault injection.
No release, main merge or TestFlight.

## 21 October 23:57 — L4.19a simulated interrupted transcript commits

Three synchronous, nil-by-default DEBUG-only checkpoints were added
to persistTranscripts: before backup, after backup, after primary.
Release builds do not contain these hooks; only synthetic temporary
repositories are affected by the test faults. Original audio is
never rewritten by transcript corrections.

Five added XCTest scenarios verify:
- Interruption before shadow write preserves BOTH committed files.
- Interruption after shadow write leaves primary authoritative and
  readable even if backup contains an uncommitted edit; the next
  successful write reconciles the two files without erasing another
  transcript. No automatic rollback of healthy primary is permitted.
- Interruption after primary write means the edit may already be
  committed even if an error was returned; retrying is idempotent.
- Interrupted automatic speech save can be safely retried and does
  not overwrite another human-edited transcript.
- Interrupted deletion at either pre/post shadow checkpoint is
  completed after repository restart, with tombstones preventing
  late Watch transfers from resurrecting deleted recordings.

Verified Xcode Simulator:
Test-WhatIOS-2026.10.21_23-56-45-+0300.xcresult:
72 PASS, 6 SKIP, 0 FAIL, 78 total (existing hardware-related
simulator skips retained). Python 40/40 PASS, locale audit PASS.
The focused Spanish save-failure UI test was included.

This is deterministic error injection, NOT SIGKILL between write
syscalls and NOT actual power-loss or storage-full testing.
Those remain L4.19b release blockers. No main merge, release, or push.

### European Portuguese work-in-progress (2026-10-25)

`photo-pdf-to-size/ios/PhotoPodRazmer/Resources/pt-PT.lproj` now contains a first regional draft derived from the existing pt-BR catalog (Localizable and InfoPlist). This is **not** a proofread, shipped, or portfolio-complete locale. Do not add `pt-PT` to the app's `sourceCatalogs` until a native-speaker review, permission/consent review, XCUITest, and all four app bundles are complete. The manifest continues to track `pt-PT` as Tier 1 remaining.

Update: `pt-PT` draft resources now cover 18 `.strings` files across all four active iOS/Watch/widget products. Source-key parity is tested, and the regional locale routing is implemented in Pushkin and Uhvat. Native editorial review, permissions/consent QA, device UI tests, and App Store readiness are still outstanding. Do not count `pt-PT` as a released or editorially accepted source pack.

### pt-PT simulator build checkpoint (2026-10-25)

XcodeGen project regeneration succeeded for Photo, Pushkin, What and ChickMark. Generic iOS Simulator builds succeeded for all four app schemes. WhatIOS `LanguageFallbackTests` and Pushkin `CoverageCatalogTests` passed on the iOS 27.0 simulator. ChickMark `LocalizationTests` first run was interrupted by Xcode; the retry with parallel testing disabled passed. `pt-PT` remains a **draft** pending independent European Portuguese editorial review and visual/accessibility testing; do not ship or claim full native QA.

### Korean `ko` first source pack (draft)

`photo-pdf-to-size/ios/PhotoPodRazmer/Resources/ko.lproj` contains a full-key Korean draft for the Photo/PDF app (including consent and InfoPlist strings). Untranslated strings are measurement tokens and positional formatting templates. The pack is **not** registered for release; Korean copy, policy text and native iOS QA require independent review. Pushkin, What and ChickMark Korean packs are not yet translated.

Korean Photo/PDF generic iOS Simulator build PASS after retry using existing derived data (first fresh-build invocation was interrupted by Xcode). 58/58 Core tests PASS; both Korean `.strings` files pass `plutil -lint`. These checks do not substitute for native UI tests or Korean editorial acceptance.

### Korean PUSHKIN source pack (draft)

All 151 extracted English source entries now have Korean draft translations at `pushkin/ios/ArvectumNotify/Resources/ko.lproj/Localizable.strings`; placeholder/key parity and no-English-source fallback are tested. `PushkinCopy` now resolves the Korean resource bundle. This is not an editorial sign-off or permission to publish: Shortcuts instructions, legal/privacy copy, dynamic strings and simulator UI require review.
