import SwiftData
import SwiftUI

@main
struct ArvectumNotifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(NotifyStore.modelContainer)
    }
}
