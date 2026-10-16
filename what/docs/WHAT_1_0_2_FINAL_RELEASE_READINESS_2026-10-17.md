# Ухват / UhWhat? — 1.0.2 (7) production IPA readiness, 2026-10-17

**Status: LOCAL APP STORE EXPORT PASSED; NOT UPLOADED / NOT SUBMITTED / NOT PUBLISHED.**

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
