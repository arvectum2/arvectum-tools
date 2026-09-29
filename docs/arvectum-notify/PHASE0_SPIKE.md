# PUSHKIN — Phase 0 feasibility spike

**Working product name:** `PUSHKIN` (`Push-keen` / `Push'k'in` as styling variants).
**Legacy internal codename:** Arvectum Notify.

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

Gate A is **blocked for the full-product requirement**. Notification payload capture itself is viable, but the current iOS 27 Shortcuts path cannot provide zero-touch all-app coverage because the Notification trigger requires one or more concrete apps.

If the product is re-scoped to selected apps, the following validation remains:

- production reliability across a larger cross-app sample;
- real notification capture from all 10 configured source apps;
- whether the structured Notification properties behave consistently across those apps;
- notification summaries and hidden/sensitive previews;
- setup complexity for a non-technical user.

## Any-app trigger experiment

The full-product requirement is zero-touch capture from all notification-producing apps, not a manually curated source list. A physical iPhone 13 / iOS 27 experiment tested whether the Notification trigger can act as a wildcard.

Procedure:

- duplicated the working `Archive Notification` shortcut so the verified trigger remained untouched;
- confirmed the duplicate preserved all 10 concrete app values;
- used the system `Clear` control to remove app values one by one;
- confirmed each clear reduced the concrete app-token count;
- cleared the final remaining app value;
- inspected the resulting trigger and app picker.

Result:

- after clearing the last app, Shortcuts keeps one empty `App` placeholder rather than a wildcard value;
- the editor displays: `Чтобы включить эту автоматизацию, настройте параметр «Приложение».`;
- the automation therefore cannot be enabled with an empty App parameter;
- the App picker exposes `Cancel`, `Clear`, and concrete app rows, but no `Any App`, `All Apps`, or select-all control.

Conclusion: the iOS 27 Notification trigger requires at least one concrete source app. An empty App parameter is invalid, not a wildcard. The Shortcuts-based architecture therefore cannot satisfy the product requirement of automatically capturing notifications from every installed app without per-app source configuration.

The experimental duplicate was deleted after the test; the original working `Archive Notification` shortcut was left intact.

## Alternative system paths evaluated

After the Any-App Shortcuts experiment failed, the public iOS 27 system APIs were reviewed for a zero-touch all-app capture path.

- **UserNotifications (`UNUserNotificationCenter`)**: delivered-notification APIs return only notifications belonging to Arvectum Notify itself. They do not expose another app's Notification Center entries. Rejected for cross-app history.
- **Notification Service Extension / notification-filtering entitlement**: operates on remote notifications delivered to the app that owns the extension. The filtering entitlement can suppress those pushes, but it is not a global notification listener. Rejected for cross-app history.
- **App Intents / App Shortcuts / Shortcuts URL scheme**: can expose Notify actions automatically and open/create/run shortcuts, but public APIs do not create or configure a personal Notification automation on the user's behalf. Rejected as an automatic trigger-provisioning path.
- **Family Controls `FamilyActivityData.installedApplications`**: can expose actual installed applications only with `approvedWithDataAccess`; customer use is EU-only and requires the Family Controls App and Website Usage entitlement. This can help discover installed apps but does not expose notification contents or configure Shortcuts triggers. Insufficient.
- **MDM notification settings**: can manage notification settings on supervised iOS devices. This is an enterprise/supervised-device path, not a mass-market consumer capture API. Rejected for the product.
- **Accessory Notifications**: this is the one public iOS 27 framework found that can forward iOS system notifications from **all applicable apps** after one user authorization. It exposes notification content and an `allow` decision for all apps. However, it is designed for a companion app plus an accessory registered through AccessorySetupKit / Accessory Transport, and customer installations can use notification forwarding only on eligible EU iPhones with EU Apple Accounts. It therefore does not provide a global pure-iPhone App Store solution.

Current conclusion: no public iOS 27 API path found provides a pure-iPhone, global, zero-touch listener for notification contents from every third-party app. The universal Notify product must not proceed on the Shortcuts architecture unless Apple exposes a new system capability.

## Re-alert feasibility

Arvectum Notify can request notification authorization and schedule its own local notifications. iOS can deliver those alerts even when the app is not foregrounded. However, Notify cannot programmatically silence or suppress the original notification from another app; the user must change that source app’s notification presentation or sound settings in iOS.

For the MVP, replacing every original alert with a Notify re-alert is therefore rejected as unnecessary setup complexity. Local notifications remain appropriate for a later Snooze / Remind Later feature, where the user explicitly asks Notify to alert again.

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
| Telegram | Verified with real notifications |
| Messages | Verified with a real notification |
| WhatsApp | Verified with a real structured notification |
| Mail | Verified with a real structured notification |
| OZON | Configured in the shared trigger; runtime capture pending |
| Wildberries | Configured in the shared trigger; runtime capture pending |
| Yandex Go | Configured in the shared trigger; runtime capture pending |
| VkusVill | Verified with a real structured notification |
| Pyaterochka | Configured in the shared trigger; runtime capture pending |
| Samokat | Configured in the shared trigger; runtime capture pending |

The physical-device trigger now contains exactly 10 app values and retains the four structured mappings (`App`, `Title`, `Subtitle`, `Text`).

A full `devicectl --include-all-apps` inventory confirmed the configured third-party apps are installed. Gmail, Avito and T-Bank were not present in that inventory despite being initially reported as available, so they were not treated as valid matrix candidates on this device. Yandex Go is installed as bundle `ru.yandex.ytaxi`.

Runtime cross-app validation now covers five distinct sources: Telegram, Messages, WhatsApp, Apple Mail, and VkusVill. The notification initially thought to be from T-Bank was captured as `Сообщения` with sender `T-Mob`, so it does not count as a T-Bank app result.

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
