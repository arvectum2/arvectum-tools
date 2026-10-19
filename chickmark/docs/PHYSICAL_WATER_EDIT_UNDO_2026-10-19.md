# ChickMark CM18-3: iPhone 13 real-writer QA, 2026-10-19

Physical iPhone 13, iOS 27.0.1, Xcode 27.1. Isolated Debug app `ru.arvectum.tools.chickmark.waterqa`, build 203 installed in-place over build 202.

The QA-only one-shot probe requires `--ui-testing --disable-cloud-sync --water-edit-undo-live-qa` and the exact QA bundle identifier. The probe is excluded from the production build. It exercises the production sync engine and writer with a unique temporary sync ID and an isolated UserDefaults suite.

**PASS:** 5 sequential synthetic quantity changes (1, 2, 0, 3, 0), corresponding to 250, 500, 0, 750, 0 mL. The final journal reports `completedClean`, `countsCompleted=[1,2,0,3,0]`, and `residualOwnSamples=0`. Deletion was scoped to this QA identifier and its originating app. The second launch did not repeat the transaction. The earlier one-shot QA journal remained byte-identical.

The check demonstrates native HealthKit update, undo, replay safety and own-sample cleanup. It does **not** replace a real user-interface check-in flow or an OS Settings revoke/regrant check.

Evidence and test journal: `/Volumes/ArvectumSSD/Arvectum/tmp/chickmark-water-edit-undo-live-20261019`. No App Store upload.
