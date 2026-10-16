import SwiftUI

@main
struct WhatApp: App {
    @StateObject private var store = PhoneStore()

    init() {
        PhoneConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onReceive(NotificationCenter.default.publisher(for: .whatRecordingReceived)) { message in
                    store.receivedRecording(message.object as? UUID)
                }
                .onOpenURL { url in
                    if url.scheme == "what" && url.host == "record" {
                        store.showPhoneCapture = true
                    } else if url.scheme == "what" && url.host == "note",
                              let id = UUID(uuidString: url.lastPathComponent) {
                        store.revealReminder(id)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .whatWatchQueueStatusReceived)) { _ in
                    store.reloadWatchQueueStatus()
                }
        }
    }
}
