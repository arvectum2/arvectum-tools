# PUSHKIN — physical iPhone QA upgrade + production App Intent invocation, 19.10.2026

**Scope:** independent `ru.arvectum.tools.notify.physicalqa` on iPhone 13, iOS 27.0.1; no production application, no user Shortcuts changes and no App Store upload.

## Non-destructive migration: PASS

- Before the experiment, QA application version **1.0.0 build 1** contained **five** synthetic SwiftData notifications in `Library/Application Support/ArvectumNotify.store`. A copy of QA-only SQLite main file/WAL/SHM was saved on ArvectumSSD before any changes.
- DEBUG-only QA build **1.0.1 build 2**, same *QA* bundle ID, installed via CoreDevice **without uninstall**. A new sentinel notification with a unique UUID was inserted only if absent: `beforeCount=5`, `afterCount=6`, `markerCount=1`.
- DEBUG-only QA build **1.0.1 build 3** installed **in-place** over build 2 and queried the same persistent SwiftData store without seeding or modifying anything. `afterCount=6`, `markerCount=1`, and original sentinel UUID **exactly matches** build 2. Existing five records intact.
- Build **1.0.1 build 4** is a *QA build only* (NOT App Store 1.0.1(4)), also installed in-place without clearing. It exercised the production `CaptureNotificationIntent.perform()` twice consecutively with an **exclusively synthetic payload**, through its actual `NotifyPersistenceActor`. Exactly **one** new notification persisted via the 2-second transport dedupe; all old 6 records remained: `totalRecords=7`, `markerCount=1`, `previousRecordsKept=true`.
- These are signed physical iPhone tests of **QA bundle in-place persistence** and of **AppIntent invoked directly**; they are not a full upgrade of a personal App Store installation, nor proof that iOS Shortcuts' Notification trigger delivered a notification.

Artifacts: `/Volumes/ArvectumSSD/Arvectum/tmp/pushkin-migration-physical-20261019` — QA-only SQLite backup and metadata reports. Personal notification content is not included or exported.

## Native iOS Shortcuts acceptance

- Corrected read-only UI path (iOS Shortcuts may open an existing editor or the nested All Shortcuts folder): tap the accessibility `BackButton`, then `Automation` / `Автоматизация`; physical test navigates to native Automations and **does not change any item** (PASS).
- Previous native preview of signed base 1,000-app package: 1/1 PASS, **no Add**; previous physical unit+UI: **20/20 PASS**.
- End-to-end new temporary Notification automation remains **BLOCKED**, not a code pass: Apple `shortcuts sign --mode anyone` returns `NSURLErrorDomain error 500` both for our generated QA package *and* for the unchanged, previously valid template in a controlled GUI Terminal. No new signed QA shortcut produced; no personal automation imported, enabled, edited or deleted.
- Re-test native notification trigger after signing service restores; if cleanup of a temporary automation cannot be proven, require explicit owner authorization of that UI operation before creating one.

## Apple submission state and hard boundary

Prematurely submitted 1.0.1(4) **withdrawn**, reviewSubmission `COMPLETE`, version `DEVELOPER_REJECTED`, current public storefront still **1.0**. The future release preference is `AFTER_APPROVAL` (automatic after approval), not manual. See repository-root `AGENTS.md`. **No** resubmission/upload/metadata update without exact-build explicit user approval.
