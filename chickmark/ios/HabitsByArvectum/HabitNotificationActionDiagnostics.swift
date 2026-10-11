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

        let completedAccepted =
            HabitNotificationActionCoordinator.shared.markCompleted(
                habitID: habit.id
            )
        let skipAccepted =
            HabitNotificationActionCoordinator.shared.skipToday(
                habitID: habit.id,
                at: Date().addingTimeInterval(1)
            )

        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let skips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []
        let completedRemoved = !checkIns.contains { $0.habitID == habit.id }
        let skipped = skips.contains { $0.habitID == habit.id }

        HabitDebugLog.emit(
            "HABITS_NOTIFICATION_ACTION_DIAGNOSTIC=" +
            ((completedAccepted && skipAccepted && completedRemoved && skipped)
                ? "PASS" : "FAIL")
        )
    }
}
#endif
