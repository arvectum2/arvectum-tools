import SwiftData
import SwiftUI

@main
struct HabitsByArvectumApp: App {
    @UIApplicationDelegateAdaptor(HabitsAppDelegate.self) private var appDelegate
    private let modelContainer: ModelContainer
    private let storageUnavailable: Bool

    init() {
        HabitAdSDK.configure()

        let schema = HabitsSchema.current
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--ui-testing")
        let cloudSyncDisabled = isUITesting || arguments.contains(
            "--disable-cloud-sync"
        )
        let bootstrap = Self.bootstrapModelContainer(
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            cloudSyncEnabled: !cloudSyncDisabled,
            forceRecovery: arguments.contains("--simulate-storage-recovery")
        )
        let container = bootstrap.container
        modelContainer = container
        storageUnavailable = bootstrap.storageUnavailable

        guard !bootstrap.storageUnavailable else {
            return
        }

#if DEBUG
        seedWatchSyncDemoIfRequested(container: container)
        seedScreenshotDemoIfRequested(container: container)
        seedOneOffReminderDemoIfRequested(container: container)
        seedFlexibleWeeklyDemoIfRequested(container: container)
        seedReminderSmokeIfRequested(container: container)
        completeFirstIncompleteHabitIfRequested(container: container)
        skipFirstIncompleteHabitIfRequested(container: container)
        HabitMutationDiagnostics.runIfRequested(container: container)
#endif
        if !cloudSyncDisabled {
            ChickMarkGroupsCloudSync.shared.start()
        }
        HabitNotificationActionCoordinator.shared.configure(
            modelContainer: container
        )
        HabitReminderCoordinator.shared.configure(
            modelContainer: container
        )
#if DEBUG
        HabitNotificationActionDiagnostics.runIfRequested(
            container: container
        )
#endif
        PhoneWatchSyncCoordinator.shared.configure(
            modelContainer: container
        )
        HabitWidgetCoordinator.shared.configure(
            modelContainer: container
        )
    }

    private struct ContainerBootstrap {
        let container: ModelContainer
        let storageUnavailable: Bool
    }

    private static func bootstrapModelContainer(
        schema: Schema,
        isStoredInMemoryOnly: Bool,
        cloudSyncEnabled: Bool,
        forceRecovery: Bool
    ) -> ContainerBootstrap {
#if DEBUG
        if forceRecovery {
            return emergencyContainer(schema: schema)
        }
#endif

        let habitsStoreSchema = Schema(
            versionedSchema: HabitsSchemaV1.self
        )
        let oneOffStoreSchema = Schema([OneOffReminder.self])

        let preferredHabits = ModelConfiguration(
            "Habits",
            schema: habitsStoreSchema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )
        let preferredOneOffs = ModelConfiguration(
            "OneOffReminders",
            schema: oneOffStoreSchema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        do {
            return ContainerBootstrap(
                container: try ModelContainer(
                    for: schema,
                    migrationPlan: HabitsMigrationPlan.self,
                    configurations: [preferredHabits, preferredOneOffs]
                ),
                storageUnavailable: false
            )
        } catch {
#if DEBUG
            HabitDebugLog.emit(
                "HABITS_PRIMARY_STORE_FAILED reason=\(error.localizedDescription)"
            )
#endif
        }

        if cloudSyncEnabled {
            let localHabits = ModelConfiguration(
                "Habits",
                schema: habitsStoreSchema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            let localOneOffs = ModelConfiguration(
                "OneOffReminders",
                schema: oneOffStoreSchema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )

            do {
                return ContainerBootstrap(
                    container: try ModelContainer(
                        for: schema,
                        migrationPlan: HabitsMigrationPlan.self,
                        configurations: [localHabits, localOneOffs]
                    ),
                    storageUnavailable: false
                )
            } catch {
#if DEBUG
                HabitDebugLog.emit(
                    "HABITS_LOCAL_STORE_FAILED reason=\(error.localizedDescription)"
                )
#endif
            }
        }

        return emergencyContainer(schema: schema)
    }

    private static func emergencyContainer(
        schema: Schema
    ) -> ContainerBootstrap {
        let habitsStoreSchema = Schema(
            versionedSchema: HabitsSchemaV1.self
        )
        let oneOffStoreSchema = Schema([OneOffReminder.self])
        let habitsRecovery = ModelConfiguration(
            "HabitsRecovery",
            schema: habitsStoreSchema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        let oneOffRecovery = ModelConfiguration(
            "OneOffRemindersRecovery",
            schema: oneOffStoreSchema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        do {
            return ContainerBootstrap(
                container: try ModelContainer(
                    for: schema,
                    migrationPlan: HabitsMigrationPlan.self,
                    configurations: [habitsRecovery, oneOffRecovery]
                ),
                storageUnavailable: true
            )
        } catch {
            fatalError(
                "Could not create emergency in-memory SwiftData container: \(error)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            if storageUnavailable {
                StorageRecoveryView()
            } else {
                TodayView()
            }
        }
        .modelContainer(modelContainer)
    }

#if DEBUG
    private func skipFirstIncompleteHabitIfRequested(
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

    private func completeFirstIncompleteHabitIfRequested(
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

    private func seedReminderSmokeIfRequested(
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

    private func seedOneOffReminderDemoIfRequested(
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

    private func seedFlexibleWeeklyDemoIfRequested(
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

    private func seedScreenshotDemoIfRequested(container: ModelContainer) {
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

    private func seedWatchSyncDemoIfRequested(
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
