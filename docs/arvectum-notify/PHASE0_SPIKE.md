# Arvectum Notify — Phase 0 feasibility spike

**Status:** physical-device validation in progress
**Date:** 2026-09-28  
**Target:** iOS 27+

## What is already proven

Arvectum Notify exposes an App Intent named **Archive Notification** and stores
captures locally in SwiftData without requiring the app UI to open.

On a physical **iPhone 13 running iOS 27.0**, a Shortcuts **Notification**
automation scoped to Telegram successfully invoked the App Intent when a real
third-party Telegram push arrived.

Two real Telegram notifications were captured during the spike:

| Capture time | Source | Raw Shortcuts string |
| --- | --- | --- |
| 22:02:05 | Telegram | `<sender A>\n<message A>` |
| 22:20:06 | Telegram | `<sender B>\ntest` |

Both records were written through capture channel `shortcuts-notification`.
No duplicate candidate was reported for either capture.

This proves the core capture path works on physical iOS 27 hardware and does not
require Arvectum Notify to be in the foreground at the moment the notification
arrives.
## Measured payload behavior

The iOS 27 Notification trigger exposes one notification magic variable in the
Shortcuts action editor.

When that magic variable is passed into a String parameter of our App Intent,
Telegram notifications were measured as:

```text
<title or sender>
<message>
```

For example:

```text
<sender>
test
```

In the first physical test, Shortcuts therefore populated our `Title` parameter
with the complete multiline string while `Subtitle` and `Message` were empty.

Arvectum Notify now normalizes that measured fallback when structured fields are
otherwise empty:

- first non-empty line → title;
- remaining text → body;
- explicitly supplied Subtitle / Message fields are preserved unchanged.
This fallback must still be tested across the full source-app matrix before it is
treated as universal behavior.

## Spike architecture

One Shortcuts Notification automation is configured per source app.

Current measured setup:

- choose a source app in the Notification trigger;
- add **Arvectum Notify → Archive Notification**;
- set `Source app` once as a literal;
- set `Title` to the Notification magic variable;
- leave `Subtitle` / `Message` empty unless a source-specific structured mapping
  is later proven;
- `receivedAt` currently falls back to capture time when Shortcuts does not
  expose a separate original timestamp;
- bundle identifier remains optional and was not exposed in the Telegram test.

The app stores:

- source app;
- optional bundle identifier;
- normalized title;
- normalized subtitle;
- normalized message body;
- received timestamp;
- capture timestamp;
- capture channel;
- possible-duplicate flag.
Duplicate diagnostics flag identical source/title/subtitle/body payloads captured
within 10 seconds. The record is still retained so Phase 0 can measure
duplication instead of hiding it.

## Local implementation status

- Native SwiftUI app shell: complete.
- Bundle ID: `ru.arvectum.tools.notify`.
- SwiftData local persistence: complete.
- App Intent input path: complete.
- Minimal Inbox: complete.
- Guided Setup screen: complete.
- Diagnostics counters/reset: complete.
- Raw Shortcuts payload diagnostics: implemented for new captures.
- Duplicate-detection unit test: passing on iPhone 13 / iOS 27.0.
- iOS 27 multiline payload-normalization tests: passing on iPhone 13 / iOS 27.0.
- Physical device build/sign/install: passing with Xcode 27.0.
- App launch on iPhone 13 / iOS 27.0: verified.
- Real Telegram notification → Shortcuts → App Intent → SwiftData: verified.
- Production project deployment target: iOS 27.

## Still unproven

Gate A is **not closed yet**. The following still need measured physical-device
coverage:

- exact reliability / loss rate;
- app foreground;
- app background;
- app force-quit;
- device locked;
- Focus mode;
- Low Power Mode;
- at least 10 common source apps;
- whether the multiline String fallback is consistent across those apps;
- whether an original notification timestamp is available;
- source bundle identifier exposure;
- attachments / URLs / other structured metadata;
- notification summaries and hidden/sensitive previews;
- re-alert behavior;
- setup complexity for a non-technical user.

## Physical-device test protocol

For each condition, send a known count of notifications and record:

- notifications sent;
- records captured;
- missing records;
- duplicate records;
- raw Shortcuts text;
- normalized title;
- normalized subtitle;
- normalized body;
- capture timestamp;
- any original timestamp if available;
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

## Gate A

Remain at Phase 0 until physical-device tests show that capture reliability,
payload usefulness, and setup complexity are acceptable for a mass-market app.

The first physical Telegram captures are a positive feasibility result, not yet
a reliability result.

## Preliminary Telegram observations

Two user-driven Telegram test pushes sent after the automation was configured
were both eventually present in SwiftData, with zero duplicate candidates in
that small sample.

The later capture occurred while Arvectum Notify was not the foreground app,
which verifies the background/suspended capture path for this scenario.

One test capture was not present during the first immediate checks and appeared
on a later re-check. Because the original notification timestamp is not exposed
in the current setup, exact latency cannot yet be calculated. Phase 0 therefore
tracks **delayed capture** separately from **missing capture**.

The spike now stores optional raw Shortcuts inputs, normalization mode, and
timestamp source for new records. Existing records remain readable through a
lightweight SwiftData schema migration.
