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

    func refresh() {
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
            transferDurably(packet)
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
                transferDurably(packet)
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
                    self?.transferDurably(packet)
                }
            }
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
        let reconciled = HabitSyncReconciler.reconcile(
            incoming: incoming,
            currentSnapshot: snapshot,
            pendingCommands: pendingCommands
        )
        pendingCommands = reconciled.remainingCommands
        persistPending()

        let merged = reconciled.snapshot
        snapshot = merged
        cacheSnapshot()

#if DEBUG
        if ProcessInfo.processInfo.arguments.contains(
            "--diagnose-watch-sync"
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
            ProcessInfo.processInfo.arguments.contains(
                "--auto-toggle-first-habit"
            ),
            let first = merged.habits.first
        {
            didAutoToggleForDebug = true
            toggle(first)
        }
#endif
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
    func debugAutoToggleCachedFirstHabitIfRequested() {
        guard
            !didAutoToggleCachedForDebug,
            ProcessInfo.processInfo.arguments.contains(
                "--auto-toggle-cached-first-habit"
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
            ProcessInfo.processInfo.arguments.contains(
                "--stress-toggle-cached-first-habit"
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
            if ProcessInfo.processInfo.arguments.contains(
                "--diagnose-watch-sync"
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
