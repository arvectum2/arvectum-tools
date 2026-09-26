# App Store — App Privacy

State for iOS 0.4.2.

## Data collection

**Data collected:** None.

**Data linked to the user:** None.

**Data used to track the user:** None.

The app has no account system, analytics SDK, advertising SDK, backend, or network-dependent image-processing service.

## Photos and files

The user explicitly selects an image with the system iOS photo picker. Image processing is performed locally on the device.

The result is written only when the user invokes the system save/export flow, or shared using the system share sheet. Temporary working files may exist in the app's local temporary directory and can be removed by the operating system.

## Tracking

Tracking: **No**.

The privacy manifest declares no tracking, no tracking domains, and no collected data types.

## Privacy policy

Public URL:

https://github.com/arvectum2/arvectum-tools/blob/main/PRIVACY.md

The repository policy covers both Android and iOS and states that selected images are processed locally.

## Export compliance

The app does not implement its own cryptography and does not contain third-party encryption libraries. The iOS bundle sets `ITSAppUsesNonExemptEncryption = false`.
