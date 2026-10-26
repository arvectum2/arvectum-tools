import ArvectumCore
import SwiftUI

@main
struct PhotoPodRazmerApp: App {
    @StateObject private var model = AppModel()
    // Clean DEBUG screenshot capture does not show the first-run consent overlay.
    @State private var showingInitialAdConsent =
        AdConsentStore.storedConsent == nil &&
        !ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean")

    init() {
#if DEBUG
        if !ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean") {
            AdSDK.configure()
        }
#else
        AdSDK.configure()
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .appStoreUpdatePrompt(enabled: !showingInitialAdConsent &&
                    !ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean"))
                .sheet(isPresented: $showingInitialAdConsent) {
                    AdConsentSheet { value in
                        AdSDK.setUserConsent(value)
                        showingInitialAdConsent = false
                    }
                    .interactiveDismissDisabled()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                }
        }
    }
}
