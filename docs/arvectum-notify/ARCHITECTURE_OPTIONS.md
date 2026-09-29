# PUSHKIN — Universal notification capture architecture options

**Working product name:** PUSHKIN  
**Styling variants:** Push-keen / Push'k'in  
**Legacy internal codename:** Arvectum Notify

## Non-negotiable product requirement

A normal user must not maintain a manual per-app notification source list. The target experience is:

1. install PUSHKIN;
2. grant a small number of understandable system permissions;
3. receive a durable local history of notifications from all applicable apps automatically.

The Shortcuts per-app trigger remains useful as a research harness, but it is not an acceptable production architecture for the universal product.

## Architecture matrix

| Path | All apps | One-time setup | Pure iPhone | Global | App Store/public API | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Shortcuts Notification trigger | No — explicit apps required | No | Yes | Yes | Yes | Research fallback only |
| UserNotifications / NSE | No — own app only | Yes | Yes | Yes | Yes | Reject |
| Family Controls installed-app discovery | Discovers apps, not notifications | Yes | Yes | EU customer use for data access | Yes, entitlement required | Insufficient |
| MDM / supervised device | No public notification-content feed | Enterprise setup | Yes | Yes | Enterprise | Reject for consumer product |
| Accessory Notifications (iOS 27) | Yes, all applicable apps | Yes | No — accessory required | EU customer use only | Yes | Strong EU accessory path |
| ANCS Bluetooth accessory relay | Yes, Notification Center feed | Yes | No — BLE accessory required | Yes | Public BLE protocol | **Primary full-product candidate** |
| Windows companion / Phone Link style bridge | Yes while PC link is active | Yes | No — PC required | Yes | System Bluetooth path | Niche desktop variant / PoC path |
| macOS iPhone notification mirroring | Yes on supported Apple setup | Yes | No — Mac required | Region-dependent | No public third-party feed API found | Niche / not core |
| Private APIs / jailbreak / sideload-only | Potentially | Varies | Yes | Varies | No | Reject for App Store product |

## Candidate A — PUSHKIN Tag using ANCS

Apple Notification Center Service (ANCS) is a public Bluetooth Low Energy GATT service published by iOS for notification accessories. The iPhone is the Notification Provider; the accessory is the Notification Consumer.

ANCS can provide:

- application identifier;
- title;
- subtitle;
- message;
- message size;
- notification date;
- positive / negative action labels;
- added / modified / removed events;
- categories such as email, social, finance, schedule and location.

This materially improves on the Shortcuts payload because PUSHKIN can get the stable app identifier and original notification date directly from ANCS.

### Proposed architecture

```text
iOS Notification Center
        |
        | ANCS over bonded BLE
        v
PUSHKIN Tag (tiny BLE accessory)
        |
        | custom encrypted GATT characteristic
        v
PUSHKIN iOS app
        |
        v
SwiftData local history
```

The accessory firmware would act as an ANCS client and also expose a small custom GATT service to the PUSHKIN app. On `NotificationAdded`, it requests the ANCS attributes, serializes a compact record, buffers it locally, and relays it to the app.

### User setup

Target onboarding:

1. Open PUSHKIN.
2. Tap **Pair PUSHKIN Tag**.
3. Pair the accessory through AccessorySetupKit / Bluetooth.
4. Approve iPhone's system permission to share notifications with the accessory.
5. Done. No per-app matrix inside PUSHKIN.

The accessory can be a buttonless key-fob / card / phone-case insert. It does not need a display. A small LED is enough for setup/status if desired.

### Background resilience

PUSHKIN should use Core Bluetooth `bluetooth-central` background mode plus state preservation/restoration. iOS can wake a suspended app for subscribed BLE characteristic updates and can restore Bluetooth state after system termination. The tag should also maintain a local ring buffer so notification capture remains durable while the PUSHKIN app is temporarily unavailable; the app drains the backlog when it reconnects.

### Hardware candidate

Use a Nordic nRF52-class BLE SoC for the first PoC. Nordic publishes a working ANCS client example that receives iPhone notification attributes including app identifier, title, message and date. The PoC can add one custom notify characteristic and a small ring buffer.

A production device would require normal Bluetooth product qualification and regional hardware compliance. No MFi-only requirement has been identified for the public BLE ANCS path; this must still be confirmed before committing to production hardware.


### PoC hardware choice

Use **Nordic nRF52840 DK (PCA10056)** for the first physical ANCS proof. Nordic's current nRF Connect SDK ships a supported `peripheral_ancs_client` sample for this exact board. The sample bonds to an iPhone, discovers ANCS, receives Notification Source events, and can request notification attributes including the source app identifier. The DK also provides onboard debugging and UART, which materially reduces PoC risk compared with a small production module or dongle.

For production, the relay does not inherently need the DK form factor. An nRF52/nRF54-class module can be reduced to a tiny battery-powered tag, card or case insert. Apple currently states that accessories using only standard BLE do not generally require MFi; final product compliance and Bluetooth qualification still require a separate production review.

## Candidate B — Accessory Notifications on iOS 27

The new Accessory Notifications framework is functionally ideal: the system permission can allow notifications from **all applicable apps**, and `AccessoryNotification` includes rich content such as title, subtitle, body, summary, source name, identifiers, dates, icons, attachments and actions.

However:

- it requires an accessory registered with AccessorySetupKit / Accessory Transport;
- customer use of Accessory Transport / Accessory Notifications is currently limited to eligible EU iPhones signed into EU-region Apple Accounts;
- internet transport can keep forwarding to an accessory when Bluetooth is unavailable, but it does not eliminate the requirement for an accessory to be registered first.

PUSHKIN Tag could therefore use ANCS globally and optionally use Accessory Notifications on eligible EU devices for richer metadata/actions.

## Candidate C — PC companion bridge

Current Microsoft Phone Link documentation confirms that an iPhone can expose system notifications to a paired Windows PC after the user enables **Share System Notifications** in the PC's Bluetooth settings.

This proves the global Bluetooth notification-sharing path is still a current supported behavior on modern iOS. A PUSHKIN Windows companion could potentially act as a notification bridge for desktop users, but requiring a nearby PC is incompatible with the mass-market mobile-only goal.

This remains useful as:

- a research path before custom hardware;
- an optional desktop PUSHKIN product later;
- independent evidence that system-wide iPhone notification forwarding over Bluetooth is a supported platform behavior.

## Candidate D — macOS companion

After iPhone Mirroring setup, macOS can receive iPhone notifications even when the mirroring UI is not active. This proves Apple itself maintains another all-app forwarding channel.

No public macOS API was found that lets an ordinary third-party Mac app subscribe to those forwarded iPhone notifications. Accessibility/UI scraping or private Notification Center database access would create a non-App-Store, fragile product and is not suitable as the primary architecture.

## Software-only loopholes rejected or still under test

- Empty App in Shortcuts: physically tested; automation becomes invalid rather than matching every app.
- Select All in Shortcuts: no such control is exposed.
- `UNUserNotificationCenter`: only returns PUSHKIN's own delivered notifications.
- Notification Service Extension / filtering entitlement: only sees remote notifications belonging to the app that owns the extension.
- VPN / packet interception: APNs/app payload traffic is encrypted and does not expose notification content to a generic tunnel.
- Family Controls: may reveal installed bundle identifiers in eligible EU configurations but does not provide notification content or create a Shortcuts trigger.
- Supervised/MDM: can configure notification policy but no public API provides a universal notification-content stream.
- Apple Watch / watchOS companion: no public API exposes other apps' mirrored notification feed to a third-party watch app.
- Same-device virtual BLE accessory: **closed**. A physical iPhone 13 / iOS 27 CoreBluetooth PoC simultaneously advertised and scanned the same service UUID for 10 seconds after Bluetooth permission. Result: `NO SELF-DISCOVERY`; the iPhone did not discover its own BLE advertisement. A separate physical/remote Bluetooth peer is therefore required.

## Recommended next PoC

Stop investing in the Shortcuts source matrix. Preserve it only as a payload/reference harness.

Build **PUSHKIN ANCS Relay PoC**:

1. Obtain or emulate an ANCS-capable BLE Notification Consumer.
2. Pair it with the physical iPhone 13.
3. Confirm one system-level notification-sharing permission exposes notifications from apps not preconfigured in PUSHKIN.
4. Capture `AppIdentifier`, `Title`, `Subtitle`, `Message`, `Date`, category and add/remove events.
5. Add a custom BLE relay characteristic back to the PUSHKIN iOS app.
6. Test background, lock, Focus, Low Power, app termination and explicit force-quit behavior.
7. Add a hardware ring buffer and verify backlog recovery after the app reconnects.

**Gate H1:** only consider hardware productization if the relay captures arbitrary app notifications reliably with one accessory-level permission and without a per-app PUSHKIN setup list.
