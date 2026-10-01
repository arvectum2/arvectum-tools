import Foundation
import SwiftData
import WatchConnectivity

final class PhoneWatchSyncCoordinator: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSyncCoordinator()

    private let acknowledgementsKey = "habits.watch.recentCommandIDs"
    private var modelContainer: ModelContainer?
    private var recentCommandIDs: [UUID] = []
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    private override init() {
        super.init()
        recentCommandIDs = Self.loadCommandIDs(
            key: acknowledgementsKey
        )
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    func dataDidChange() {
        Task { @MainActor in
            await publishCurrentSnapshot()
        }
    }

    @MainActor
    func publishCurrentSnapshot() async {
        guard
            let session,
            session.activationState == .activated,
            let snapshot = makeCurrentSnapshot(),
            let packet = try? HabitSyncCodec.message(.snapshot(snapshot))
        else { return }

        try? session.updateApplicationContext(packet)

        if session.isReachable {
            session.sendMessage(packet, replyHandler: nil) { _ in }
        }
    }

    @MainActor
    private func makeCurrentSnapshot() -> HabitSyncSnapshot? {
        guard let modelContainer else { return nil }

        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(
            FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
        )) ?? []
        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>(
                sortBy: [SortDescriptor(\.day)]
            )
        )) ?? []
        let skips = (try? context.fetch(
            FetchDescriptor<HabitSkip>(
                sortBy: [SortDescriptor(\.day)]
            )
        )) ?? []
        let pausePeriods = (try? context.fetch(
            FetchDescriptor<HabitPausePeriod>(
                sortBy: [SortDescriptor(\.startedAt)]
            )
        )) ?? []

        let now = Date()
        let activeToday = HabitOrdering.sorted(
            habits.filter {
                !$0.isArchived && !$0.isPaused && HabitFrequency.isDue(
                    habit: $0,
                    on: now,
                    checkIns: checkIns,
                    skips: skips
                )
            }
        )

        let syncHabits = activeToday.map { habit in
            HabitSyncHabit(
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
                    ? habit.weeklyTarget : nil,
                weeklyCount: habit.usesFlexibleWeeklyTarget
                    ? HabitFrequency.weeklyCompletionCount(
                        habit: habit,
                        containing: now,
                        checkIns: checkIns
                    ) : nil
            )
        }

        let snapshot = HabitSyncSnapshot(
            generatedAt: .now,
            dayKey: HabitDayKey.make(for: now),
            completedCount: syncHabits.filter(\.completed).count,
            skippedCount: syncHabits.filter {
                !$0.completed && $0.skipped
            }.count,
            totalCount: syncHabits.count,
            habits: syncHabits,
            acknowledgedCommandIDs: recentCommandIDs
        )
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains(
            "--diagnose-watch-sync"
        ) {
            let states = snapshot.habits.map {
                "\($0.name)=\($0.completed ? "1" : "0")"
            }.joined(separator: ",")
            HabitDebugLog.emit(
                "HABITS_PHONE_SNAPSHOT day=\(snapshot.dayKey) " +
                "completed=\(snapshot.completedCount)/\(snapshot.totalCount) " +
                "habits=[\(states)]"
            )
        }
#endif
        return snapshot
    }

    @MainActor
    private func apply(
        command: HabitCompletionCommand
    ) -> HabitSyncSnapshot? {
        guard let modelContainer else { return nil }

        recordAcknowledgement(command.id)

        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard habits.contains(where: { $0.id == command.habitID }) else {
            return makeCurrentSnapshot()
        }

        _ = HabitCompletionMutation.setCompletion(
            habitID: command.habitID,
            dayKey: command.dayKey,
            completed: command.completed,
            context: context,
            mutationAt: command.createdAt,
            mutationID: command.id
        )

        try? context.save()
        return makeCurrentSnapshot()
    }

    @MainActor
    private func recordAcknowledgement(_ id: UUID) {
        recentCommandIDs.removeAll { $0 == id }
        recentCommandIDs.append(id)
        if recentCommandIDs.count > 50 {
            recentCommandIDs.removeFirst(
                recentCommandIDs.count - 50
            )
        }
        UserDefaults.standard.set(
            recentCommandIDs.map(\.uuidString),
            forKey: acknowledgementsKey
        )
    }

    private static func loadCommandIDs(key: String) -> [UUID] {
        let values = UserDefaults.standard.stringArray(forKey: key) ?? []
        return values.compactMap(UUID.init(uuidString:))
    }

    private func handle(
        packet: HabitSyncPacket,
        reply: (([String: Any]) -> Void)? = nil
    ) {
        Task { @MainActor in
            switch packet.kind {
            case .requestSnapshot:
                guard
                    let snapshot = makeCurrentSnapshot(),
                    let response = try? HabitSyncCodec.message(
                        .snapshot(snapshot)
                    )
                else { return }
                reply?(response)

            case .setCompletion:
                guard let command = packet.command else { return }
#if DEBUG
                if ProcessInfo.processInfo.arguments.contains(
                    "--diagnose-watch-sync"
                ) {
                    HabitDebugLog.emit(
                        "HABITS_PHONE_COMMAND habit=\(command.habitID) " +
                        "day=\(command.dayKey) completed=\(command.completed)"
                    )
                }
#endif
                let snapshot = apply(command: command)

                if let snapshot {
                    if let response = try? HabitSyncCodec.message(
                        .snapshot(snapshot)
                    ) {
                        reply?(response)
                    }
                    await publishCurrentSnapshot()
                }

            case .snapshot:
                break
            }
        }
    }

    // MARK: WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated, error == nil else { return }
        dataDidChange()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            dataDidChange()
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let packet = try? HabitSyncCodec.packet(from: message) else {
            return
        }
        handle(packet: packet, reply: replyHandler)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        guard let packet = try? HabitSyncCodec.packet(from: message) else {
            return
        }
        handle(packet: packet)
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        guard let packet = try? HabitSyncCodec.packet(from: userInfo) else {
            return
        }
        handle(packet: packet)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
