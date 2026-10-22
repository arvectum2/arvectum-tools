import SwiftUI

@main
struct WhatWatchApp: App {
    init() {
        // Activate the session even on background launches that do not display a UI.
        // Otherwise durable phone acknowledgements can sit undelivered until a tap.
        let controller = WatchCaptureController.shared
        controller.activateConnectivity()
#if WATCH_PHYSICAL_QA
        // Physical watchOS app launches sometimes return before CaptureView
        // appears. Read-only or synthetic QA must be reachable from app init,
        // without requiring a screen tap or requesting microphone permission.
        Task { @MainActor in
            WatchPhysicalQAProbe.shared.startIfRequested(controller: controller)
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            CaptureView(controller: WatchCaptureController.shared)
        }
    }
}
