# Arvectum Notify — Roadmap

## Product goal

Build a mass-market iOS utility that solves one simple pain exceptionally well:

> Never lose an important notification again.

Arvectum Notify should be understandable without technical knowledge, useful within the first minute after setup, privacy-first, and suitable as the first broad-consumer app in the Arvectum utility line.

The product starts with notification history and progressively expands into snooze, reminders, prioritization, digests, and simple automation.

---

## Product principles

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
- [ ] Verify real notification capture from all 10 configured source apps.
- [ ] Re-check source-app availability when the installed-app set changes.
- [x] Measure event loss / duplication.
- [x] Reduce setup to one multi-app Notification trigger, four field mappings, and automatic in-app verification.
- [ ] Validate the guided setup with a non-technical user.
- [x] Determine re-alert viability: local Notify alerts are possible, but silencing third-party originals requires user notification settings; defer re-alert to Snooze rather than MVP capture.
- [x] Document platform limitations in `docs/arvectum-notify/PHASE0_SPIKE.md`.

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

If no: stop or redefine the product before building UI.

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

1. Build the Phase 0 feasibility spike.
2. Capture the first real third-party notification.
3. Document exact payload and platform limitations.
4. Build a minimal local inbox.
5. Validate the setup flow with a non-technical user.
6. Only then freeze the MVP specification.
