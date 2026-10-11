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
                .onReceive(NotificationCenter.default.publisher(for: .whatRecordingReceived)) { _ in
                    store.reload()
                }
        }
    }
}
