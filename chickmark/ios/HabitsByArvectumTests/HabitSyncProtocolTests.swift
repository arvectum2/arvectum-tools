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

    func testMatchingNewerAuthoritativeSnapshotClearsPendingWithoutExplicitID() {
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

        XCTAssertTrue(result.remainingCommands.isEmpty)
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
}
