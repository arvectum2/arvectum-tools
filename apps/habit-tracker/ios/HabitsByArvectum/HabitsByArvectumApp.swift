import SwiftData
import SwiftUI

@main
struct HabitsByArvectumApp: App {
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self
        ])
        let isUITesting = ProcessInfo.processInfo.arguments.contains(
            "--ui-testing"
        )
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            modelContainer = container
#if DEBUG
            seedWatchSyncDemoIfRequested(container: container)
            completeFirstIncompleteHabitIfRequested(container: container)
            skipFirstIncompleteHabitIfRequested(container: container)
#endif
            PhoneWatchSyncCoordinator.shared.configure(
                modelContainer: container
            )
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
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
            $0.schedule.includes(today) &&
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
            $0.schedule.includes(today) &&
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
                colorHex: "43E5C5"
            )
        )
        context.insert(
            Habit(
                name: "Чтение",
                symbolName: "book.fill",
                colorHex: "8B5CF6"
            )
        )
        try? context.save()
    }
#endif
}
