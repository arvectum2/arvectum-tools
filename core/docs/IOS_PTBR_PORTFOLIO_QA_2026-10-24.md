# C5.3 — Brazilian Portuguese (pt-BR) iOS-first source localization
Date: 24 October 2026.

## Scope / evidence boundary
The sixth catalog, pt-BR, is authored with full translated source strings for all
10 active iOS/watchOS/widgets bundles. This is NOT an App Store release or
editorial/native quality approval.

| Product | iPhone | Watch | Phone widget | Watch complication/widget |
| --- | ---: | ---: | ---: | ---: |
| Photo/PDF | 155 | - | - | - |
| PUSHKIN | 151 | - | - | - |
| Uhvat/What? | 231 | 6 | 6 | 5 |
| ChickMark | 302 | 22 | 16 | 5 |

Total **899 pt-BR Localizable.strings entries**. Previously there were
EN/RU/ES/FR and then DE. This branch follows stacked draft PRs
#141 -> #142 -> #143. Android language count is unchanged.

## Technical and safety scope
- Photo/PDF advertising consent, privacy, metadata and file-processing
  copy localized; regional advertising/legal review required.
- Pushkin Shortcuts onboarding instructions localized, unchanged Shortcut
  identifiers and unchanged user notification content.
- Uhvat Watch, widgets, camera/microphone/speech usage descriptions and
  archive/recovery privacy statements translated. Interface pt-BR DOES NOT
  imply pt-BR on-device speech recognition; dictation locale stays independent.
- ChickMark HealthKit Read/Write consent, water export and Siri AppShortcuts
  localized. The applicationName macro was preserved.
- Runtime fixed: PushkinCopy regional pt-BR bundle, CaptureBrand interface
  pt-BR resolver, pt_BR formatting and Portuguese note-count grammar,
  ChickMarkLanguage system and per-app regional selection.

## Verified
- [x] Core portfolio six-language full source key-parity and format-check audit.
- [x] 39/39 Core Python localization tests PASS (before native UI stage).
- [x] pt-BR companion InfoPlist and Siri string lint and placeholder parity PASS.
- [x] XcodeGen regenerated all four project sources.
- [x] Six unsigned builds PASS: Photo/PDF iOS, PUSHKIN iOS, Uhvat iOS, ChickMark iOS, Uhvat watchOS and ChickMark watchOS.
- [ ] pt-BR simulator XCUITests: Photo/PDF photo, PDF and AXXXL; Pushkin
  navigation; Uhvat AXXXL; ChickMark synthetic isolated store.
- [x] Verified actual compiled pt-BR.lproj resources inside four iPhone apps, two embedded Watch apps and all four app extensions/widgets.

## Open release gates
- [ ] Native Brazilian editorial review for legal/advertising, health,
  Shortcuts and document-photo guidance; layout/text clipping and VoiceOver.
- [ ] Physical iPhone/Watch permissions and non-destructive upgrades.
- [ ] Separate explicit version-specific owner approval for every Apple upload.
No current public app or App Store metadata changed.
