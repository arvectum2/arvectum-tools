# Adaptive Arvectum Tools source merged to main · 18.10.2026

## GitHub evidence

- [PR #90](https://github.com/arvectum2/arvectum-tools/pull/90) merged 18.10.2026 at 12:06:55 UTC.
- PR head 4c8bfb28d692ede5403fe75a006720b335507815; squash-main c86bc5437ae4b558c6c8b3114879ce3cd3d95e59.
- **38/38 PR CI checks successful, 0 failures and 0 pending** before merge.
- Both commits have identical Git tree 5b2461f91efb53b3d339e45fba20d37b25541a7d. No lost source changes.
- Post-merge main CI is a separate workflow and may run later than the recorded PR result.

## Source included

- Shared adaptive layout package and all four app targets: real UhWhat 1.1 multimodal source, ChickMark 1.5 submitted-source integrations, Pushkin notification history/navigation and Фото/PDF adaptive preview workspace.
- [Pilot QA](ADAPTIVE_T4_T5_PILOT_2026-10-18.md), [UhWhat 1.1 QA](ADAPTIVE_T4_T5_MULTIMODAL_2026-10-18.md), [ChickMark + Pushkin QA](ADAPTIVE_CHICKMARK_PUSHKIN_2026-10-18.md), [ChickMark 1.5 source QA](ADAPTIVE_CHICKMARK_1_5_INTEGRATION_2026-10-18.md).

## Last independent local checks

- Mac mini Xcode 27.1, standard iPhone simulator: UhWhat WhatIOSTests 104 executed, 0 failures, 3 expected skip.
- Pushkin notification deletion: 3/3 unit and 3/3 UI PASS on isolated simulator. One GitHub XCTest runner could not launch the app; same SHA previous pass, targeted rerun successful.
- Shared Core 13/13 Swift tests PASS; other iPad/Duo results are documented in linked QA records.
- After merge: bash core/tools/verify_baseline.sh **PASS** on Mac mini, with 13/13 Core tests, architecture, SwiftPM/dependency alignment. Core CI impact contract PASS.
- All temporary test outputs are on ArvectumSSD. Generated Xcode project UUID-only changes were reverted before merging.

## What was NOT released or verified

- This was source merge, not a new App Store upload or publication. Submitted/live binaries and user devices unchanged.
- The owner does not have physical iPhone Duo; simulator-only QA was explicitly approved for current development. A two-display simulator cannot prove a physical hinge/fold-unfold transition during recording or export.
- Real Camera/Mic, Files/Photos, HealthKit, Shortcuts, permissions, privacy/ad-consent, accessibility and future signed builds require separate app-specific QA.
- ChickMark dietaryWater is a separate [draft PR #94](https://github.com/arvectum2/arvectum-tools/pull/94) based on main. It is NOT merged or submitted and awaits controlled real HealthKit acceptance.
- Growth and Where? remain paused.
