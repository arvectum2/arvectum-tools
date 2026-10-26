import ArvectumCore
import SwiftUI

@main
struct PhotoPodRazmerApp: App {
    @StateObject private var model = AppModel()
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
                .appStoreUpdatePrompt(enabled: !ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean"))
        }
    }
}
