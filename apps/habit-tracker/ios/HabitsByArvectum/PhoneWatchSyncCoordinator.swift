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
        let calendar = Calendar.autoupdatingCurrent

        func makeHabits(for date: Date) -> [HabitSyncHabit] {
            let due = HabitTodayProjection.orderedDueHabits(
                habits: habits,
                on: date,
                checkIns: checkIns,
                skips: skips,
                pausePeriods: pausePeriods,
                calendar: calendar
            )

            return due.map { habit in
                HabitSyncHabit(
                    id: habit.id,
                    name: HabitSyncPayloadBudget.watchName(habit.name),
                    symbolName: habit.symbolName,
                    colorHex: habit.colorHex,
                    completed: HabitMetrics.isCompleted(
                        habitID: habit.id,
                        on: date,
                        checkIns: checkIns,
                        calendar: calendar,
                target: habit.dailyTarget
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
                        ) : nil,
                    dailyTarget: habit.supportsIncrementalGoal ? habit.dailyTarget : nil,
                    dailyCount: habit.supportsIncrementalGoal
                        ? HabitMultiCheck.count(
                            habitID: habit.id,
                            dayKey: HabitDayKey.make(for: date, calendar: calendar),
                            target: habit.dailyTarget, checkIns: checkIns
                        ) : nil,
                    durationStepMinutes: habit.usesDurationGoal ? 5 : nil
                )
            }
        }

        let syncHabits = makeHabits(for: now)
        let dayStart = calendar.startOfDay(for: now)
        let projectedDays = (1..<14).compactMap {
            offset -> HabitSyncDayProjection? in
            guard let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: dayStart
            ) else { return nil }
            return HabitSyncDayProjection(
                dayKey: HabitDayKey.make(for: date, calendar: calendar),
                habits: makeHabits(for: date)
            )
        }

        let rawSnapshot = HabitSyncSnapshot(
            generatedAt: .now,
            dayKey: HabitDayKey.make(for: now, calendar: calendar),
            completedCount: syncHabits.filter(\.completed).count,
            skippedCount: syncHabits.filter {
                !$0.completed && $0.skipped
            }.count,
            totalCount: syncHabits.count,
            habits: syncHabits,
            acknowledgedCommandIDs: recentCommandIDs,
            projectedDays: projectedDays
        )
        let snapshot = HabitSyncPayloadBudget.fitted(rawSnapshot)
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
                "payload=\(HabitSyncPayloadBudget.encodedSize(of: snapshot)) " +
                "horizon=\(snapshot.projectedDays?.count ?? 0) " +
                "habits=[\(states)]"
            )
        }
#endif
        return snapshot
    }

    @MainActor
    func apply(
        command: HabitCompletionCommand
    ) -> HabitSyncSnapshot? {
        guard let modelContainer else { return nil }

        if recentCommandIDs.contains(command.id) {
            return makeCurrentSnapshot()
        }

        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard habits.contains(where: { $0.id == command.habitID }) else {
            recordAcknowledgement(command.id)
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

        do {
            try context.save()
        } catch {
#if DEBUG
            HabitDebugLog.emit(
                "HABITS_WATCH_SAVE_FAILED " +
                error.localizedDescription
            )
#endif
            return makeCurrentSnapshot()
        }

        recordAcknowledgement(command.id)
        HabitReminderCoordinator.shared.dataDidChange()
        HabitWidgetCoordinator.shared.dataDidChange()
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

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let packet = try? HabitSyncCodec.packet(
            from: applicationContext
        ) else {
            return
        }
        handle(packet: packet)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
