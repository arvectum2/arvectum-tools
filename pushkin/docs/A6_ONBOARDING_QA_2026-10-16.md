# A6 — PUSHKIN automation onboarding, 2026-10-16

**Scope:** improve guidance and offer *optional* manual group planning without changing Notification capture, SwiftData, signed Shortcuts resources, App Intents, or App Store versions.

## Correction to the 25-app assumption

The old guess that a Notification automation supports only 25 apps **does not hold in our measured iOS 27 experiment**. On a physical iPhone, a signed shortcut with 1,000 entries in the `WFNotificationTrigger.SelectedApps` array imported successfully and Shortcuts retained all of them; [physical experiment](PHASE0_SPIKE.md#1000-app-trigger). This confirms the data model retained entries, **not** that notifications from all 1,000 apps were delivered, enabled, or runtime-tested. No iOS-wide 25-app hard limit has been established. Automatically splitting the base into 40 Shortcuts would be a UX regression.

Also verified physically: app descriptors for software installed **after** base import are not automatically rebound. Re-toggling the existing automation did not help; a signed one-app micro-package imported after installation, followed by manual enablement, did capture a test notification. Imported Notification automations are disabled by iOS until the user turns them on. PUSHKIN cannot read or change Shortcuts' enabled state.

## Implemented

- Step 1: launch the signed offline 1,000-app base package; opening Shortcuts is shown as a *handoff*, not a successful setup.
- Step 2: explicit deep link to Automations with instruction to enable the newly imported automation. No claim that PUSHKIN can inspect the switch.
- Step 3: verify that **at least one** notification was captured; number of distinct observed source apps is shown, never called total configured coverage.
- New-install refresh: link to existing signed one-app packages. Setup instructions explain why old base automations will not automatically bind apps installed later.
- Optional manual group planner: offline selection of catalog bundle IDs, suggested groups of 25, stable ordering, no duplicates, copy name checklist, Shortcuts deep-link and setup text. These are *suggested human-sized groups*, **not automatically generated or signed workflows**. Users manually select the apps in Apple's UI. Planner stores only selected IDs in UserDefaults, independent of SwiftData; Clear does not touch history or Shortcuts.
- Updated existing Add Apps and pending-setup micro-copy to describe Shortcuts truthfully.
- RU in-app UI localization remains a separate pending roadmap task; A6 follows existing English-first UI.

## Test gates

- [x] **App build PASS** with Xcode 27 and existing signed catalog assets (generic iOS Simulator).
- [x] **17/17 unit PASS**: group boundaries (0/1/25/26/51), 70-element order preservation, dedupe/toggle, corrupt local selection recovery, original capture/delete/store/catalog unit tests; no network.
- [x] **2/2 focused simulator UI PASS** after correcting test navigation to scroll the lazy SwiftUI List; setup link/status guidance and group select/clear; no real history mutation.
- [ ] PR CI and mirrored source SHA.
- [ ] Physical non-destructive validation on real iPhone: open base signed package, cancel and retry, enable automation in Shortcuts, capture notification, late-installed app micro-package, multiple manual group coverage and overlap. **Do not** disable/uninstall existing personal automations or reset personal notification history.

No new A6 App Store binary or upload; the A5 signed Pushkin 1.0.1(3) remains unchanged, and new A6 source will need a distinct later build after its QA and review-status check.
