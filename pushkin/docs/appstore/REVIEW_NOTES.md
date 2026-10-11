# App Review notes — PUSHKIN 1.0

## Purpose

PUSHKIN is a local notification-history utility. It allows a user to archive selected third-party notification text through Apple's Shortcuts Notification automation and search that history later.

## Access

- No login.
- No account.
- No subscription or purchase.
- No backend.
- No special reviewer credentials.

The app requires iOS 27 because it relies on the Notification automation behavior validated for this product.

## Core setup

1. Launch PUSHKIN.
2. On the History screen, tap **Set up PUSHKIN**.
3. iOS opens the signed PUSHKIN configuration in Shortcuts.
4. Tap **Add Shortcut** / **Add**.
5. Open Shortcuts → Automation and enable the new PUSHKIN Notification automation if iOS imports it disabled.
6. Allow it to run automatically / while locked if iOS asks.

The bundled configuration contains a maintained catalog of explicit source-app descriptors. PUSHKIN does not use a wildcard trigger and does not claim to capture every possible third-party app automatically.

If a newly installed app is in the bundled catalog, use **+ App** in PUSHKIN and import that app's small local refresh configuration. If an app is outside the catalog, PUSHKIN provides a manual Shortcuts setup guide.

## Verification

After the automation is enabled, send a real notification from a configured source app. The new item appears in PUSHKIN History. The app verifies coverage automatically after it sees a notification from an app that was just added.

Suggested reviewer test sources:
- Messages;
- Mail;
- Telegram or another installed catalog app.

## Data and external services

Notification content is stored only in the app's local SwiftData database.

Version 1.0 has:
- no server-side processing;
- no cloud sync;
- no analytics SDK;
- no advertising SDK;
- no account system;
- no runtime App Store lookup.

The app opens Apple's Shortcuts app for setup. This is the only external platform required for the core capture flow.

## Review video

Before submission, attach a physical-device screen recording showing:
1. app launch;
2. first setup handoff to Shortcuts;
3. enabling the automation;
4. receipt of a real notification;
5. the notification appearing in PUSHKIN;
6. search;
7. copy/share/delete;
8. adding one catalog app through **+ App**.

Record on the same final build submitted to review.

## Regional behavior

Core functionality is the same across App Store regions. The bundled app catalog is a maintained cross-storefront popularity composite; uncommon apps can be configured manually.

## Advertising

PUSHKIN 1.0 contains no advertising. Advertising is intentionally deferred to a later release.
