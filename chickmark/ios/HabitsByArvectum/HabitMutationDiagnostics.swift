#if DEBUG
import Foundation
import SwiftData

enum HabitMutationDiagnostics {
    @MainActor
    static func runIfRequested(container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--diagnose-mutation-conflicts"
        ) else { return }

        let context = ModelContext(container)
        let calendar = diagnosticCalendar
        let habitID = UUID()
        let dayKey = "2026-10-01"

        let skipAccepted = HabitSkipMutation.setSkipped(
            habitID: habitID,
            dayKey: dayKey,
            skipped: true,
            context: context,
            mutationAt: Date(timeIntervalSince1970: 300),
            mutationID: UUID(
                uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFE"
            )!,
            calendar: calendar
        )

        let staleCompletionAccepted = HabitCompletionMutation.setCompletion(
            habitID: habitID,
            dayKey: dayKey,
            completed: true,
            context: context,
            mutationAt: Date(timeIntervalSince1970: 250),
            mutationID: UUID(
                uuidString: "00000000-0000-0000-0000-000000000002"
            )!,
            calendar: calendar
        )

        let skips = (try? context.fetch(FetchDescriptor<HabitSkip>())) ?? []
        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []

        let pass =
            skipAccepted &&
            !staleCompletionAccepted &&
            skips.contains {
                $0.habitID == habitID && $0.dayKey == dayKey
            } &&
            !checkIns.contains { $0.habitID == habitID }

        HabitDebugLog.emit(
            "HABITS_MUTATION_CONFLICT_DIAGNOSTIC=" +
            (pass ? "PASS" : "FAIL")
        )
    }

    private static var diagnosticCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
#endif
