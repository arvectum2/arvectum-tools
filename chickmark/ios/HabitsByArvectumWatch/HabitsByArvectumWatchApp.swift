import SwiftUI
import WatchKit

/// HealthKit can launch the Watch app in the background without opening
/// the SwiftUI scene. Register observers from the application delegate.
final class ChickMarkWatchApplicationDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchHealthBackgroundDelivery.shared.configure()
    }
}

@main
struct HabitsByArvectumWatchApp: App {
    @WKApplicationDelegateAdaptor(ChickMarkWatchApplicationDelegate.self)
    private var applicationDelegate
    @StateObject private var syncStore = WatchHabitSyncStore()

    var body: some Scene {
        WindowGroup {
            WatchTodayView()
                .environmentObject(syncStore)
        }
    }
}
