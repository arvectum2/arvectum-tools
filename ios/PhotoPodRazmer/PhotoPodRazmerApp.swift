import SwiftUI

@main
struct PhotoPodRazmerApp: App {
    @StateObject private var model = AppModel()

    init() {
        AdSDK.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.light)
        }
    }
}
