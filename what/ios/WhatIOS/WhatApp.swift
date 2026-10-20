import ArvectumCore
import SwiftUI

@main
struct WhatApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = PhoneStore()

    init() {
#if !REVIEW_HANDOFF_QA
        // Standalone physical test build has NO paired Watch companion.
        // Leave the established Watch/phone test pairs untouched.
        PhoneConnectivityManager.shared.activate()
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
#if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--qa-design-filled-library") {
                    // Only the synthetic, Debug-only filled inbox fixture.
                    // Force the actual AXXXL SwiftUI layout branch under test.
                    ContentView().environment(\.dynamicTypeSize, .accessibility5)
                } else {
                    ContentView()
                }
#else
                ContentView()
#endif
            }
#if REVIEW_HANDOFF_QA
                .onAppear { PhysicalCaptureQAProbe.shared.startIfRequested(store: store) }
#endif
                .environmentObject(store)
                .environment(\.locale, CaptureBrand.interfaceLocale)
                .appStoreUpdatePrompt(locale: CaptureBrand.interfaceLocale)
                .onChange(of: scenePhase) { _, phase in
#if REVIEW_HANDOFF_QA
                    PhysicalCaptureQAProbe.shared.observeScenePhase(phase, store: store)
#endif
#if !REVIEW_HANDOFF_QA
                    if phase == .active {
                        PhoneConnectivityManager.shared.requestWatchQueueRecovery()
                    }
#endif
                }
                .onReceive(NotificationCenter.default.publisher(for: .whatRecordingReceived)) { message in
                    store.receivedRecording(message.object as? UUID)
                }
                .onOpenURL { url in
                    if url.scheme == ReviewNoteHandoff.sourceScheme && url.host == "record" {
                        store.showPhoneCapture = true
                    } else if url.scheme == ReviewNoteHandoff.sourceScheme && url.host == "note",
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
