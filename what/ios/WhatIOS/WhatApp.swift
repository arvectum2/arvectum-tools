import SwiftUI

@main
struct WhatApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = PhoneStore()

    init() {
        PhoneConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, CaptureBrand.interfaceLocale)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        PhoneConnectivityManager.shared.requestWatchQueueRecovery()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .whatRecordingReceived)) { message in
                    store.receivedRecording(message.object as? UUID)
                }
                .onOpenURL { url in
                    if url.scheme == "what" && url.host == "record" {
                        store.showPhoneCapture = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .whatWatchQueueStatusReceived)) { _ in
                    store.reloadWatchQueueStatus()
                }
        }
    }
}
