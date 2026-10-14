# Pushkin 1.0 — physical QA evidence, 2026-10-14

State: Apple review still pending (owner-confirmed). No publication claimed.

## Verified by CoreDevice
- [x] Physical iPhone 13 has ru.arvectum.tools.notify 1.0.0 (2) installed.
- [x] Non-activated physical iPhone launch command succeeded.
- [ ] Check exact binary provenance: roadmap records submitted 1.0.0 (1), while current developer installation is build 2; current device test is not automatically evidence for the submitted App Store build.

## Critical manual acceptance still open
- [ ] Back up user history or use new disposable sample notifications only.
- [ ] Reproduce and verify the reported deletion crash using a disposable entry, verify Cancel, then delete intentionally and relaunch.
- [ ] Confirm deleted item stays gone, other history remains intact and local full-text search still works.
- [ ] Walk through Shortcuts automation activation, grouping across the per-automation 25-app limit, coverage verification and offline capture.
- [ ] Test permissions denied and disabled automation messages; do not claim capturing arbitrary iOS notifications beyond documented Shortcuts mechanics.
- [ ] Verify visual layout and privacy constraints before release.

Do not delete pre-existing personal history to test destructive behavior.
