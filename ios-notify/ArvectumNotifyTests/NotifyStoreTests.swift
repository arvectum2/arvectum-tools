import SwiftData
import XCTest
@testable import ArvectumNotify

final class NotifyStoreTests: XCTestCase {
    func testSecondIdenticalCaptureIsMarkedAsDuplicate() async throws {
        let schema = Schema([
            CapturedNotification.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let writer = NotifyPersistenceActor(
            modelContainer: container
        )

        let now = Date()
        let first = NotificationCaptureDraft(
            sourceApp: "Test App",
            sourceBundleIdentifier: "com.example.test",
            titleText: "Title",
            subtitleText: "Subtitle",
            bodyText: "Body",
            receivedAt: now,
            capturedAt: now
        )
        let second = NotificationCaptureDraft(
            sourceApp: first.sourceApp,
            sourceBundleIdentifier: first.sourceBundleIdentifier,
            titleText: first.titleText,
            subtitleText: first.subtitleText,
            bodyText: first.bodyText,
            receivedAt: now.addingTimeInterval(1),
            capturedAt: now.addingTimeInterval(1)
        )

        _ = try await writer.save(first)
        _ = try await writer.save(second)

        let context = ModelContext(container)
        let records = try context.fetch(
            FetchDescriptor<CapturedNotification>(
                sortBy: [SortDescriptor(\.capturedAt)]
            )
        )

        XCTAssertEqual(records.count, 2)
        XCTAssertFalse(records[0].duplicateCandidate)
        XCTAssertTrue(records[1].duplicateCandidate)
    }
}

final class ShortcutNotificationPayloadTests: XCTestCase {
    func testMultilineFallbackSplitsTitleAndBody() {
        let payload = ShortcutNotificationPayload(
            title: "Sender\nTest message",
            subtitle: nil,
            message: nil
        )

        XCTAssertEqual(payload.titleText, "Sender")
        XCTAssertEqual(payload.subtitleText, "")
        XCTAssertEqual(payload.bodyText, "Test message")
    }

    func testStructuredFieldsArePreserved() {
        let payload = ShortcutNotificationPayload(
            title: "Sender",
            subtitle: "Chat",
            message: "Message body"
        )

        XCTAssertEqual(payload.titleText, "Sender")
        XCTAssertEqual(payload.subtitleText, "Chat")
        XCTAssertEqual(payload.bodyText, "Message body")
    }
}
