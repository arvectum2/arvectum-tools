import SwiftData
import SwiftUI

@main
struct ArvectumNotifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .appStoreUpdatePrompt()
                #if DEBUG && PUSHKIN_PHYSICAL_QA
                .onAppear {
                    PersistentUpgradeQAProbe.runIfRequested()
                    DirectIntentQAProbe.runIfRequested()
                }
                #endif
        }
        .modelContainer(NotifyStore.modelContainer)
    }
}
