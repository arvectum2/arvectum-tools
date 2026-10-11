import Foundation
import SwiftData

extension HabitsByArvectumApp {
#if DEBUG
    func skipFirstIncompleteHabitIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--debug-skip-first-incomplete-habit"
        ) else { return }

        let context = ModelContext(container)
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
        )) ?? []
        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let skips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []
        let today = Date()

        guard let habit = habits.first(where: {
            !$0.isArchived &&
            HabitFrequency.isDue(
                habit: $0,
                on: today,
                checkIns: checkIns,
                skips: skips
            ) &&
            !HabitMetrics.isCompleted(
                habitID: $0.id,
                on: today,
                checkIns: checkIns,
                target: $0.dailyTarget
            ) &&
            !HabitMetrics.isSkipped(
                habitID: $0.id,
                on: today,
                skips: skips
            )
        }) else { return }

        context.insert(
            HabitSkip(
                habitID: habit.id,
                day: today
            )
        )
        try? context.save()
    }

    func completeFirstIncompleteHabitIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--debug-complete-first-incomplete-habit"
        ) else { return }

        let context = ModelContext(container)
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
        )) ?? []
        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let today = Date()

        guard let habit = habits.first(where: {
            !$0.isArchived &&
            HabitFrequency.isDue(
                habit: $0,
                on: today,
                checkIns: checkIns
            ) &&
            !HabitMetrics.isCompleted(
                habitID: $0.id,
                on: today,
                checkIns: checkIns,
                target: $0.dailyTarget
            )
        }) else { return }

        context.insert(
            HabitCheckIn(
                habitID: habit.id,
                day: today
            )
        )
        try? context.save()
    }

    func seedReminderSmokeIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--seed-reminder-smoke"
        ) else { return }

        let calendar = Calendar.autoupdatingCurrent
        let fireDate = calendar.date(
            byAdding: .minute,
            value: 2,
            to: Date()
        ) ?? Date().addingTimeInterval(120)
        let components = calendar.dateComponents(
            [.hour, .minute],
            from: fireDate
        )

        let context = ModelContext(container)
        context.insert(
            Habit(
                name: "Reminder smoke",
                symbolName: "bell.fill",
                colorHex: "F59E0B",
                reminderEnabled: true,
                reminderHour: components.hour ?? 20,
                reminderMinute: components.minute ?? 0
            )
        )
        try? context.save()

        HabitDebugLog.emit(
            "HABITS_REMINDER_SMOKE_FIRE=" + fireDate.ISO8601Format()
        )
    }

    func seedOneOffReminderDemoIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--seed-oneoff-demo"
        ) else { return }

        let context = ModelContext(container)
        let existing = (try? context.fetch(
            FetchDescriptor<OneOffReminder>()
        )) ?? []
        guard existing.isEmpty else { return }

        let dueAt = Calendar.autoupdatingCurrent.date(
            byAdding: .hour,
            value: 2,
            to: Date()
        ) ?? Date().addingTimeInterval(7200)

        context.insert(
            OneOffReminder(
                title: L10n.string("oneoff.demo.marathon"),
                dueAt: dueAt
            )
        )
        try? context.save()
    }

    func seedFlexibleWeeklyDemoIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--seed-flexible-weekly-demo"
        ) else { return }

        let context = ModelContext(container)
        let existing = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard existing.isEmpty else { return }

        let createdAt = Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: -7,
            to: Date()
        ) ?? Date()

        context.insert(
            Habit(
                name: L10n.string("quick.workout"),
                symbolName: "dumbbell.fill",
                colorHex: "8B5CF6",
                createdAt: createdAt,
                weeklyTarget: 3
            )
        )
        try? context.save()
    }

    func seedScreenshotDemoIfRequested(container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--seed-screenshot-demo"
        ) else { return }
        let context = ModelContext(container)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard !habits.contains(where: {
            $0.id == UUID(uuidString: "00000000-0000-0000-0000-000000000003")
        }) else { return }
        let habit = Habit(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: L10n.string("quick.multicheck"),
            symbolName: "drop.fill",
            colorHex: "43E5C5",
            createdAt: Calendar.current.startOfDay(for: .now),
            weeklyTarget: 1005,
            sortOrder: 2
        )
        context.insert(habit)
        if let basic = habits.first(where: {
            $0.id == UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        }) {
            basic.name = L10n.string("quick.walk")
            basic.symbolName = "figure.walk"
            basic.colorHex = "FB923C"
        }
        for slot in 1...3 {
            let key = HabitDayKey.make(for: .now)
            let checkIn = HabitCheckIn(
                id: HabitMultiCheck.slotID(
                    habitID: habit.id, dayKey: key, slot: slot
                ),
                habitID: habit.id, day: .now
            )
            checkIn.dayKey = key
            context.insert(checkIn)
        }
        if let reading = habits.first(where: {
            $0.id == UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        }), let twoWeeksAgo = Calendar.current.date(
            byAdding: .day, value: -14, to: Calendar.current.startOfDay(for: .now)
        ) {
            reading.createdAt = twoWeeksAgo
            for offset in [0, 1, 2, 3, 4, 6, 7, 8, 10, 11, 12] {
                guard let date = Calendar.current.date(
                    byAdding: .day, value: -offset, to: .now
                ) else { continue }
                context.insert(HabitCheckIn(
                    habitID: reading.id, day: date
                ))
            }
        }
        try? context.save()
    }

    func seedWatchSyncDemoIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--seed-watch-sync-demo"
        ) else { return }

        let context = ModelContext(container)
        let existing = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard existing.isEmpty else { return }

        context.insert(
            Habit(
                id: UUID(
                    uuidString: "00000000-0000-0000-0000-000000000002"
                )!,
                name: L10n.string("quick.water"),
                symbolName: "drop.fill",
                colorHex: "43E5C5",
                sortOrder: 1
            )
        )
        context.insert(
            Habit(
                id: UUID(
                    uuidString: "00000000-0000-0000-0000-000000000001"
                )!,
                name: L10n.string("quick.reading"),
                symbolName: "book.fill",
                colorHex: "8B5CF6",
                sortOrder: 0
            )
        )
        try? context.save()
    }
#endif
}
