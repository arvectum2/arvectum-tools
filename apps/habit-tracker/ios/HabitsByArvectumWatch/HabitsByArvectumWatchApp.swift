import SwiftUI

@main
struct HabitsByArvectumWatchApp: App {
    @StateObject private var syncStore = WatchHabitSyncStore()

    var body: some Scene {
        WindowGroup {
            WatchTodayView()
                .environmentObject(syncStore)
        }
    }
}
