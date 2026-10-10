import Foundation
import SwiftUI
import WatchConnectivity
import WidgetKit

final class WatchHabitSyncStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var snapshot: HabitSyncSnapshot
    @Published private(set) var isReachable = false

    private let snapshotKey = "habits.watch.cachedSnapshot"
    private let pendingKey = "habits.watch.pendingCommands"
    private var pendingCommands: [HabitCompletionCommand]
    private var durableFlushWorkItem: DispatchWorkItem?
#if DEBUG
    private var didAutoToggleForDebug = false
    private var didAutoToggleCachedForDebug = false
    private var didStressToggleForDebug = false
#endif

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        if let cached = Self.load(
            HabitSyncSnapshot.self,
            key: "habits.watch.cachedSnapshot"
        ) {
            snapshot = WatchComplicationBridge.currentSnapshot(cached)
        } else {
            snapshot = WatchComplicationBridge.loadCurrentSnapshot()
        }
        pendingCommands = Self.load(
            [HabitCompletionCommand].self,
            key: "habits.watch.pendingCommands"
        ) ?? []

        super.init()

        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    func toggle(_ habit: HabitSyncHabit) {
        guard
            let index = snapshot.habits.firstIndex(where: { $0.id == habit.id }),
            !snapshot.dayKey.isEmpty
        else { return }

        let desiredState = snapshot.habits[index].skipped
            ? true
            : !snapshot.habits[index].completed
        snapshot.habits[index].completed = desiredState
        if let target = snapshot.habits[index].dailyTarget {
            snapshot.habits[index].dailyCount = desiredState ? target : 0
        }
        snapshot.habits[index].skipped = false
        snapshot.completedCount = snapshot.habits.filter(\.completed).count
        snapshot.skippedCount = snapshot.habits.filter {
            !$0.completed && $0.skipped
        }.count
        snapshot.generatedAt = .now
        cacheSnapshot()

        let command = HabitCompletionCommand(
            habitID: habit.id,
            dayKey: snapshot.dayKey,
            completed: desiredState
        )
        pendingCommands = HabitCompletionCommandQueue.appending(
            command,
            to: pendingCommands
        )
        persistPending()
        send(command)
    }

    /// Partial progress is expressed as a desired count (not a blind toggle).
    /// The same durable queue, ACK and mutation ledger handle offline replay.
    func adjust(_ habit: HabitSyncHabit, by delta: Int) {
        guard let index = snapshot.habits.firstIndex(where: { $0.id == habit.id }),
              let target = snapshot.habits[index].dailyTarget,
              let current = snapshot.habits[index].dailyCount,
              target > 1, !snapshot.dayKey.isEmpty else { return }
        let desired = min(max(current + delta, 0), target)
        guard desired != current else { return }
        snapshot.habits[index].dailyCount = desired
        snapshot.habits[index].completed = desired == target
        snapshot.habits[index].skipped = false
        snapshot.completedCount = snapshot.habits.filter(\.completed).count
        snapshot.skippedCount = snapshot.habits.filter { !$0.completed && $0.skipped }.count
        snapshot.generatedAt = .now
        cacheSnapshot()

        let command = HabitCompletionCommand(
            habitID: habit.id, dayKey: snapshot.dayKey,
            completed: desired == target, desiredCount: desired
        )
        pendingCommands = HabitCompletionCommandQueue.appending(
            command, to: pendingCommands
        )
        persistPending()
        send(command)
    }

    func refresh() {
        rollToCurrentDayIfNeeded()

        guard
            let session,
            session.activationState == .activated
        else { return }

        if let contextPacket = try? HabitSyncCodec.packet(
            from: session.receivedApplicationContext
        ),
        contextPacket.kind == .snapshot,
        let snapshot = contextPacket.snapshot {
            apply(snapshot)
        }

        guard session.isReachable else {
            resendPendingDurably()
            return
        }

        send(
            packet: .requestSnapshot,
            expectsReply: true
        )
        flushPendingImmediately()
    }

    private func send(_ command: HabitCompletionCommand) {
        let packet = HabitSyncPacket.setCompletion(command)

        guard let session else { return }

        if session.isReachable {
            send(packet: packet, expectsReply: true)
        } else {
            scheduleDurableFlush()
        }
    }

    private func send(
        packet: HabitSyncPacket,
        expectsReply: Bool
    ) {
        guard
            let session,
            let message = try? HabitSyncCodec.message(packet)
        else { return }

        guard session.isReachable else {
            if packet.kind == .setCompletion {
                scheduleDurableFlush()
            }
            return
        }

        session.sendMessage(
            message,
            replyHandler: expectsReply ? { [weak self] reply in
                guard
                    let response = try? HabitSyncCodec.packet(from: reply),
                    response.kind == .snapshot,
                    let snapshot = response.snapshot
                else { return }
                self?.applyOnMain(snapshot)
            } : nil,
            errorHandler: { [weak self] _ in
                if packet.kind == .setCompletion {
                    self?.scheduleDurableFlush()
                }
            }
        )
    }

    private func scheduleDurableFlush() {
        durableFlushWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.resendPendingDurably()
        }
        durableFlushWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35,
            execute: workItem
        )
    }

    private func transferDurably(_ packet: HabitSyncPacket) {
        guard
            let session,
            let message = try? HabitSyncCodec.message(packet)
        else { return }

        if packet.kind == .setCompletion {
            try? session.updateApplicationContext(message)
        }

        if let command = packet.command {
            for transfer in session.outstandingUserInfoTransfers {
                guard
                    let existing = try? HabitSyncCodec.packet(
                        from: transfer.userInfo
                    ),
                    let existingCommand = existing.command,
                    existingCommand.habitID == command.habitID,
                    existingCommand.dayKey == command.dayKey
                else { continue }

                transfer.cancel()
            }
        }

        session.transferUserInfo(message)
    }

    private func flushPendingImmediately() {
        for command in pendingCommands {
            send(packet: .setCompletion(command), expectsReply: true)
        }
    }

    private func resendPendingDurably() {
        for command in pendingCommands {
            transferDurably(.setCompletion(command))
        }
    }

    private func applyOnMain(_ incoming: HabitSyncSnapshot) {
        DispatchQueue.main.async { [weak self] in
            self?.apply(incoming)
        }
    }

    private func apply(_ incoming: HabitSyncSnapshot) {
        let currentIncoming = WatchComplicationBridge.currentSnapshot(incoming)
        guard !currentIncoming.dayKey.isEmpty else { return }

        let reconciled = HabitSyncReconciler.reconcile(
            incoming: currentIncoming,
            currentSnapshot: snapshot,
            pendingCommands: pendingCommands
        )
        pendingCommands = reconciled.remainingCommands
        persistPending()

        let merged = reconciled.snapshot
        snapshot = merged
        cacheSnapshot()

#if DEBUG
        if Self.debugFlag(
            argument: "--diagnose-watch-sync",
            environment: "HABITS_DIAGNOSE_WATCH_SYNC"
        ) {
            let states = merged.habits.map {
                "\($0.name)=\($0.completed ? "1" : "0")"
            }.joined(separator: ",")
            HabitDebugLog.emit(
                "HABITS_WATCH_SNAPSHOT day=\(merged.dayKey) " +
                "completed=\(merged.completedCount)/\(merged.totalCount) " +
                "pending=\(pendingCommands.count) habits=[\(states)]"
            )
        }

        if
            !didAutoToggleForDebug,
            Self.debugFlag(
                argument: "--auto-toggle-first-habit",
                environment: "HABITS_AUTO_TOGGLE_FIRST_HABIT"
            ),
            let first = merged.habits.first
        {
            didAutoToggleForDebug = true
            toggle(first)
        }
#endif
    }

    private func rollToCurrentDayIfNeeded() {
        let current = WatchComplicationBridge.currentSnapshot(snapshot)
        guard current.dayKey != snapshot.dayKey else { return }

        if current.dayKey.isEmpty {
            snapshot = .empty
            return
        }

        snapshot = current
        cacheSnapshot()
    }

    private func cacheSnapshot() {
        Self.save(snapshot, key: snapshotKey)
        WatchComplicationBridge.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadTimelines(
            ofKind: "HabitsWatchComplication"
        )
    }

    private func persistPending() {
        Self.save(pendingCommands, key: pendingKey)
    }

#if DEBUG
    private static func debugFlag(
        argument: String,
        environment: String
    ) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument) ||
        ProcessInfo.processInfo.environment[environment] == "1"
    }

    func debugAutoToggleCachedFirstHabitIfRequested() {
        guard
            !didAutoToggleCachedForDebug,
            Self.debugFlag(
                argument: "--auto-toggle-cached-first-habit",
                environment: "HABITS_AUTO_TOGGLE_CACHED_FIRST_HABIT"
            ),
            let first = snapshot.habits.first
        else { return }

        didAutoToggleCachedForDebug = true
        guard first.completed else { return }
        toggle(first)
    }

    func debugStressToggleCachedFirstHabitIfRequested() {
        guard
            !didStressToggleForDebug,
            Self.debugFlag(
                argument: "--stress-toggle-cached-first-habit",
                environment: "HABITS_STRESS_TOGGLE_CACHED_FIRST_HABIT"
            ),
            let first = snapshot.habits.first
        else { return }

        didStressToggleForDebug = true
        for _ in 0..<51 {
            toggle(first)
        }

        HabitDebugLog.emit(
            "HABITS_WATCH_STRESS pending=\(pendingCommands.count) " +
            "durable=\(session?.outstandingUserInfoTransfers.count ?? -1) " +
            "final=\(snapshot.habits.first?.completed == true ? 1 : 0) " +
            "reachable=\(isReachable)"
        )
    }
#endif

    private static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func load<T: Decodable>(
        _ type: T.Type,
        key: String
    ) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func receive(_ message: [String: Any]) {
        guard
            let packet = try? HabitSyncCodec.packet(from: message),
            packet.kind == .snapshot,
            let snapshot = packet.snapshot
        else { return }
        applyOnMain(snapshot)
    }

    // MARK: WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
#if DEBUG
            if Self.debugFlag(
                argument: "--diagnose-watch-sync",
                environment: "HABITS_DIAGNOSE_WATCH_SYNC"
            ) {
                HabitDebugLog.emit(
                    "HABITS_WATCH_ACTIVATED state=\(activationState.rawValue) " +
                    "reachable=\(session.isReachable)"
                )
            }
#endif
            if activationState == .activated, error == nil {
                self?.refresh()
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            if session.isReachable {
                self?.refresh()
            }
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        receive(applicationContext)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        receive(message)
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        receive(userInfo)
    }
}
