#if DEBUG
import Foundation
import SwiftData

enum HabitNotificationActionDiagnostics {
    @MainActor
    static func runIfRequested(container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--diagnose-notification-action"
        ) else { return }

        let context = ModelContext(container)
        let habit = Habit(
            name: "Notification action",
            sortOrder: 0
        )
        context.insert(habit)
        try? context.save()

        let accepted =
            HabitNotificationActionCoordinator.shared.markCompleted(
                habitID: habit.id
            )

        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let completed = checkIns.contains { $0.habitID == habit.id }

        HabitDebugLog.emit(
            "HABITS_NOTIFICATION_ACTION_DIAGNOSTIC=" +
            ((accepted && completed) ? "PASS" : "FAIL")
        )
    }
}
#endif
