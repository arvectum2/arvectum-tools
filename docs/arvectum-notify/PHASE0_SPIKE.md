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

The iOS 27 Notification trigger exposes a Notification magic variable in the
Shortcuts action editor. The editor can pass the whole object as text or select
a specific property from that object.

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

In the first physical test, before the structured properties were selected,
Shortcuts populated our `Title` parameter with the complete multiline string
while `Subtitle` and `Message` were empty.

Arvectum Notify now normalizes that measured fallback when structured fields are
otherwise empty:

- first non-empty line → title;
- remaining text → body;
- explicitly supplied Subtitle / Message fields are preserved unchanged.
This fallback remains as defensive compatibility for whole-object mappings.
The preferred iOS 27 setup is the structured App/Title/Subtitle/Text mapping.

## Spike architecture

A single iOS 27 Shortcuts Notification trigger can contain multiple selected
source apps. This was verified on the physical iPhone by adding both Telegram
and Messages to the same trigger.

The Notification magic variable exposes these selectable properties in the
Shortcuts editor:

- `App`;
- `Title`;
- `Subtitle`;
- `Text`.

No notification date/time property was exposed in the inspected property list.

Current measured setup:

- choose one or more source apps in the same Notification trigger using `+`;
- add **Arvectum Notify → Archive Notification**;
- map `Source app` → `Notification.App`;
- map `Title` → `Notification.Title`;
- map `Subtitle` → `Notification.Subtitle`;
- map `Message` → `Notification.Text`.

The App Intent now exposes only these four user-configurable fields. Arvectum Notify records capture time internally as the timestamp fallback. The current iOS 27 Notification property list does not expose a stable source bundle identifier.

Apple's iOS 27 Shortcuts model keeps automation shortcuts device-specific. App Intents expose Arvectum Notify actions to Shortcuts, while automation creation remains a user action in the Shortcuts app. The product therefore uses a guided Shortcuts handoff plus in-app verification.

The structured mapping is configured on the physical test device and has now
been confirmed at runtime by Telegram and Messages test notifications. Both
sources populated `Notification.App`, `Notification.Title`, and
`Notification.Text` as separate values; `Notification.Subtitle` was empty for
the tested notifications.

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
- Setup verification from captured records: complete.
- Diagnostics counters/reset: complete.
- Raw Shortcuts payload diagnostics: implemented for new captures.
- Duplicate-detection unit test: passing on iPhone 13 / iOS 27.0.
- iOS 27 multiline payload-normalization tests: passing on iPhone 13 / iOS 27.0.
- Physical device build/sign/install: passing with Xcode 27.0.
- App launch on iPhone 13 / iOS 27.0: verified.
- Real Telegram notification → Shortcuts → App Intent → SwiftData: verified.
- Messages notification through the same multi-app trigger: verified.
- Structured `App` / `Title` / `Subtitle` / `Text` mapping: verified at runtime.
- Cold/terminated app capture without opening the UI after install: verified.
- Locked-device Telegram capture: verified with structured fields and no duplicate candidate.
- Focus / Do Not Disturb capture: verified with structured fields and no duplicate candidate.
- Low Power Mode capture: verified with structured fields and no duplicate candidate.
- Foreground capture: verified with structured fields and no duplicate candidate.
- Explicit user force-quit capture: verified with structured fields and no duplicate candidate.
- Production project deployment target: iOS 27.

## Controlled structured test sample

Eighteen expected user-driven test notifications have now been sent after structured mapping was enabled.

The first seven covered Telegram baseline, Messages baseline, locked device, Focus, Low Power Mode, foreground, and explicit force-quit. All 7 were captured in SwiftData and none was marked as a duplicate.

A subsequent burst test sent BURST_01 through BURST_10 as ten separate Telegram notifications roughly 1-2 seconds apart while Arvectum Notify remained force-quit. All 10 were captured, in order, with zero duplicate candidates.

Current controlled sample: **18 sent / 18 captured / 0 missing / 0 duplicate candidates**.

A follow-up control push after simplifying the App Intent from six visible parameters to four (`Source app`, `Title`, `Subtitle`, `Message`) was also captured successfully, confirming that the existing Shortcuts property mappings survived the app update. The original notification timestamp and stable source bundle identifier are not exposed by the current iOS 27 Notification properties; capture time remains the timestamp fallback.

This is a positive reliability signal, but the sample is still too small and too Telegram-heavy to estimate production reliability across source apps.

## Still unproven

Gate A is **not closed yet**. The following still need measured physical-device
coverage:

- exact reliability / loss rate;
- at least 10 common source apps;
- whether the structured Notification properties behave consistently across those apps;
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

Start with 3–5 apps to validate the setup, then expand to 10 common sources.

| Source | Status |
| --- | --- |
| Telegram | Verified with test notifications |
| Messages | Verified in the same multi-app trigger |
| WhatsApp | Pending |
| Mail | Pending |
| Gmail | Pending |
| Banking app | Pending |
| Marketplace app | Pending |
| Delivery app | Pending |
| Calendar | Pending |
| Social app | Pending |

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
