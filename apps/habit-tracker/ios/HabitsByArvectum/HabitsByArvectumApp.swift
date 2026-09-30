import SwiftData
import SwiftUI

@main
struct HabitsByArvectumApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitCheckIn.self
        ])
        let configuration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TodayView()
        }
        .modelContainer(modelContainer)
    }
}
