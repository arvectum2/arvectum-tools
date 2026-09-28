# Arvectum Notify — Phase 0 feasibility spike

**Status:** implementation ready for physical-device validation  
**Date:** 2026-09-28  
**Target:** iOS 27+

## What is already proven

Apple Shortcuts includes a Notification automation trigger. It can be scoped to a
specific source app and filtered by notification Message, Subtitle, or Title.

Official references:

- Apple Developer — WWDC26, “What’s new in Shortcuts”:
  https://developer.apple.com/videos/play/wwdc2026/310/
- Apple Support — “Event triggers in Shortcuts on iPhone or iPad”:
  https://support.apple.com/guide/shortcuts/apd932ff833f/ios

Arvectum Notify now exposes an App Intent named **Archive Notification**.
The intended automation passes notification fields into this intent and the intent
writes them to SwiftData without opening the app.

## Spike architecture

One Shortcuts Notification automation is configured per source app.

The automation uses:
- source app name: configured as a literal once during setup;
- Title: mapped from the notification event when available;
- Subtitle: mapped from the notification event when available;
- Message: mapped from the notification event when available;
- received time: passed when Shortcuts exposes it, otherwise capture time;
- bundle identifier: optional; not assumed to be available from the trigger.

The app stores:
- source app;
- optional bundle identifier;
- title;
- subtitle;
- message body;
- received timestamp;
- capture timestamp;
- capture channel;
- possible-duplicate flag.

Duplicate diagnostics currently flag identical source/title/subtitle/body payloads
captured within 10 seconds. The record is still retained so Phase 0 can measure
duplication instead of hiding it.

## Local implementation status

- Native SwiftUI app shell: complete.
- Bundle ID: `ru.arvectum.tools.notify`.
- SwiftData local persistence: complete.
- App Intent input path: complete.
- Minimal Inbox: complete.
- Guided Setup screen: complete.
- Diagnostics counters/reset: complete.
- Duplicate-detection unit test: passing.
- Simulator build: passing with Xcode 26.6 / iOS 26.5 compatibility override.
- Production project deployment target: iOS 27.
## Current environment blocker

Xcode 27.0 is installed on the Mac mini, but its Apple SDK license has not yet
been accepted. The active developer directory is still Xcode 26.6.

Do not accept the Xcode license automatically on behalf of the account holder.
After it is accepted interactively, rerun the build and physical-device checks
with Xcode 27.

This means the code path is compiled and unit-tested, but **Gate A is not closed**:
we have not yet recorded a real third-party notification through the iOS 27
Notification automation on a physical iPhone.

## Physical-device test protocol

For each condition, send a known count of notifications and record:
- notifications sent;
- records captured;
- missing records;
- duplicate records;
- title present;
- subtitle present;
- message present;
- timestamp quality;
- unexpected truncation or transformation.

Run each selected source app under:
1. Arvectum Notify open.
2. Arvectum Notify backgrounded.
3. Arvectum Notify force-quit.
4. Device locked.
5. Focus mode enabled.
6. Low Power Mode enabled.
## Source-app matrix

Start with 3–5 apps to validate the setup, then expand to:
- Messages
- Telegram
- WhatsApp
- Mail
- Gmail
- banking app
- marketplace app
- delivery app
- Calendar
- social app

## Unknowns that must be measured

Apple documents app selection and filters for Message, Subtitle, and Title.
The following must not be assumed until measured on iOS 27:
- whether source bundle identifier is exposed to shortcut actions;
- whether a separate original notification timestamp is exposed;
- whether attachments are exposed;
- whether URLs are exposed as structured data;
- behavior for notification summaries;
- behavior for sensitive/hidden previews;
- behavior when the source app or Notify is force-quit;
- loss/duplication rate under Focus and Low Power Mode;
- whether a re-alert flow can avoid creating confusing duplicate notifications.

## Gate A

Remain at Phase 0 until physical-device tests show that capture reliability,
payload usefulness, and setup complexity are acceptable for a mass-market app.
