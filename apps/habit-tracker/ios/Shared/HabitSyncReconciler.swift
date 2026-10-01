import Foundation

enum HabitSyncReconciler {
    static func reconcile(
        incoming: HabitSyncSnapshot,
        currentSnapshot: HabitSyncSnapshot? = nil,
        pendingCommands: [HabitCompletionCommand]
    ) -> (
        snapshot: HabitSyncSnapshot,
        remainingCommands: [HabitCompletionCommand]
    ) {
        let acknowledged = Set(incoming.acknowledgedCommandIDs)
        let remaining = pendingCommands.filter { command in
            guard !acknowledged.contains(command.id) else {
                return false
            }
            return !authoritativeSnapshot(
                incoming,
                satisfies: command
            )
        }

        let shouldKeepCurrent = currentSnapshot.map {
            $0.dayKey == incoming.dayKey &&
            $0.generatedAt > incoming.generatedAt
        } ?? false
        var merged = incoming
        if shouldKeepCurrent, let currentSnapshot {
            merged = currentSnapshot
        }

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

    private static func authoritativeSnapshot(
        _ snapshot: HabitSyncSnapshot,
        satisfies command: HabitCompletionCommand
    ) -> Bool {
        guard
            snapshot.dayKey == command.dayKey,
            snapshot.generatedAt >= command.createdAt,
            let habit = snapshot.habits.first(where: {
                $0.id == command.habitID
            })
        else {
            return false
        }

        return habit.completed == command.completed && !habit.skipped
    }
}
