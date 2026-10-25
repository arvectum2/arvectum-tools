# Core C5.7: nine-language iPhone UI matrix

25 October 2026. Xcode 27.1, iPhone 17 Pro iOS 27.0 Simulator.
Ten missing language UI smoke tests were created and actually executed.

| Product | New locales | XCUITest |
| --- | --- | --- |
| Photo/PDF | RU EN, AXXXL mode grid | 2/2 PASS |
| Pushkin | RU EN, tabs and navigation | 2/2 PASS |
| Uhvat | RU EN FR, AXXXL synthetic home | 3/3 PASS |
| ChickMark | RU EN ES, synthetic habit form | 3/3 PASS |
| **Total** | 10 missing app-locale pairs | **10/10 PASS** |

The existing 26 app-locale pairs have their own native smoke suites.
All 36 app x 9 locale pairs now have authored native XCUITest coverage
and a new Python/Core test ensures this source-level gate cannot
silently regress. This is not a guarantee of visual perfection
or exhaustive screen-by-screen translation quality.

Previous integration: 52 Core + 68 Swift + 60 localized iOS UI passed.
This branch adds one new Python source gate and 10 tested UI cases.

All test app instances were synthetic and isolated. Photo fixtures
never access a personal photo library; Pushkin does not change Apple
Shortcuts; Uhvat never records; ChickMark disables CloudKit and
does not save user habits. The 4 real XCResult bundles and logs
are stored on Mac mini at:
  /Volumes/ArvectumSSD/Arvectum/qa/ios-nine-language-matrix-20261025

CI main 8/8 GREEN as observed after merge of PR #141-147.
Actual CI for this new branch still needs independent verification.
Physical Watch/iPhone/VoiceOver QA, native editorial review,
background/permission/update testing and owner approval for
each App Store upload remain release blockers. No Apple upload.
