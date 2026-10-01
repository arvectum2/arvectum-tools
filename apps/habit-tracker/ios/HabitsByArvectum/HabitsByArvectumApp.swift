import SwiftData
import SwiftUI

@main
struct HabitsByArvectumApp: App {
    @UIApplicationDelegateAdaptor(HabitsAppDelegate.self) private var appDelegate
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self,
            HabitPausePeriod.self,
            HabitDayMutation.self
        ])
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--ui-testing")
        let cloudSyncDisabled = isUITesting || arguments.contains(
            "--disable-cloud-sync"
        )
        do {
            let container = try Self.makeModelContainer(
                schema: schema,
                isStoredInMemoryOnly: isUITesting,
                cloudSyncEnabled: !cloudSyncDisabled
            )
            modelContainer = container
#if DEBUG
            seedWatchSyncDemoIfRequested(container: container)
            seedFlexibleWeeklyDemoIfRequested(container: container)
            completeFirstIncompleteHabitIfRequested(container: container)
            skipFirstIncompleteHabitIfRequested(container: container)
            HabitMutationDiagnostics.runIfRequested(container: container)
#endif
            HabitNotificationActionCoordinator.shared.configure(
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
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }

    private static func makeModelContainer(
        schema: Schema,
        isStoredInMemoryOnly: Bool,
        cloudSyncEnabled: Bool
    ) throws -> ModelContainer {
        let preferred = ModelConfiguration(
            "Habits",
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [preferred]
            )
        } catch where cloudSyncEnabled {
#if DEBUG
            HabitDebugLog.emit(
                "HABITS_CLOUD_FALLBACK reason=\(error.localizedDescription)"
            )
#endif
            let localOnly = ModelConfiguration(
                "Habits",
                schema: schema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            return try ModelContainer(
                for: schema,
                configurations: [localOnly]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            TodayView()
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
                checkIns: checkIns
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
                checkIns: checkIns
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

    private func seedFlexibleWeeklyDemoIfRequested(
        container: ModelContainer
    ) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--seed-flexible-weekly-demo"
        ) else { return }

        let context = ModelContext(container)
        let existing = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard existing.isEmpty else { return }

        context.insert(
            Habit(
                name: L10n.string("quick.workout"),
                symbolName: "dumbbell.fill",
                colorHex: "8B5CF6",
                weeklyTarget: 3
            )
        )
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
                name: "Вода",
                symbolName: "drop.fill",
                colorHex: "43E5C5",
                sortOrder: 1
            )
        )
        context.insert(
            Habit(
                name: "Чтение",
                symbolName: "book.fill",
                colorHex: "8B5CF6",
                sortOrder: 0
            )
        )
        try? context.save()
    }
#endif
}
