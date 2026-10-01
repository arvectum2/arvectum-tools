import AppIntents
import Foundation
import WidgetKit

enum HabitWidgetIntentRuntime {
    static var processor: (() async -> Void)?
}

struct ToggleHabitWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle habit"
    static var description = IntentDescription(
        "Mark or unmark a habit from the Habits widget."
    )

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes {
        [.background, .foreground(.dynamic)]
    }

    @Parameter(title: "Habit ID")
    var habitID: String

    @Parameter(title: "Day")
    var dayKey: String

    @Parameter(title: "Completed")
    var completed: Bool

    init() {}

    init(
        habitID: String,
        dayKey: String,
        completed: Bool
    ) {
        self.habitID = habitID
        self.dayKey = dayKey
        self.completed = completed
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: habitID) else {
            return .result()
        }

        let command = HabitWidgetCommand(
            habitID: id,
            dayKey: dayKey,
            completed: completed
        )
        HabitWidgetBridge.appendCommand(command)
        HabitWidgetBridge.applyOptimistic(command)

        if let processor = HabitWidgetIntentRuntime.processor {
            await processor()
        }

        WidgetCenter.shared.reloadTimelines(
            ofKind: "HabitsTodayWidget"
        )
        return .result()
    }
}

@available(iOS, introduced: 16.4, obsoleted: 26.0)
@available(iOSApplicationExtension, unavailable)
extension ToggleHabitWidgetIntent: ForegroundContinuableIntent {}
