# PUSHKIN — iOS 27 Shortcuts discovery, exact cleanup and E2E blocker

## Scope and controls

Physical iPhone 13 with iOS 27.0.1, separate Pushkin QA app, Mac mini / Xcode 27.1. Do not import, enable, replace or delete any existing automations. Apple App Store submission is separately prohibited without explicit owner release approval.

## What was done and independently verified

- Native Shortcuts navigation from a restored nested Shortcuts view to the Automation tab succeeded; an isolated read-only XCTest was kept in [PR #130](https://github.com/arvectum2/arvectum-tools/pull/130).
- A further disposable UI exploration found that floating **+** unexpectedly opens a **New Shortcut** editor, not an Automation Notification trigger picker. Apple Shortcuts then auto-saved an empty \`Новая команда 4\` without an explicit Save. Thus the first exploration **did change** the user's Shortcuts iCloud library; it must not be called read-only.
- Immediate remediation on the same phone uniquely matched \`Новая команда 4, Нет действий\`; after the iOS confirmation that deleting the Shortcut also deletes its iCloud copies, the exact identified QA-created item was deleted. A physical XCTest reported **1/1 PASS**, \`QA_EXACT_EMPTY_DRAFT_DELETED\` and \`QA_PREEXISTING_SHORTCUTS_3_AND_NEW_SHORTCUT_RETAINED\`. No other item was selected for deletion, and earlier existing automations remain disabled.
- The mutating exploration and one-shot cleanup XCTest Swift sources were discarded from the working tree and **not committed**. The \`main\` QA suite contains only nonmutating navigation checks.
- \`shortcuts sign --mode anyone\` failed with **NSURLErrorDomain 500** from Mac mini both for a new QA-only template and the unchanged original template. A separately signed-in MacBook Air failed against the same unchanged template with **NSURLErrorDomain 504**. No signed QA-specific package and no new Notification automation were installed.

## Evidence

The detailed logs and xctestrun results remain on ArvectumSSD (no personal command details or screenshots committed):
\`/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-automation-draft-20261019\`

The native physical QA acceptance of persisted records and direct AppIntent is in [PHYSICAL_SAFE_UPGRADE_AND_APPINTENT_2026-10-19.md](PHYSICAL_SAFE_UPGRADE_AND_APPINTENT_2026-10-19.md). CI merged PR #130 after successful retry of a transient iOS simulator test environment error.

## Open gate before release

- [x] AppIntent itself durably persists and deduplicates test notifications on iPhone.
- [x] In-place QA build upgrades retain prior SwiftData history.
- [x] Removed exclusively the new empty experimental Shortcut and verified older items remain.
- [ ] End-to-end \`real incoming notification → new temporary system automation → Pushkin AppIntent → history\` using a dedicated, safely removable QA automation. **Not proven**.
- [ ] Real production App Store in-place upgrade without touching personal history. Do not uninstall the production app.
- [ ] Get explicit user approval **before any future ASC upload, review or publication**. Configure automatic distribution after Apple approval, not manual.
