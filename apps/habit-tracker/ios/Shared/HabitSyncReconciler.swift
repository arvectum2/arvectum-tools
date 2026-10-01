import Foundation

enum HabitSyncReconciler {
    static func reconcile(
        incoming: HabitSyncSnapshot,
        pendingCommands: [HabitCompletionCommand]
    ) -> (
        snapshot: HabitSyncSnapshot,
        remainingCommands: [HabitCompletionCommand]
    ) {
        let acknowledged = Set(incoming.acknowledgedCommandIDs)
        let remaining = pendingCommands.filter {
            !acknowledged.contains($0.id)
        }

        var merged = incoming

        for command in remaining where command.dayKey == incoming.dayKey {
            guard let index = merged.habits.firstIndex(where: {
                $0.id == command.habitID
            }) else { continue }

            merged.habits[index].completed = command.completed
            merged.habits[index].skipped = false
        }

        merged.completedCount = merged.habits.filter(\.completed).count
        merged.skippedCount = merged.habits.filter {
            !$0.completed && $0.skipped
        }.count
        return (merged, remaining)
    }
}
