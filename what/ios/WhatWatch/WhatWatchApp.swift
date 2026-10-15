import SwiftUI

@main
struct WhatWatchApp: App {
    init() {
        // Activate the session even on background launches that do not display a UI.
        // Otherwise durable phone acknowledgements can sit undelivered until a tap.
        WatchCaptureController.shared.activateConnectivity()
    }

    var body: some Scene {
        WindowGroup {
            CaptureView(controller: WatchCaptureController.shared)
        }
    }
}
