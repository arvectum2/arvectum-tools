import ArvectumCore
import SwiftUI

@main
struct PhotoPodRazmerApp: App {
    @StateObject private var model = AppModel()
    @State private var showingInitialAdConsent = AdConsentStore.storedConsent == nil

    init() {
        AdSDK.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .appStoreUpdatePrompt(enabled: !showingInitialAdConsent)
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
