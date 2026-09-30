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
