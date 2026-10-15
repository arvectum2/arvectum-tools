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
        // A matching iPhone snapshot is NOT an acknowledgement: it might be
        // coincidentally equal to a Watch command that has never arrived.
        // Example: a Health-derived completion disappears when access is
        // revoked, matching a pending Watch undo; dropping that undo here
        // loses the user's explicit manual override when Health returns.
        // Keep durable retry until the phone explicitly ACKs the command ID.
        let remaining = pendingCommands.filter {
            !acknowledged.contains($0.id)
        }

        let shouldKeepCurrent = currentSnapshot.map {
            $0.dayKey == incoming.dayKey &&
            $0.generatedAt > incoming.generatedAt
        } ?? false
        var merged = incoming
        if shouldKeepCurrent, let currentSnapshot {
            merged = currentSnapshot
        }

        // A more recent displayed snapshot might still contain a marker
        // from a command already ACKed by the phone. Recompute pending
        // markers exclusively from the surviving queue, not prior UI state.
        for index in merged.habits.indices {
            merged.habits[index].watchPendingManualAction = nil
        }

        for command in remaining where command.dayKey == incoming.dayKey {
            guard let index = merged.habits.firstIndex(where: {
                $0.id == command.habitID
            }) else { continue }

            if merged.habits[index].healthRuleMetric != nil {
                merged.habits[index].watchPendingManualAction = true
            }
            merged.habits[index].completed = command.completed
            if let target = merged.habits[index].dailyTarget {
                let desired = min(
                    max(command.desiredCount ?? (command.completed ? target : 0), 0),
                    target
                )
                merged.habits[index].dailyCount = desired
                merged.habits[index].completed = desired == target
            }
            merged.habits[index].skipped = false
        }

        merged.completedCount = merged.habits.filter(\.completed).count
        merged.skippedCount = merged.habits.filter {
            !$0.completed && $0.skipped
        }.count
        return (merged, remaining)
    }

}
