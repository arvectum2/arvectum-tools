import SwiftData
import SwiftUI

@main
struct ArvectumNotifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
