# ArvectumAdaptiveLayout — scoped Core spike (2026-10-16)

This **prototype** is not deployed to any app or App Store build yet.

## What can be shared

* **ArvectumAdaptiveMetrics**: pure, width-based content decisions for compact vs. optional two-pane layouts. Every app provides its own pane minimum, spacing and insets. Accessibility text size forces a single column.
* **ArvectumReadableColumn**: a capped readable width, centered in the available scene/window. The app owns scrolling, keyboard avoidance, safe areas and typography.
* **ArvectumAdaptiveContentStack**: opt-in flexible two-region *content* layout using SwiftUI AnyLayout. Switching its HStack/VStack structure does not deliberately recreate the child subviews, unlike separate if/else branches. Width is measured using onGeometryChange, not UIScreen.main or UIDevice identifiers.

Quick usage:

    ArvectumReadableColumn(maxWidth: 860) {
        TextEditor(text: $text)
    }

    ArvectumAdaptiveContentStack(minimumPaneWidth: 350) {
        SourcePreview()
    } trailing: {
        ExportSettings()
    }

## What must NOT be shared

* Navigation selection, editor data and media/notification lifecycle, permissions and WatchConnectivity.
* Camera, photos, Files and ad layouts; the wrapping Core stack must not assume these can be resized mid-operation.
* iPhone Duo hinge or reserved-region geometry — prefer native NavigationSplitView, split/overlay arrangement views and APIs from the latest SDK. Do not infer a fold pose from absolute points, physical-device type or orientation.

## Rollout guardrails

1. Use in two **real** app flows first (suggested pilots: What? text/list content; Photo/PDF source-preview ↔ settings). Document baseline UI, screenshot/interaction tests, compact/expanded/Dynamic Type tests, save/cancel safety.
2. Integrate into each app via a single Core source reference **or** a local SwiftPM Core dependency, **not both** in the same target. Existing apps currently include selected Core files directly.
3. Separate validation for iPhone/iPad, iPad Split View/Stage Manager, iPhone Duo closed/open and reserved regions. Xcode 27.1 is needed for Apple's Duo simulator, while the current Mac mini has Xcode 27.0.
4. Retain original app UI until two consumers pass QA and CI. Do not enable iPad family, migrate user data, or alter release branches as part of this extraction.

Test: cd core && swift test.
