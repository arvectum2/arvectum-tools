import SwiftData

final class HabitReminderCoordinator {
    static let shared = HabitReminderCoordinator()

    private var modelContainer: ModelContainer?
    private var isRefreshing = false
    private var needsRefresh = false

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
            await requestRefresh()
        }
    }

    @MainActor
    func refreshNow() async {
        await requestRefresh()
    }

    @MainActor
    private func requestRefresh() async {
        if isRefreshing {
            needsRefresh = true
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        repeat {
            needsRefresh = false
            await rebuildSchedule()
        } while needsRefresh
    }

    @MainActor
    private func rebuildSchedule() async {
        guard let modelContainer else { return }

        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>()
        )) ?? []
        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let skips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []

        _ = await HabitReminderScheduler.syncAll(
            habits: habits,
            checkIns: checkIns,
            skips: skips
        )
    }
}
