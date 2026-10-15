import SwiftData
import XCTest
@testable import ArvectumNotify

@MainActor
final class NotificationHistoryDeletionTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([CapturedNotification.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func add(_ name: String, into context: ModelContext) throws -> CapturedNotification {
        let notification = CapturedNotification(
            sourceApp: name,
            titleText: "\(name) title",
            subtitleText: "Test subtitle",
            bodyText: "\(name) body",
            receivedAt: .now
        )
        context.insert(notification)
        try context.save()
        return notification
    }

    func testDeletingOneNotificationKeepsOtherRowsAndDetachedSnapshot() throws {
        let context = try makeContext()
        let toDelete = try add("Delete Me", into: context)
        let survivor = try add("Keep Me", into: context)
        let snapshot = NotificationHistoryItem(toDelete)
        let target = toDelete.id
        let survivorID = survivor.id

        XCTAssertTrue(try NotificationHistoryDeletion.delete(id: target, in: context))
        let persisted = try context.fetch(FetchDescriptor<CapturedNotification>())
        XCTAssertEqual(persisted.map(\.id), [survivorID])
        XCTAssertEqual(snapshot.id, target)
        XCTAssertEqual(snapshot.sourceApp, "Delete Me")
        XCTAssertTrue(snapshot.shareText.contains("Delete Me body"))

        let reopened = ModelContext(context.container)
        XCTAssertEqual(
            try reopened.fetch(FetchDescriptor<CapturedNotification>()).map(\.id),
            [survivorID],
            "Deletion and survivor must persist after reopening a model context"
        )
    }

    func testRepeatedOrStaleDeleteIsNoOp() throws {
        let context = try makeContext()
        let toDelete = try add("Gone", into: context)
        let survivor = try add("Live", into: context)
        let survivorID = survivor.id

        XCTAssertTrue(try NotificationHistoryDeletion.delete(id: toDelete.id, in: context))
        XCTAssertFalse(try NotificationHistoryDeletion.delete(id: toDelete.id, in: context))
        XCTAssertFalse(try NotificationHistoryDeletion.delete(id: UUID(), in: context))
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<CapturedNotification>()).map(\.id),
            [survivorID]
        )
    }

    func testDeleteAllRemovesHistoryButDoesNotBreakSubsequentInsert() throws {
        let context = try makeContext()
        _ = try add("First", into: context)
        _ = try add("Second", into: context)
        let last = try add("Third", into: context)
        let lastSnapshot = NotificationHistoryItem(last)

        try NotificationHistoryDeletion.deleteAll(in: context)
        XCTAssertTrue(try context.fetch(FetchDescriptor<CapturedNotification>()).isEmpty)
        XCTAssertEqual(lastSnapshot.sourceApp, "Third")
        try NotificationHistoryDeletion.deleteAll(in: context)

        let new = try add("After Reset", into: context)
        let reopened = ModelContext(context.container)
        XCTAssertEqual(
            try reopened.fetch(FetchDescriptor<CapturedNotification>()).map(\.id),
            [new.id]
        )
    }
}
