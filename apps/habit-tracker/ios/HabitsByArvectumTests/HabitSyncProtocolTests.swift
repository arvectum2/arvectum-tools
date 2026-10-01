import XCTest
@testable import HabitsByArvectum

final class HabitSyncProtocolTests: XCTestCase {
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
