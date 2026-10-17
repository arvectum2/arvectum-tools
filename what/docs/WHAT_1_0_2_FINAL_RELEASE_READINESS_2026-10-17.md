# Ухват / UhWhat? — 1.0.2 (7) production IPA readiness, 2026-10-17

**Status (UPDATED 2026-10-17): BLOCKED — Watch complication branding fix is not included in the previously exported production IPA.**
The IPA SHA-256 39ae71cc0c3d65d92d6998823f600e7861c44a91cec75762d33155e3faa99dc6 is now **SUPERSEDED** for submission, despite its previously passing signatures and functional QA. Do not upload it. A new QA Watch complication visual acceptance and another full App Store export are required before release.

## Evidence and provenance

- Corrected source: fix/what-watch-autostart-1.0.2, PR #84 (draft at checkpoint).
- The what/ios Git tree remained identical (931285745f9fce127f8324c3c67bc5a2a0fb520c) between IPA archive source ec03e79a843fffe41be7442e4992dbf95ee6e2b9 and origin/main integration 4c79302922d680a7bd1624603e3ad2ae155d4790. The two Core files linked into the targets were unchanged. Roadmap integration therefore did not alter compiled release sources.
- Physical Watch SE and iPhone 13 QA (8): one complication tap starts capture; Stop and Digital Crown finalize; offline ordering; no duplicates; automatic watch reboot recovery, with sound and no duplicate. Owner separately confirmed final QA (8) one-tap + Crown + audio + dedup on 2026-10-17.
- Final branch regression: 63 iOS tests (3 skipped / 0 failures), plus 2 UI tests (0 failures). QA build 8 has separate QA bundle IDs.

## Fresh production-signed IPA

- Version/build: **1.0.2 (7)** in the iPhone app, iPhone widget, Watch app, Watch complication.
- Team VML75VY94V. Signing certificate: Apple Distribution: LLC ARVECTUM.
- Xcode 27.1 archive and App Store Connect export both succeeded with ExportOptions-A5-AppStore.plist.
- Mac mini SSD IPA: /Volumes/ArvectumSSD/Arvectum/builds/what-production-1.0.2-20261017/export/WhatIOS.ipa
- SHA-256: **39ae71cc0c3d65d92d6998823f600e7861c44a91cec75762d33155e3faa99dc6**
- Size: **2714731 bytes**.
- Validation receipt: /Volumes/ArvectumSSD/Arvectum/builds/what-production-1.0.2-20261017/IPA_LOCAL_VALIDATION_RECEIPT.json
- All four extracted IPA components passed strict code-sign verification, their production bundle IDs and versions, Apple Distribution signature and get-task-allow=false. No private RuWordNet-named assets.
- Old A5 IPA SHA-256 978e49a845db6311e81ba9d0d4bb2be18d9dd9a55ef9fdd84310b1c56db0fce5 is superseded; DO NOT SUBMIT.

## What's New — suggested text, not posted

**ru-RU:** Исправили запуск записи одним нажатием на циферблате Apple Watch. Улучшили сохранение заметок при выходе из приложения и автоматическую доставку на iPhone после потери связи или перезагрузки часов. Устранили возможные дубли при повторной передаче.

**en-US:** Fixed one-tap recording from the Apple Watch face. Improved saving voice notes when leaving the app and automatic delivery to iPhone after disconnection or Watch restart. Improved duplicate protection during retries.

## Release gates

- [x] QA (8) physical confirmation of reproduced Watch-face and reboot transfer regressions.
- [x] Corrected production IPA archive, local export, four production signatures and entitlements.
- [x] PR #84 conflict with origin/main resolved; iOS and used Core source trees unchanged.
- [ ] PR #84 CI completion and review/merge into release reference.
- [ ] Confirm App Store Connect status and that intended production build 1.0.2 (7) can be uploaded.
- [ ] Explicit owner authorization to upload or submit; Apple-side processing, validation and review.
- [ ] Actual published release (not claimed).

**No App Store upload/submission/publication initiated in this checkpoint.**

## Additional branding requirement discovered by owner (2026-10-17)

- The actual Watch complication was reported as a generic mic; the standalone QA complication was an empty square. Owner requires the **same recognizable icon as Ухват application**, not a system mic.
- The complication was changed to use exact byte-identical full-color Watch app icon on full-color watch faces and a native vector path based on identical brand contours for accented/tinted watch faces; added accessoryCorner support. This change **was not** in the previously exported IPA and must be validated visually on physical Watch.
- Apple controls accented complication coloring by watch-face configuration; the logo silhouette can remain recognizable but full-color appearance isn't guaranteed on every face. An asset catalog inclusion check and physical UI test are explicit gates.
- iOS 1.0.2 is NOT cleared for upload until the icon is present/recognizable on the physical Watch and existing one-tap capture/audio still works.

## Additional production-source changes after previous IPA (2026-10-17)

SyncDiagnosticsView translated through the app's existing RU/EN CaptureBrand.text locale selection, with 2 new UI tests PASS. QA10 updated on physical Watch/iPhone; screenshot language and EN recognition checks awaiting owner. The old locally-exported 1.0.2(7) IPA predates both branded Watch complication and this localization and MUST NOT be uploaded. No newer production IPA has been built or released at this time.

## QA11 new iPhone UI / Speech locale changes (2026-10-17)

Previously exported production IPA is still **superseded** and must not be uploaded. After QA10 hardware check, owner reported missing diagnostics Done button and a mismatch between English Speech setting and Russian UI. Both fixed in source: diagnostics dismiss action and shared persisted RU/EN locale. Three simulator UI tests passed. Isolated signed iPhone QA11 installed in place, and 22/22 QA app-support files SHA-256 identical after upgrade. Owner visual acceptance on physical iPhone QA11 remains open. No production IPA uploaded or submitted to Apple.

## Final QA11 branch simulator regressions, 2026-10-17

Full Xcode WhatIOS scheme tests PASS: 63 unit/integration (3 skipped), 5 UI, zero failures. The persisted-locale test fixture was corrected to respect saved settings. This does not authorize upload; previous production IPA is superseded and physical QA11 UI is unaccepted.
