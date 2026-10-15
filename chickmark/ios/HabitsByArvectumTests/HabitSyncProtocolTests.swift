import XCTest
@testable import HabitsByArvectum

final class HabitSyncProtocolTests: XCTestCase {
    func testWatchHealthProgressDoesNotEnterSyncPackets() throws {
        let progress = WatchHealthProgress(metric: "steps", current: 3_475, target: 7_777)
        XCTAssertEqual(progress.unitKey, "watch.health.unit.steps")
        XCTAssertEqual(progress.fraction, 3_475.0 / 7_777.0, accuracy: 0.00001)
        let text = progress.quantityText(locale: Locale(identifier: "en_US"))
        XCTAssertEqual(text, "3,475 / 7,777")

        let habitID = UUID()
        let source = HabitSyncSnapshot(
            generatedAt: .now, dayKey: "2026-10-14",
            completedCount: 0, totalCount: 1,
            habits: [HabitSyncHabit(
                id: habitID, name: "Walk", symbolName: "figure.walk",
                colorHex: "43E5C5", completed: false, streak: 0,
                healthRuleMetric: "steps", healthRuleTarget: 7_777
            )]
        )
        let serialized = try HabitSyncCodec.encode(.snapshot(source))
        XCTAssertFalse(String(decoding: serialized, as: UTF8.self).contains("3475"))
    }

    func testWatchHealthProgressClampsAndSupportsAllMetrics() {
        let distance = WatchHealthProgress(metric: "walkingDistance", current: 1.26, target: 3)
        XCTAssertEqual(distance.unitKey, "watch.health.unit.kilometers")
        XCTAssertEqual(distance.quantityText(locale: Locale(identifier: "en_US")), "1.3 / 3")
        XCTAssertEqual(WatchHealthProgress(metric: "sleepHours", current: 9, target: 7).fraction, 1)
        XCTAssertEqual(WatchHealthProgress(metric: "runningWorkout", current: 2, target: 20).unitKey,
                       "watch.health.unit.minutes")
        XCTAssertEqual(WatchHealthProgress(metric: "steps", current: .nan, target: 7777).fraction, 0)
        XCTAssertEqual(WatchHealthProgress(metric: "steps", current: 25, target: 0).quantityText(locale: .current), "—")
    }

    func testCompletionPacketRoundTrips() throws {
        let command = HabitCompletionCommand(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            habitID: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            dayKey: "2026-10-01",
            completed: true,
            createdAt: Date(timeIntervalSince1970: 1_790_815_200)
        )

        let packet = HabitSyncPacket.setCompletion(command)
        let decoded = try HabitSyncCodec.decode(
            HabitSyncCodec.encode(packet)
        )

        XCTAssertEqual(decoded.kind, .setCompletion)
        XCTAssertEqual(decoded.command, command)
        XCTAssertNil(decoded.snapshot)
    }

    func testAcknowledgedCommandIsRemoved() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-10-01",
            completed: true
        )
        let incoming = snapshot(
            habitID: habitID,
            completed: true,
            acknowledged: [command.id]
        )

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            pendingCommands: [command]
        )

        XCTAssertTrue(result.remainingCommands.isEmpty)
        XCTAssertTrue(result.snapshot.habits[0].completed)
        XCTAssertEqual(result.snapshot.completedCount, 1)
    }

    func testPendingCommandWinsOptimisticallyUntilAcknowledged() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-10-01",
            completed: true
        )
        let incoming = snapshot(
            habitID: habitID,
            completed: false
        )

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            pendingCommands: [command]
        )

        XCTAssertEqual(result.remainingCommands, [command])
        XCTAssertTrue(result.snapshot.habits[0].completed)
        XCTAssertEqual(result.snapshot.completedCount, 1)
    }

    func testPendingCompletionResolvesSkippedSnapshot() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-10-01",
            completed: true
        )
        var incoming = snapshot(
            habitID: habitID,
            completed: false
        )
        incoming.habits[0].skipped = true
        incoming.skippedCount = 1

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            pendingCommands: [command]
        )

        XCTAssertTrue(result.snapshot.habits[0].completed)
        XCTAssertFalse(result.snapshot.habits[0].skipped)
        XCTAssertEqual(result.snapshot.completedCount, 1)
        XCTAssertEqual(result.snapshot.skippedCount, 0)
        XCTAssertEqual(result.snapshot.resolvedCount, 1)
    }

    func testPendingQueueCompactsRapidSameDayCommandsToLatestState() {
        let habitID = UUID()
        var commands: [HabitCompletionCommand] = []

        for index in 0..<50 {
            let command = HabitCompletionCommand(
                id: UUID(),
                habitID: habitID,
                dayKey: "2026-10-01",
                completed: index.isMultiple(of: 2),
                createdAt: Date(timeIntervalSince1970: Double(index))
            )
            commands = HabitCompletionCommandQueue.appending(
                command,
                to: commands
            )
        }

        XCTAssertEqual(commands.count, 1)
        XCTAssertEqual(commands.first?.createdAt, Date(timeIntervalSince1970: 49))
        XCTAssertEqual(commands.first?.completed, false)
    }

    func testPendingQueueKeepsNewestHundredDistinctTargets() {
        var commands: [HabitCompletionCommand] = []

        for index in 0..<105 {
            let command = HabitCompletionCommand(
                id: UUID(),
                habitID: UUID(),
                dayKey: "2026-10-01",
                completed: true,
                createdAt: Date(timeIntervalSince1970: Double(index))
            )
            commands = HabitCompletionCommandQueue.appending(
                command,
                to: commands
            )
        }

        XCTAssertEqual(commands.count, 100)
        XCTAssertEqual(commands.first?.createdAt, Date(timeIntervalSince1970: 5))
        XCTAssertEqual(commands.last?.createdAt, Date(timeIntervalSince1970: 104))
    }

    func testSkippedSnapshotRoundTrips() throws {
        let habitID = UUID()
        var source = snapshot(
            habitID: habitID,
            completed: false
        )
        source.habits[0].skipped = true
        source.skippedCount = 1

        let packet = HabitSyncPacket.snapshot(source)
        let decoded = try HabitSyncCodec.decode(
            HabitSyncCodec.encode(packet)
        )

        XCTAssertEqual(decoded.snapshot, source)
        XCTAssertEqual(decoded.snapshot?.resolvedCount, 1)
    }

    func testOlderSnapshotCannotRollBackNewerDisplayedState() {
        let habitID = UUID()
        var current = snapshot(
            habitID: habitID,
            completed: true
        )
        current.generatedAt = Date(timeIntervalSince1970: 20)

        var incoming = snapshot(
            habitID: habitID,
            completed: false
        )
        incoming.generatedAt = Date(timeIntervalSince1970: 10)

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            currentSnapshot: current,
            pendingCommands: []
        )

        XCTAssertTrue(result.snapshot.habits[0].completed)
        XCTAssertEqual(result.snapshot.completedCount, 1)
        XCTAssertEqual(result.snapshot.generatedAt, current.generatedAt)
    }

    func testOlderSnapshotStillAcknowledgesPendingCommandWithoutRollback() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-10-01",
            completed: true,
            createdAt: Date(timeIntervalSince1970: 15)
        )
        var current = snapshot(
            habitID: habitID,
            completed: true
        )
        current.generatedAt = Date(timeIntervalSince1970: 20)

        var incoming = snapshot(
            habitID: habitID,
            completed: false,
            acknowledged: [command.id]
        )
        incoming.generatedAt = Date(timeIntervalSince1970: 10)

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            currentSnapshot: current,
            pendingCommands: [command]
        )

        XCTAssertTrue(result.remainingCommands.isEmpty)
        XCTAssertTrue(result.snapshot.habits[0].completed)
    }

    func testMatchingNewerSnapshotCannotSilentlyAcknowledgeUnreceivedCommand() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-10-01",
            completed: false,
            createdAt: Date(timeIntervalSince1970: 10)
        )
        var incoming = snapshot(
            habitID: habitID,
            completed: false
        )
        incoming.generatedAt = Date(timeIntervalSince1970: 20)

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            pendingCommands: [command]
        )

        XCTAssertEqual(result.remainingCommands, [command],
                       "A coincidentally matching snapshot proves no delivery/ACK")
        XCTAssertFalse(result.snapshot.habits[0].completed)
    }

    func testOlderMatchingSnapshotDoesNotClearNewerPendingCommand() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-10-01",
            completed: false,
            createdAt: Date(timeIntervalSince1970: 20)
        )
        var incoming = snapshot(
            habitID: habitID,
            completed: false
        )
        incoming.generatedAt = Date(timeIntervalSince1970: 10)

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            pendingCommands: [command]
        )

        XCTAssertEqual(result.remainingCommands, [command])
    }

    func testHealthRevocationCoincidingWithPendingUndoCannotLoseManualOverride() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID, dayKey: "2026-10-01",
            completed: false, createdAt: Date(timeIntervalSince1970: 10)
        )
        var coincidence = snapshot(habitID: habitID, completed: false)
        coincidence.generatedAt = Date(timeIntervalSince1970: 20)
        coincidence.habits[0].healthRuleMetric = "steps"
        coincidence.habits[0].healthRuleTarget = 8000
        coincidence.habits[0].healthManualOverride = false

        let whileOffline = HabitSyncReconciler.reconcile(
            incoming: coincidence, pendingCommands: [command]
        )
        XCTAssertEqual(whileOffline.remainingCommands, [command])
        XCTAssertFalse(whileOffline.snapshot.habits[0].completed)

        // When Health becomes available again, the iPhone would
        // auto-complete unless the undelivered manual undo is retried.
        var healthRecovered = snapshot(habitID: habitID, completed: true)
        healthRecovered.generatedAt = Date(timeIntervalSince1970: 30)
        healthRecovered.habits[0].healthRuleMetric = "steps"
        let replay = HabitSyncReconciler.reconcile(
            incoming: healthRecovered,
            currentSnapshot: whileOffline.snapshot,
            pendingCommands: whileOffline.remainingCommands
        )
        XCTAssertEqual(replay.remainingCommands, [command])
        XCTAssertFalse(replay.snapshot.habits[0].completed)
        XCTAssertEqual(replay.snapshot.completedCount, 0)

        var phoneApplied = snapshot(
            habitID: habitID, completed: false, acknowledged: [command.id]
        )
        phoneApplied.generatedAt = Date(timeIntervalSince1970: 40)
        let afterACK = HabitSyncReconciler.reconcile(
            incoming: phoneApplied,
            currentSnapshot: replay.snapshot,
            pendingCommands: replay.remainingCommands
        )
        XCTAssertTrue(afterACK.remainingCommands.isEmpty)
        XCTAssertFalse(afterACK.snapshot.habits[0].completed)
    }

    func testPartialCountCoincidenceMustNotDropWatchCommandBeforeACK() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID, dayKey: "2026-10-01",
            completed: false, desiredCount: 3,
            createdAt: Date(timeIntervalSince1970: 10)
        )
        var incoming = snapshot(habitID: habitID, completed: false)
        incoming.generatedAt = Date(timeIntervalSince1970: 20)
        incoming.habits[0].dailyTarget = 5
        incoming.habits[0].dailyCount = 3

        let pending = HabitSyncReconciler.reconcile(
            incoming: incoming, pendingCommands: [command]
        )
        XCTAssertEqual(pending.remainingCommands, [command])
        XCTAssertEqual(pending.snapshot.habits[0].dailyCount, 3)

        // Other iPhone action changes the count before command delivery.
        incoming.generatedAt = Date(timeIntervalSince1970: 30)
        incoming.habits[0].dailyCount = 1
        let continued = HabitSyncReconciler.reconcile(
            incoming: incoming,
            currentSnapshot: pending.snapshot,
            pendingCommands: pending.remainingCommands
        )
        XCTAssertEqual(continued.remainingCommands, [command])
        XCTAssertEqual(continued.snapshot.habits[0].dailyCount, 3)

        incoming.generatedAt = Date(timeIntervalSince1970: 40)
        incoming.habits[0].dailyCount = 3
        incoming.acknowledgedCommandIDs = [command.id]
        let acked = HabitSyncReconciler.reconcile(
            incoming: incoming,
            currentSnapshot: continued.snapshot,
            pendingCommands: continued.remainingCommands
        )
        XCTAssertTrue(acked.remainingCommands.isEmpty)
        XCTAssertEqual(acked.snapshot.habits[0].dailyCount, 3)
    }

    func testOfflineIndependentCommandsSurviveRestartAndPartialACKs() throws {
        let firstID = UUID()
        let secondID = UUID()
        let first = HabitCompletionCommand(
            habitID: firstID, dayKey: "2026-10-01",
            completed: true, createdAt: Date(timeIntervalSince1970: 100)
        )
        let second = HabitCompletionCommand(
            habitID: secondID, dayKey: "2026-10-01",
            completed: false, createdAt: Date(timeIntervalSince1970: 101)
        )
        let offline = HabitCompletionCommandQueue.appending(
            second, to: HabitCompletionCommandQueue.appending(first, to: [])
        )
        // The Watch's pending commands are persisted in UserDefaults as
        // JSON. Rehydrate here to model an app restart while disconnected.
        let restored = try JSONDecoder().decode(
            [HabitCompletionCommand].self,
            from: JSONEncoder().encode(offline)
        )
        XCTAssertEqual(restored, [first, second])

        var arrived = snapshot(habitID: firstID, completed: true)
        arrived.generatedAt = Date(timeIntervalSince1970: 120)
        arrived.habits.append(HabitSyncHabit(
            id: secondID, name: "Second", symbolName: "checkmark",
            colorHex: "43E5C5", completed: false, streak: 0
        ))
        arrived.totalCount = 2
        arrived.completedCount = 1

        let noACK = HabitSyncReconciler.reconcile(
            incoming: arrived, pendingCommands: restored
        )
        XCTAssertEqual(noACK.remainingCommands, [first, second],
                       "Coincidental agreement for two habits is not delivery")

        arrived.generatedAt = Date(timeIntervalSince1970: 130)
        arrived.acknowledgedCommandIDs = [first.id]
        let partialACK = HabitSyncReconciler.reconcile(
            incoming: arrived,
            currentSnapshot: noACK.snapshot,
            pendingCommands: noACK.remainingCommands
        )
        XCTAssertEqual(partialACK.remainingCommands, [second])
        XCTAssertEqual(partialACK.snapshot.completedCount, 1)

        arrived.generatedAt = Date(timeIntervalSince1970: 140)
        arrived.acknowledgedCommandIDs = [first.id, second.id]
        let fullACK = HabitSyncReconciler.reconcile(
            incoming: arrived,
            currentSnapshot: partialACK.snapshot,
            pendingCommands: partialACK.remainingCommands
        )
        XCTAssertTrue(fullACK.remainingCommands.isEmpty)
        XCTAssertEqual(fullACK.snapshot.completedCount, 1)
    }

    func testDuplicateOrOldSnapshotWithoutACKCannotConsumeDurablePending() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID, dayKey: "2026-10-01",
            completed: true, createdAt: Date(timeIntervalSince1970: 110)
        )
        var current = snapshot(habitID: habitID, completed: false)
        current.generatedAt = Date(timeIntervalSince1970: 100)
        var incoming = snapshot(habitID: habitID, completed: true)
        incoming.generatedAt = Date(timeIntervalSince1970: 120)

        for _ in 0..<5 {
            let reconciled = HabitSyncReconciler.reconcile(
                incoming: incoming, currentSnapshot: current,
                pendingCommands: [command]
            )
            XCTAssertEqual(reconciled.remainingCommands, [command])
            XCTAssertTrue(reconciled.snapshot.habits[0].completed)
            current = reconciled.snapshot
            incoming.generatedAt = incoming.generatedAt.addingTimeInterval(-1)
        }

        incoming.generatedAt = Date(timeIntervalSince1970: 140)
        incoming.acknowledgedCommandIDs = [command.id]
        let acked = HabitSyncReconciler.reconcile(
            incoming: incoming, currentSnapshot: current,
            pendingCommands: [command]
        )
        XCTAssertTrue(acked.remainingCommands.isEmpty)
    }

    func testWatchHealthPendingUndoSurvivesSnapshotsAndBlocksLocalRecompletionUntilACK() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var phone = snapshot(habitID: id, completed: false)
        phone.generatedAt = date
        phone.habits[0].healthRuleMetric = "steps"
        phone.habits[0].healthRuleTarget = 2000
        let undo = HabitCompletionCommand(
            habitID: id, dayKey: phone.dayKey,
            completed: false, createdAt: date.addingTimeInterval(1)
        )
        let state = WatchLocalHealthProjection.State(
            dayKey: phone.dayKey, habitIDs: [id], generatedAt: date,
            rules: [id: .init(metric: "steps", target: 2000)]
        )

        let initial = HabitSyncReconciler.reconcile(
            incoming: phone, pendingCommands: [undo]
        )
        XCTAssertEqual(initial.remainingCommands, [undo])
        XCTAssertEqual(initial.snapshot.habits[0].watchPendingManualAction, true)
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(
            initial.snapshot.habits[0], value: 3000
        ))
        XCTAssertFalse(WatchLocalHealthProjection.applying(
            initial.snapshot, state: state, now: date
        ).habits[0].completed,
            "Complication must not use cached steps to undo the pending manual action")

        // A new, coincidentally unchecked iPhone snapshot carries no ACK.
        phone.generatedAt = date.addingTimeInterval(10)
        let repeated = HabitSyncReconciler.reconcile(
            incoming: phone,
            currentSnapshot: initial.snapshot,
            pendingCommands: initial.remainingCommands
        )
        XCTAssertEqual(repeated.remainingCommands, [undo])
        XCTAssertEqual(repeated.snapshot.habits[0].watchPendingManualAction, true)

        // After explicit ACK, a fresh Health threshold may auto-complete
        // again, consistent with the existing iPhone/Watch health policy.
        phone.acknowledgedCommandIDs = [undo.id]
        phone.generatedAt = date.addingTimeInterval(20)
        let acknowledged = HabitSyncReconciler.reconcile(
            incoming: phone,
            currentSnapshot: repeated.snapshot,
            pendingCommands: repeated.remainingCommands
        )
        XCTAssertTrue(acknowledged.remainingCommands.isEmpty)
        XCTAssertNil(acknowledged.snapshot.habits[0].watchPendingManualAction)
        XCTAssertTrue(WatchLocalHealthProjection.qualifies(
            acknowledged.snapshot.habits[0], value: 3000
        ))
        XCTAssertTrue(WatchLocalHealthProjection.applying(
            acknowledged.snapshot, state: state, now: date
        ).habits[0].completed)
    }

    func testWatchOptimisticHealthFlagDoesNotSurviveACKAgainstNewerLocalSnapshot() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let undo = HabitCompletionCommand(
            habitID: id, dayKey: "2026-10-01", completed: false,
            createdAt: date
        )
        var cached = snapshot(habitID: id, completed: false)
        cached.generatedAt = date.addingTimeInterval(20)
        cached.habits[0].healthRuleMetric = "steps"
        cached.habits[0].healthRuleTarget = 2000
        cached.habits[0].watchPendingManualAction = true

        var olderReply = snapshot(
            habitID: id, completed: false, acknowledged: [undo.id]
        )
        olderReply.generatedAt = date.addingTimeInterval(10)
        let resolved = HabitSyncReconciler.reconcile(
            incoming: olderReply, currentSnapshot: cached,
            pendingCommands: [undo]
        )
        XCTAssertTrue(resolved.remainingCommands.isEmpty)
        XCTAssertNil(resolved.snapshot.habits[0].watchPendingManualAction)
    }

    func testOldV2SnapshotWithoutWatchPendingMarkerDecodesAndRetainsHealthPolicy() throws {
        let id = UUID()
        var source = snapshot(habitID: id, completed: false)
        source.habits[0].healthRuleMetric = "steps"
        source.habits[0].healthRuleTarget = 2000
        source.habits[0].watchPendingManualAction = true
        XCTAssertEqual(source.protocolVersion, 2)

        let encoded = try HabitSyncCodec.encode(.snapshot(source))
        var wrapper = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        var snapshotJSON = try XCTUnwrap(wrapper["snapshot"] as? [String: Any])
        var habitsJSON = try XCTUnwrap(snapshotJSON["habits"] as? [[String: Any]])
        habitsJSON[0].removeValue(forKey: "watchPendingManualAction")
        snapshotJSON["habits"] = habitsJSON
        wrapper["snapshot"] = snapshotJSON
        let oldPacket = try JSONSerialization.data(withJSONObject: wrapper)
        let restored = try XCTUnwrap(HabitSyncCodec.decode(oldPacket).snapshot)

        XCTAssertEqual(restored.protocolVersion, 2)
        XCTAssertNil(restored.habits[0].watchPendingManualAction)
        XCTAssertTrue(WatchLocalHealthProjection.qualifies(
            restored.habits[0], value: 3000
        ))
        // The new local in-flight marker also round-trips in a v2 packet.
        let current = try XCTUnwrap(HabitSyncCodec.decode(encoded).snapshot)
        XCTAssertEqual(current.habits[0].watchPendingManualAction, true)
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(
            current.habits[0], value: 3000
        ))
    }

    func testPendingCommandFromDifferentDayDoesNotOverrideSnapshot() {
        let habitID = UUID()
        let command = HabitCompletionCommand(
            habitID: habitID,
            dayKey: "2026-09-30",
            completed: true
        )
        let incoming = snapshot(
            habitID: habitID,
            completed: false
        )

        let result = HabitSyncReconciler.reconcile(
            incoming: incoming,
            pendingCommands: [command]
        )

        XCTAssertFalse(result.snapshot.habits[0].completed)
        XCTAssertEqual(result.snapshot.completedCount, 0)
    }

    func testOfflineRapidUndoWinsWhenOlderPhoneSnapshotArrivesFirst() {
        // A2: the Watch queues a check, then an undo while disconnected.
        // Reconnecting can first deliver an older iPhone completion snapshot.
        // It must neither resurrect the stale check nor drop the newer undo.
        let habitID = UUID()
        let checked = HabitCompletionCommand(
            id: UUID(), habitID: habitID, dayKey: "2026-10-01",
            completed: true, createdAt: Date(timeIntervalSince1970: 100)
        )
        let undone = HabitCompletionCommand(
            id: UUID(), habitID: habitID, dayKey: "2026-10-01",
            completed: false, createdAt: Date(timeIntervalSince1970: 200)
        )
        let pending = HabitCompletionCommandQueue.appending(
            undone, to: HabitCompletionCommandQueue.appending(checked, to: [])
        )
        XCTAssertEqual(pending, [undone])

        var stalePhone = snapshot(habitID: habitID, completed: true)
        stalePhone.generatedAt = Date(timeIntervalSince1970: 150)
        let beforeACK = HabitSyncReconciler.reconcile(
            incoming: stalePhone, pendingCommands: pending
        )
        XCTAssertEqual(beforeACK.remainingCommands, [undone])
        XCTAssertFalse(beforeACK.snapshot.habits[0].completed)
        XCTAssertEqual(beforeACK.snapshot.completedCount, 0)

        var updatedPhone = snapshot(
            habitID: habitID, completed: false, acknowledged: [undone.id]
        )
        updatedPhone.generatedAt = Date(timeIntervalSince1970: 250)
        let afterACK = HabitSyncReconciler.reconcile(
            incoming: updatedPhone,
            currentSnapshot: beforeACK.snapshot,
            pendingCommands: beforeACK.remainingCommands
        )
        XCTAssertTrue(afterACK.remainingCommands.isEmpty)
        XCTAssertFalse(afterACK.snapshot.habits[0].completed)
        XCTAssertEqual(afterACK.snapshot.completedCount, 0)
    }

    func testOfflinePreviousDayCommandCannotMarkTodayAfterReconnection() {
        // A2/A3: delayed commands from before midnight stay attached to
        // their original calendar day and must not check today's Watch row.
        let habitID = UUID()
        let priorDay = HabitCompletionCommand(
            habitID: habitID, dayKey: "2026-10-14",
            completed: true, createdAt: Date(timeIntervalSince1970: 100)
        )
        var currentDay = snapshot(habitID: habitID, completed: false)
        currentDay.dayKey = "2026-10-15"
        currentDay.generatedAt = Date(timeIntervalSince1970: 200)

        let reconciled = HabitSyncReconciler.reconcile(
            incoming: currentDay,
            pendingCommands: [priorDay]
        )
        XCTAssertEqual(reconciled.remainingCommands, [priorDay])
        XCTAssertEqual(reconciled.snapshot.dayKey, "2026-10-15")
        XCTAssertFalse(reconciled.snapshot.habits[0].completed)
        XCTAssertEqual(reconciled.snapshot.completedCount, 0)
    }

    func testPayloadBudgetKeepsFullHorizonForTypicalHabitCount() {
        let habits = (0..<6).map { index in
            HabitSyncHabit(
                id: UUID(),
                name: "Habit \(index)",
                symbolName: "checkmark",
                colorHex: "43E5C5",
                completed: false,
                skipped: false,
                streak: index
            )
        }
        let source = HabitSyncSnapshot(
            generatedAt: .now,
            dayKey: "2026-10-01",
            completedCount: 0,
            totalCount: habits.count,
            habits: habits,
            projectedDays: (2...14).map { day in
                HabitSyncDayProjection(
                    dayKey: String(format: "2026-10-%02d", day),
                    habits: habits
                )
            }
        )

        let fitted = HabitSyncPayloadBudget.fitted(source)

        XCTAssertEqual(fitted.projectedDays?.count, 13)
        XCTAssertLessThanOrEqual(
            HabitSyncPayloadBudget.encodedSize(of: fitted),
            HabitSyncPayloadBudget.maxEncodedBytes
        )
    }

    func testPayloadBudgetTrimsDistantDaysForHeavySnapshot() {
        let habits = (0..<50).map { index in
            HabitSyncHabit(
                id: UUID(),
                name: HabitSyncPayloadBudget.watchName(
                    "Habit \(index) " + String(repeating: "x", count: 100)
                ),
                symbolName: "figure.strengthtraining.traditional",
                colorHex: "8B5CF6",
                completed: false,
                skipped: false,
                streak: 123,
                weeklyTarget: 7,
                weeklyCount: 6
            )
        }
        let source = HabitSyncSnapshot(
            generatedAt: .now,
            dayKey: "2026-10-01",
            completedCount: 0,
            totalCount: habits.count,
            habits: habits,
            acknowledgedCommandIDs: (0..<50).map { _ in UUID() },
            projectedDays: (2...14).map { day in
                HabitSyncDayProjection(
                    dayKey: String(format: "2026-10-%02d", day),
                    habits: habits
                )
            }
        )

        XCTAssertGreaterThan(
            HabitSyncPayloadBudget.encodedSize(of: source),
            HabitSyncPayloadBudget.maxEncodedBytes
        )

        let fitted = HabitSyncPayloadBudget.fitted(source)

        XCTAssertLessThan(
            fitted.projectedDays?.count ?? 0,
            source.projectedDays?.count ?? 0
        )
        XCTAssertEqual(fitted.habits.count, habits.count)
        XCTAssertLessThanOrEqual(
            HabitSyncPayloadBudget.encodedSize(of: fitted),
            HabitSyncPayloadBudget.maxEncodedBytes
        )
    }

    func testWatchNameIsBoundedWithoutChangingShortNames() {
        XCTAssertEqual(HabitSyncPayloadBudget.watchName("Read"), "Read")

        let long = String(repeating: "a", count: 100)
        XCTAssertEqual(
            HabitSyncPayloadBudget.watchName(long).count,
            HabitSyncPayloadBudget.maxWatchNameCharacters
        )
    }

    private func snapshot(
        habitID: UUID,
        completed: Bool,
        acknowledged: [UUID] = []
    ) -> HabitSyncSnapshot {
        HabitSyncSnapshot(
            generatedAt: .now,
            dayKey: "2026-10-01",
            completedCount: completed ? 1 : 0,
            totalCount: 1,
            habits: [
                HabitSyncHabit(
                    id: habitID,
                    name: "Reading",
                    symbolName: "book.fill",
                    colorHex: "8B5CF6",
                    completed: completed,
                    streak: completed ? 1 : 0
                )
            ],
            acknowledgedCommandIDs: acknowledged
        )
    }

    func testDurableTransferDoesNotRequeueSameOfflineCommandAfterRefresh() {
        let habit = UUID()
        let original = HabitCompletionCommand(
            habitID: habit, dayKey: "2026-10-14", completed: true
        )
        let unrelated = HabitCompletionCommand(
            habitID: UUID(), dayKey: "2026-10-14", completed: false
        )
        let plan = HabitDurableDeliveryPlan.plan(
            new: original, outstanding: [original, unrelated]
        )
        XCTAssertTrue(plan.alreadyQueued)
        XCTAssertTrue(plan.supersededIDs.isEmpty)
        XCTAssertEqual(
            HabitDurableDeliveryPlan.plan(new: original, outstanding: []).alreadyQueued,
            false
        )
    }

    func testDurableTransferReplacesOnlyOlderCommandsForSameHabitDay() {
        let habit = UUID()
        let older = HabitCompletionCommand(
            habitID: habit, dayKey: "2026-10-14",
            completed: true, createdAt: Date(timeIntervalSince1970: 100)
        )
        let newest = HabitCompletionCommand(
            habitID: habit, dayKey: "2026-10-14",
            completed: false, createdAt: Date(timeIntervalSince1970: 200)
        )
        let otherDay = HabitCompletionCommand(
            habitID: habit, dayKey: "2026-10-15", completed: true
        )
        let otherHabit = HabitCompletionCommand(
            habitID: UUID(), dayKey: "2026-10-14", completed: true
        )
        let plan = HabitDurableDeliveryPlan.plan(
            new: newest, outstanding: [older, otherDay, otherHabit]
        )
        XCTAssertFalse(plan.alreadyQueued)
        XCTAssertEqual(plan.supersededIDs, [older.id])
        let after = HabitDurableDeliveryPlan.plan(
            new: newest, outstanding: [older, newest, otherDay, otherHabit]
        )
        XCTAssertTrue(after.alreadyQueued)
        XCTAssertEqual(after.supersededIDs, [older.id])
    }

    func testDurableTransferKeepsNewestPartialProgressAfterRepeatedFlush() {
        let habit = UUID()
        let first = HabitCompletionCommand(
            habitID: habit, dayKey: "2026-10-15",
            completed: false, desiredCount: 1
        )
        let last = HabitCompletionCommand(
            habitID: habit, dayKey: "2026-10-15",
            completed: false, desiredCount: 3
        )
        let pending = HabitCompletionCommandQueue.appending(
            last, to: HabitCompletionCommandQueue.appending(first, to: [])
        )
        XCTAssertEqual(pending, [last])
        let initial = HabitDurableDeliveryPlan.plan(
            new: last, outstanding: [first]
        )
        XCTAssertEqual(initial.supersededIDs, [first.id])
        XCTAssertFalse(initial.alreadyQueued)
        let repeatPlan = HabitDurableDeliveryPlan.plan(
            new: last, outstanding: [last]
        )
        XCTAssertTrue(repeatPlan.alreadyQueued)
        XCTAssertTrue(repeatPlan.supersededIDs.isEmpty)
        XCTAssertEqual(pending.first?.desiredCount, 3)
    }


    func testWatchActionGateRejectsYesterdayAfterMidnightAndFutureSnapshot() throws {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let now = try XCTUnwrap(ny.date(from: DateComponents(
            year: 2026, month: 11, day: 2, hour: 0, minute: 1
        )))
        XCTAssertFalse(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "2026-11-01", now: now, calendar: ny
        ))
        XCTAssertTrue(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "2026-11-02", now: now, calendar: ny
        ))
        XCTAssertFalse(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "2026-11-03", now: now, calendar: ny
        ))
        XCTAssertFalse(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "", now: now, calendar: ny
        ))
    }

    func testWatchActionGateRecomputesDateAfterTimezoneTravel() throws {
        let moment = try XCTUnwrap(ISO8601DateFormatter().date(
            from: "2026-10-14T00:30:00Z"
        ))
        var london = Calendar(identifier: .gregorian)
        london.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        XCTAssertTrue(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "2026-10-14", now: moment, calendar: london
        ))
        XCTAssertFalse(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "2026-10-14", now: moment, calendar: newYork
        ))
        XCTAssertTrue(HabitWatchActionPolicy.accepts(
            snapshotDayKey: "2026-10-13", now: moment, calendar: newYork
        ))
    }

}
