# PUSHKIN — Roadmap

**Working product name:** `PUSHKIN`
**Styling variants:** `Push-keen`, `Push'k'in`
**Internal repository codename/path:** `arvectum-notify` (kept temporarily to avoid unnecessary technical renames during feasibility work)

## Product goal

Build a mass-market iOS utility that solves one simple pain exceptionally well:

> Never lose an important notification again.

PUSHKIN should be understandable without technical knowledge, useful within the first minute after setup, privacy-first, and suitable as the first broad-consumer app in the Arvectum utility line.

The product starts with notification history and progressively expands into snooze, reminders, prioritization, digests, and simple automation.

---

## Product principles

**Primary product metric:** minimize required user actions during initial setup and whenever app coverage changes. Every technical choice should be judged first by tap count, typing, waiting time, and number of system confirmations.

Current UX targets:
- onboarding: one PUSHKIN tap -> one system `Add Shortcut` -> at most one automation-enable action;
- common newly installed app: `+ App` -> tap app -> system `Add Shortcut` -> at most one automation-enable action;
- uncommon newly installed app: `+ App` -> type/search -> tap app -> system `Add Shortcut` -> at most one automation-enable action;
- no full TOP-1000 rebuild in the normal update path.

1. **Mass-market first.** No power-user complexity on the main path.
2. **Immediate value.** The user should understand the product in seconds.
3. **Local-first privacy.** Notifications stay on-device by default.
4. **No account required.** MVP must work without registration or backend.
5. **No ads in notification content.** Sensitive data should not be monetized through tracking.
6. **Progressive disclosure.** Rules and automation appear only after the core inbox works well.
7. **Native iOS UX.** SwiftUI, system patterns, accessibility, Dynamic Type, VoiceOver.
8. **App Store-safe design.** Do not rely on behavior that conflicts with platform restrictions.

---

# Phase 0 — Feasibility spike

**Goal:** prove that the iOS notification capture path is stable enough for a consumer product before investing in the full UI.

### Tasks

- [x] Create minimal native iOS project for Arvectum Notify.
- [x] Set bundle identifier and signing under Arvectum.
- [x] Research and implement the iOS notification-trigger flow available through Shortcuts / App Intents.
- [x] Capture a notification event into the app's local storage.
- [x] Verify what data is actually available:
  - [x] source app display name
  - [x] title
  - [x] subtitle
  - [x] body
  - [x] timestamp (capture-time fallback; original notification timestamp is not exposed)
  - [x] attachments and links (not exposed by the iOS 27 Notification properties)
  - [x] other metadata (no additional notification properties exposed)
- [x] Test while:
  - [x] app is open
  - [x] app is in background
  - [x] app has been terminated
  - [x] app was explicitly force-quit
  - [x] device is locked
  - [x] Focus mode is active
  - [x] Low Power Mode is active
- [x] Configure one multi-app Notification trigger with 10 source apps.
- [ ] Verify real notification capture from all 10 configured source apps (5/10 verified: Telegram, Messages, WhatsApp, Mail, VkusVill).
- [x] Test empty-App / any-app Notification trigger behavior: empty App is invalid and the automation cannot be enabled.
- [x] Check picker for `Any App` / select-all: not exposed on iOS 27.
- [x] Evaluate public iOS 27 alternatives for universal capture:
  - [x] UserNotifications: own-app notifications only.
  - [x] Notification Service Extension/filtering entitlement: own-app remote notifications only.
  - [x] App Intents / Shortcuts URL schemes: no public automation-provisioning API.
  - [x] FamilyActivityData: EU-only installed-app discovery, no notification-content access.
  - [x] MDM: supervised-device path, not consumer capture.
  - [x] Accessory Notifications: true all-app forwarding exists, but requires an accessory and is EU-only for customer use.
- [x] Re-check source-app availability when the installed-app set changes.
  - [x] A single imported `WFNotificationTrigger` accepts and preserves **1000 `SelectedApps`** entries on a physical iPhone.
  - [x] Descriptors for apps that are not installed at import time remain serialized in `SelectedApps`.
  - [x] Installing such an app later does **not** automatically activate capture for it.
  - [x] `shortcuts://automations` opens the Shortcuts Automation list directly from PUSHKIN.
  - [x] Reject **off -> on** as the refresh mechanism; it did not make the controlled late-installed Future App capture.
  - [x] Prove same-name **Replace** with a fresh `WFTriggerUUID` tombstones the previous workflow and leaves one visible replacement.
  - [x] Confirm replacement resets the automation toggle to OFF and therefore requires explicit re-enable.
  - [x] Reject a full TOP-1000 rebuild as the normal per-app refresh UX: Shortcuts can spend a minute or more resolving the complete catalog.
  - [x] Prototype two-layer coverage UX: one large base catalog plus incremental refresh overlays.
  - [x] Compare 10/25/50-app pack shapes, then switch the normal refresh path to **one app = one micro-pack** to minimize user waiting and avoid unrelated Replace operations.
  - [x] Add a versioned JSON coverage manifest and deterministic micro-pack generator. Shortcut names stay stable per app; trigger UUIDs change by catalog version.
  - [x] Add direct Inbox toolbar flow: `+ App -> search -> tap app -> open micro-pack`.
  - [x] Verify the minimal update flow on Simulator: **2 taps inside PUSHKIN + one text entry** before the system import UI.
  - [x] Add hard deduplication for identical captures arriving within 2 seconds, so overlapping base/micro automations do not create duplicate inbox rows.
  - [x] Build the real production TOP-1000 source manifest from current Apple App Store Top Free charts across 36 storefronts; resolve all entries to real Bundle IDs and keep six key iOS system apps for notification coverage.
  - [x] Add a reproducible cached catalog builder (`scripts/build_app_store_catalog.py`) so the ranking can be refreshed without manual curation.
  - [x] Pre-sign the production base package and one micro-package per supported app: 1000 micro-packages, zero missing files, ~22.7 MB total.
  - [x] Install the supplied PUSHKIN icon into the AppIcon asset set; production Simulator build succeeds.
  - [x] Polish `+ App` for production: no forced keyboard, compact popular/results list, one concise Shortcuts instruction, empty-search state, and no physical-test fixture in the user-facing catalog.
  - [x] Add the **Custom** fallback for apps outside TOP-1000: search the current App Store storefront plus US/GB fallback storefronts, remove built-in duplicates, then prepare one signed micro-package only for the selected app.
  - [x] Physical proof A: teamless one-app micro-package imported **after** installing the controlled Future App created a fresh Notification automation; after enabling it, the real marker notification `PUSHKIN_RUNTIME_1000_PROVISIONAL_02` was captured by PUSHKIN on the physical iPhone.
  - [x] Physical proof B: measured physical-iPhone handoff from tapping the app in PUSHKIN to the Shortcuts `Add` import preview at **~2.3 s** across repeated instrumented XCTest runs (2.28–2.33 s).
  - [x] Physical proof C: an app absent from the RU search results (`Working Copy`) was found through storefront fallback, a signed Custom micro-package was generated on demand, and the physical iPhone reached the native Shortcuts `Add` preview successfully.
  - [ ] Deploy the production HTTPS Custom signer endpoint and set `PUSHKIN_CUSTOM_COVERAGE_SERVICE_URL` for Release builds. The signer receives only the selected app identity; notification contents remain local.
- [x] Measure event loss / duplication.
- [x] Reduce setup to one multi-app Notification trigger, four field mappings, and automatic in-app verification.
- [ ] Validate the guided setup with a non-technical user.
- [x] Determine re-alert viability: local Notify alerts are possible, but silencing third-party originals requires user notification settings; defer re-alert to Snooze rather than MVP capture.
- [x] Document platform limitations in `docs/PHASE0_SPIKE.md`.

### Exit criteria

Proceed only if:

- notification capture is reliable enough for everyday use;
- captured data is sufficient to provide useful history;
- setup can be explained to a non-technical user;
- the flow works without requiring an always-open app.

---

# Phase 1 — Product foundation

**Goal:** establish the app shell and local data model.

### Technical baseline

- [ ] Swift + SwiftUI.
- [ ] Minimum supported iOS version: set after Phase 0 validation.
- [ ] SwiftData or equivalent local persistence.
- [ ] App Intents / Shortcuts integration.
- [ ] LocalAuthentication for Face ID / Touch ID lock.
- [ ] Local notifications for Notify's own reminders.
- [ ] No mandatory backend.
- [ ] No mandatory account.

### Core data model

Notification record:

- id
- source app identifier / display name
- title
- body
- received timestamp
- original event timestamp if available
- status: inbox / saved / done
- reminder timestamp
- pinned flag
- category
- expiration timestamp
- metadata payload if useful

### Privacy

- [ ] Privacy policy for Arvectum Notify.
- [ ] On-device storage by default.
- [ ] Face ID lock option.
- [ ] Configurable retention.
- [ ] Automatic short TTL for OTP / verification-code notifications.
- [ ] Clear local-data deletion.
- [ ] No analytics containing notification text.
- [ ] Review App Store privacy labels before beta.

---

# Phase 2 — MVP 0.1: Notification History

**Goal:** solve the core pain: “I dismissed a notification and now I cannot find it.”

### Onboarding

- [ ] Intro screen with one sentence: **Never lose a notification again.**
- [ ] Explain local-only storage.
- [ ] Guided setup of notification capture.
- [ ] Ask the user to start with 3–5 important apps rather than configuring everything.
- [ ] Built-in setup verification.
- [ ] Test notification.
- [ ] Clear success state: **You're protected.**

### Inbox

- [ ] Chronological notification feed.
- [ ] Sections:
  - Today
  - Yesterday
  - Earlier
- [ ] App icon / app name.
- [ ] Notification title.
- [ ] Body preview.
- [ ] Timestamp.
- [ ] Unread / handled visual state.
- [ ] Pull to refresh if useful.
- [ ] Empty states.

### Search and filtering

- [ ] Full-text search.
- [ ] Filter by source app.
- [ ] Filter by date.
- [ ] Saved-only filter.
- [ ] Search history or recent queries only if it improves UX.

### Basic actions

- [ ] Save.
- [ ] Mark done.
- [ ] Delete.
- [ ] Pin.
- [ ] Copy text.
- [ ] Share notification text using iOS Share Sheet.

### Settings

- [ ] Retention period.
- [ ] Face ID lock.
- [ ] Managed apps.
- [ ] Storage usage.
- [ ] Delete all data.
- [ ] Privacy/about screen.

### MVP exit criteria

- setup completion rate acceptable in internal testing;
- notifications are reliably captured;
- history remains usable with thousands of records;
- search feels instantaneous;
- no critical crashes or data-loss bugs.

---

# Phase 3 — 0.2: Snooze / Remind Later

**Goal:** turn passive history into an everyday utility.

### Features

- [ ] Swipe action: **Remind later**.
- [ ] Presets:
  - 15 minutes
  - 1 hour
  - This evening
  - Tomorrow
  - Pick a time
- [ ] Reminder queue.
- [ ] Re-notification from Arvectum Notify.
- [ ] “Done” directly from reminder where possible.
- [ ] Reminders screen.
- [ ] Missed / overdue reminders.

### Product hypothesis

A notification is often not irrelevant — it merely arrived at the wrong time.

This should become a primary retention feature.

---

# Phase 4 — 0.3: Important

**Goal:** help users separate signal from noise without exposing a complex rules engine.

### Features

- [ ] Mark an app as important.
- [ ] Mark a sender / keyword pattern as important where data permits.
- [ ] Important inbox.
- [ ] Persistent / repeated reminders for selected important items.
- [ ] Suggested importance based on repeated user behavior, processed locally where possible.
- [ ] Simple prompts such as:
  - “You often save notifications from this app. Always mark them important?”
  - “You dismissed 20 similar notifications today. Group them?”

### Guardrail

Do not expose a technical IF/AND/THEN builder yet.

---

# Phase 5 — 0.4: Digest and organization

**Goal:** make Notify useful even when the user does not actively search.

### Features

- [ ] App grouping.
- [ ] Thread-like grouping of similar notifications.
- [ ] Daily catch-up.
- [ ] Optional scheduled digest.
- [ ] Categories such as:
  - People
  - Money
  - Deliveries
  - Work
  - Other
- [ ] Local classification first.
- [ ] No opaque AI dependency for essential behavior.

---

# Phase 6 — 0.5: Simple rules

**Goal:** introduce controlled automation without turning the app into Tasker.

### Rule templates

- [ ] If notification contains a keyword → mark important.
- [ ] If notification comes from selected app → save automatically.
- [ ] If notification matches a pattern → remind after N minutes.
- [ ] If notifications repeat frequently → group them.
- [ ] Auto-delete specific low-value notification types.
- [ ] Exclude sensitive content from long-term history.

### Advanced mode

Only after template-based rules are proven:

- [ ] conditions;
- [ ] multiple conditions;
- [ ] actions;
- [ ] regex;
- [ ] App Intent / Shortcut actions;
- [ ] webhook integrations if later justified.

---

# Phase 7 — UX polish and accessibility

- [ ] Final Arvectum visual language.
- [ ] Light / Dark Mode.
- [ ] Dynamic Type.
- [ ] VoiceOver.
- [ ] Reduce Motion.
- [ ] Large tap targets.
- [ ] Haptics.
- [ ] Native swipe actions.
- [ ] Localization architecture from day one.
- [ ] Russian and English launch localization.

---

# Phase 8 — Internal dogfood

**Goal:** use the product every day before TestFlight.

### Test matrix

- [ ] Different iPhone generations.
- [ ] Different iOS point releases.
- [ ] Large notification volume.
- [ ] Reboot.
- [ ] App update.
- [ ] Device storage pressure.
- [ ] Shortcuts changes / deletion.
- [ ] Permission revocation.
- [ ] Focus modes.
- [ ] Airplane mode / offline.
- [ ] Localization.
- [ ] Face ID disabled / unavailable.

### Metrics to observe

- capture reliability;
- duplicate rate;
- setup completion;
- average daily opens;
- search usage;
- snooze usage;
- retention;
- crash-free sessions.

Do not log notification content in analytics.

---

# Phase 9 — TestFlight beta

- [ ] Prepare App Store Connect listing.
- [ ] App icon.
- [ ] Screenshots.
- [ ] Privacy nutrition labels.
- [ ] Beta review notes explaining the Shortcuts/App Intents flow.
- [ ] External TestFlight group.
- [ ] Feedback form.
- [ ] Track onboarding failures separately from product failures.
- [ ] Collect qualitative feedback around:
  - “What notification did this save for you?”
  - “What did you expect it to do but it did not?”
  - “Which step of setup was confusing?”

---

# Phase 10 — App Store 1.0

### Launch scope

Version 1.0 should ship only when the following are polished:

- reliable notification capture;
- guided onboarding;
- notification history;
- search;
- filters;
- Save / Done;
- Face ID;
- retention controls;
- privacy-first defaults.

Snooze can ship in 1.0 if stable enough; otherwise it is the first post-launch update.

### Positioning

**Name:** Arvectum Notify

**Category:** Utilities

**Core promise:** Never lose an important notification again.

**Possible subtitle:** Notification History

### Store message pillars

1. Find dismissed notifications.
2. Search your notification history.
3. Keep important alerts for later.
4. Private by design.
5. No account required.

---

# Phase 11 — Growth

Only after retention is proven.

- [ ] App Store Optimization.
- [ ] Short-form demo creatives.
- [ ] Referral / share loop if appropriate.
- [ ] Ratings prompt only after a positive user moment.
- [ ] Landing page on Arvectum website.
- [ ] Cross-link future Arvectum utilities without harming UX.
- [ ] Review localized App Store keywords.
- [ ] Track search terms around:
  - notification history
  - deleted notification
  - missed notification
  - notification log
  - remind later
  - notification archive

---

# Monetization hypothesis

Do not lock the core pain behind a subscription.

Potential model:

### Free

- recent history;
- search;
- basic Save / Done;
- limited retention.

### One-time Pro unlock

Possible Pro features:

- unlimited retention;
- unlimited managed apps;
- snooze;
- Important;
- advanced filters;
- export;
- rules;
- advanced privacy settings.

A subscription should only be introduced if the product later gains meaningful recurring server-side costs or recurring services.

---

# Explicit non-goals for MVP

Do **not** spend MVP time on:

- Android version;
- macOS companion;
- cloud sync;
- web dashboard;
- team accounts;
- AI chat over notifications;
- complex automation builder;
- server infrastructure;
- ad network integration;
- full NetOps integration;
- APL integration.

These can be reconsidered only after the core consumer product demonstrates retention.

---

# Product metrics

Primary:

- onboarding completion rate;
- Day 1 / Day 7 / Day 30 retention;
- weekly active users;
- number of captured notifications per active user;
- percentage of users who successfully retrieve a previously missed notification;
- snooze adoption after release.

Quality:

- capture success rate;
- duplicate capture rate;
- crash-free users;
- search latency;
- database size / performance;
- support requests caused by Shortcuts setup.

Store:

- App Store rating;
- review sentiment;
- conversion from product page to install;
- organic search share for notification-history queries.

---

# Decision gates

## Gate A — after feasibility spike

**Question:** Can iOS reliably provide enough notification data through an acceptable setup flow?

**Current result for the full-product requirement:** Gate reopened by the catalog-import experiments. An empty App value still cannot be used as a wildcard, but a single generated Notification trigger has now preserved **1000 explicit app descriptors** on physical hardware. That removes per-app manual selection from initial setup for a maintained catalog.

**Gate A result: passed for the software-only catalog + micro-overlay architecture.** OFF -> ON has been rejected, but the physical iPhone now proves the intended late-install path: import a fresh **one-app teamless micro-package after the app is installed -> enable its new automation -> receive a real notification -> PUSHKIN captures it**. The micro automation starts disabled, so one explicit enable action remains an iOS-required part of the refresh UX.

## Gate B — after internal MVP

**Question:** Does history alone solve a pain strongly enough that testers voluntarily keep using the app?

If no: prioritize Snooze before public launch.

## Gate C — after TestFlight

**Question:** Is onboarding simple enough for a non-technical user?

If no: do not compensate with documentation; redesign onboarding.

## Gate D — after App Store launch

**Question:** Is retention driven by history, snooze, or organization?

Use the answer to choose the 1.x roadmap rather than building all advanced features blindly.

---

# Immediate next steps

1. [x] Replace the sharding hypothesis with **one catalog Notification automation + one PUSHKIN capture App Intent**.
2. [x] Prove a single physical-iPhone trigger can preserve **1000 `SelectedApps`** entries.
3. [x] Prove an uninstalled app descriptor can remain serialized in the imported catalog.
4. [x] Prove that installing that app later does **not** automatically bind it to the already-registered automation.
5. [x] Reject simple shortcut opening as a refresh mechanism.
6. [x] Verify `shortcuts://automations` and wire a PUSHKIN **Open Automation to Refresh** handoff; simulator UI test passes.
7. [x] Check for a Shortcuts action/API that enables or disables another personal automation; none exposed in the iOS 27 action registry.
8. [x] Reject **OFF -> ON** as a late-install refresh mechanism on physical hardware.
9. [x] Prove the replacement refresh path that matters for the product: **fresh one-app micro-package after installation -> enable -> capture**, on a physical iPhone.
10. [x] Measure the physical micro-package handoff: **2.28 s** from app tap in PUSHKIN to the Shortcuts import preview in the instrumented run.
11. **Next:** productize the refresh UX so PUSHKIN guides the user through the unavoidable system `Add` + automation-enable steps and then verifies coverage automatically.
12. Keep BLE/ANCS PUSHKIN Tag as Plan B only; the preferred product does not require extra hardware.
