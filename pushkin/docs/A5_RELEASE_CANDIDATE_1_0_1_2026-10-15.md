# pushkin — A5 isolated release candidate 1.0.1 (3)

**State as of 2026-10-15: SOURCE-CANDIDATE ONLY. Not uploaded, not submitted, not public.**
**ASC external source:** authenticated read-only lookup on 2026-10-15: not public; 1.0.0 (1) WAITING_FOR_REVIEW, build 2 also exists in ASC.
**Bundle:** `ru.arvectum.tools.notify`. **Proposed** version/build: `1.0.1 (3)`.
**Source base:** `origin/main@657ce0d6bcce78cf35e07135ef5871da8e07c0ff`, plus ONLY the `pushkin/ios/project.yml` version/build changes in this isolated release branch and this release document. No old release source is blindly merged.
**Release branch:** `release/pushkin-1.0.1-build3-a5-20261015`.

## Included changes — source-only since last submitted build

PR #68: safe UUID-based SwiftData deletion with rollback; PR #69: reliably locate bundled Shortcuts micro-package resources. No analytics extraction or data migration.

## App Store What’s New — draft, not posted

**ru-RU:** Исправили удаление записей и улучшили поиск команд для настройки автоматизаций. История уведомлений остаётся только на устройстве.

**en-US:** Improved notification deletion reliability and Shortcuts setup. Notification history stays on your device.

## Pre-submission gates

- [x] Isolated branch from frozen `657ce0d6bcce` base; no automatic merge to `main`.
- [x] Reserved unique marketing/build number; cross-target version consistency is enforced by `project.yml`.
- [ ] Clean generated Xcode project builds on generic iOS Simulator (and watchOS if applicable).
- [ ] Full app unit/UI regression and clean GitHub Actions release-branch checks.
- [ ] Distribution-signed `.xcarchive` with correct team, entitlements and embedded extensions; `.ipa` SHA-256 and signing/profile receipt. **Do not claim signing from a simulator build.**
- [ ] Verify bit-by-bit exported bundle version/build and that any signed artifact includes only intended files.
- [ ] **Physical/external:** Await decision for submitted 1.0.0; physical regression for disposable notification deletion and offline Shortcuts capture, app privacy and actual bundle check. Never overwrite user notification history.
- [ ] **Apple:** actual new App Store version + build association, review notes and required locales only after preceding gates pass. No upload or submission in A5 draft phase.

## Existing QA evidence
- pushkin/docs/DELETE_SAFETY_QA_2026-10-15.md and pushkin/docs/SHORTCUT_RESOURCES_QA_2026-10-15.md
- Verified external version state is separate from the submitted build, local code tests and simulated user flows.
- Never use another app's signed IPA or release profile. No user data deleted, reinstalled, replaced, uploaded or reset in preparing this candidate.
