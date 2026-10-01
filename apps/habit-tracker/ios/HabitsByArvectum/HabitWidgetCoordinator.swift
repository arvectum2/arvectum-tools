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
        let calendar = Calendar.autoupdatingCurrent

        func makeSnapshot(for date: Date) -> HabitWidgetSnapshot {
            let due = HabitOrdering.sorted(
                habits.filter {
                    !$0.isArchived &&
                    !$0.isPaused &&
                    HabitFrequency.isDue(
                        habit: $0,
                        on: date,
                        checkIns: checkIns,
                        skips: skips,
                        pausePeriods: pausePeriods,
                        calendar: calendar
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
                        on: date,
                        checkIns: checkIns,
                        calendar: calendar
                    ),
                    skipped: HabitMetrics.isSkipped(
                        habitID: habit.id,
                        on: date,
                        skips: skips,
                        calendar: calendar
                    ),
                    streak: HabitMetrics.currentStreak(
                        habit: habit,
                        checkIns: checkIns,
                        skips: skips,
                        pausePeriods: pausePeriods,
                        today: date,
                        calendar: calendar
                    ),
                    weeklyTarget: habit.usesFlexibleWeeklyTarget
                        ? HabitFrequency.effectiveWeeklyTarget(
                            habit: habit,
                            containing: date,
                            skips: skips,
                            pausePeriods: pausePeriods,
                            calendar: calendar
                        ) : nil,
                    weeklyCount: habit.usesFlexibleWeeklyTarget
                        ? HabitFrequency.weeklyCompletionCount(
                            habit: habit,
                            containing: date,
                            checkIns: checkIns,
                            calendar: calendar
                        ) : nil
                )
            }

            return HabitWidgetSnapshot(
                generatedAt: now,
                dayKey: HabitDayKey.make(for: date, calendar: calendar),
                completedCount: widgetHabits.filter(\.completed).count,
                skippedCount: widgetHabits.filter {
                    !$0.completed && $0.skipped
                }.count,
                totalCount: widgetHabits.count,
                habits: widgetHabits
            )
        }

        let dayStart = calendar.startOfDay(for: now)
        let horizon = (0..<14).compactMap { offset -> HabitWidgetSnapshot? in
            guard let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: dayStart
            ) else { return nil }
            return makeSnapshot(for: date)
        }

        guard let snapshot = horizon.first else { return }
        HabitWidgetBridge.saveSnapshot(snapshot)
        HabitWidgetBridge.saveHorizon(horizon)
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
