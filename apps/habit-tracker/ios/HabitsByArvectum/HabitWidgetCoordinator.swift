import Foundation
import SwiftData
import WidgetKit

final class HabitWidgetCoordinator {
    static let shared = HabitWidgetCoordinator()

    private var modelContainer: ModelContainer?

    private init() {}

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refresh()
    }

    func dataDidChange() {
        refresh()
    }

    func refresh() {
        Task { @MainActor in
            processPendingCommands()
            publishSnapshot()
        }
    }

    @MainActor
    private func processPendingCommands() {
        guard let modelContainer else { return }

        let commands = HabitWidgetBridge.loadCommands()
            .sorted { $0.createdAt < $1.createdAt }
        guard !commands.isEmpty else { return }

        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        var processed = Set<UUID>()

        for command in commands {
            guard habits.contains(where: {
                $0.id == command.habitID && !$0.isArchived && !$0.isPaused
            }) else {
                processed.insert(command.id)
                continue
            }

            _ = HabitCompletionMutation.setCompletion(
                habitID: command.habitID,
                dayKey: command.dayKey,
                completed: command.completed,
                context: context,
                mutationAt: command.createdAt,
                mutationID: command.id
            )

            processed.insert(command.id)
        }

        if !processed.isEmpty {
            try? context.save()
            HabitWidgetBridge.removeCommands(ids: processed)
            PhoneWatchSyncCoordinator.shared.dataDidChange()
            HabitReminderCoordinator.shared.dataDidChange()
        }
    }

    @MainActor
    private func publishSnapshot() {
        guard let modelContainer else { return }

        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
        )) ?? []
        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let skips = (try? context.fetch(FetchDescriptor<HabitSkip>())) ?? []
        let pausePeriods = (try? context.fetch(
            FetchDescriptor<HabitPausePeriod>()
        )) ?? []

        let now = Date()
        let due = HabitOrdering.sorted(
            habits.filter {
                !$0.isArchived &&
                !$0.isPaused &&
                HabitFrequency.isDue(
                    habit: $0,
                    on: now,
                    checkIns: checkIns,
                    skips: skips,
                    pausePeriods: pausePeriods
                )
            }
        )

        let widgetHabits = due.map { habit in
            HabitWidgetHabit(
                id: habit.id,
                name: habit.name,
                symbolName: habit.symbolName,
                colorHex: habit.colorHex,
                completed: HabitMetrics.isCompleted(
                    habitID: habit.id,
                    on: now,
                    checkIns: checkIns
                ),
                skipped: HabitMetrics.isSkipped(
                    habitID: habit.id,
                    on: now,
                    skips: skips
                ),
                streak: HabitMetrics.currentStreak(
                    habit: habit,
                    checkIns: checkIns,
                    skips: skips,
                    pausePeriods: pausePeriods
                ),
                weeklyTarget: habit.usesFlexibleWeeklyTarget
                    ? HabitFrequency.effectiveWeeklyTarget(
                        habit: habit,
                        containing: now,
                        skips: skips,
                        pausePeriods: pausePeriods
                    ) : nil,
                weeklyCount: habit.usesFlexibleWeeklyTarget
                    ? HabitFrequency.weeklyCompletionCount(
                        habit: habit,
                        containing: now,
                        checkIns: checkIns
                    ) : nil
            )
        }

        let snapshot = HabitWidgetSnapshot(
            generatedAt: .now,
            dayKey: HabitDayKey.make(for: now),
            completedCount: widgetHabits.filter(\.completed).count,
            skippedCount: widgetHabits.filter {
                !$0.completed && $0.skipped
            }.count,
            totalCount: widgetHabits.count,
            habits: widgetHabits
        )

        HabitWidgetBridge.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadTimelines(
            ofKind: "HabitsTodayWidget"
        )
    }

    private func date(from dayKey: String) -> Date? {
        let parts = dayKey.split(separator: "-").compactMap {
            Int(String($0))
        }
        guard parts.count == 3 else { return nil }

        var components = DateComponents()
        components.calendar = .autoupdatingCurrent
        components.timeZone = .autoupdatingCurrent
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 12
        return components.date
    }
}

enum HabitDataChangeNotifier {
    static func notify() {
        PhoneWatchSyncCoordinator.shared.dataDidChange()
        HabitWidgetCoordinator.shared.dataDidChange()
        HabitReminderCoordinator.shared.dataDidChange()
    }
}
