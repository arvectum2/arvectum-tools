import XCTest
import UserNotifications
@testable import WhatIOS

private final class FakeNoteScheduler: NoteReminderScheduling {
    var accessGranted = true
    var failSchedule = false
    var pending = [String: NoteReminder]()
    var cancelled = [String]()
    var scheduledCount = 0

    func requestAccess() async throws -> Bool { accessGranted }
    func notificationsAuthorized() async -> Bool { accessGranted }
    func pendingIdentifiers() async -> Set<String> { Set(pending.keys) }

    func schedule(_ reminder: NoteReminder) async throws {
        if failSchedule {
            throw NSError(domain: "Mock scheduler failure", code: 1)
        }
        pending[reminder.notificationIdentifier] = reminder
        scheduledCount += 1
    }

    func cancel(identifier: String) {
        pending.removeValue(forKey: identifier)
        cancelled.append(identifier)
    }
}

@MainActor
final class NoteReminderTests: XCTestCase {
    private func root() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-reminders-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        return directory
    }

    func testManualReminderHasStableIDAndIsIdempotentlyRescheduled() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repo = NoteReminderRepository(rootURL: directory)
        let fake = FakeNoteScheduler()
        let manager = NoteReminderManager(repository: repo, scheduler: fake)
        let id = UUID()
        XCTAssertNil(manager.reminder(for: id))
        XCTAssertTrue(fake.pending.isEmpty) // No automatic reminders

        await manager.schedule(noteID: id, afterHours: 1)
        let first = try XCTUnwrap(manager.reminder(for: id))
        XCTAssertEqual(first.status, .scheduled)
        XCTAssertTrue(abs(first.remindAt.timeIntervalSinceNow - 3600) < 5)
        XCTAssertEqual(fake.pending.count, 1)

        await manager.schedule(noteID: id, afterHours: 3)
        let last = try XCTUnwrap(manager.reminder(for: id))
        XCTAssertEqual(last.id, first.id)
        XCTAssertEqual(last.createdAt, first.createdAt)
        XCTAssertTrue(abs(last.remindAt.timeIntervalSinceNow - 10800) < 5)
        XCTAssertEqual(try repo.all().count, 1)
        XCTAssertEqual(fake.pending.count, 1)
        XCTAssertEqual(fake.scheduledCount, 2)
        XCTAssertEqual(fake.pending[last.notificationIdentifier], last)
    }

    func testPermissionDenialNeverPersistsReminder() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repo = NoteReminderRepository(rootURL: directory)
        let fake = FakeNoteScheduler()
        fake.accessGranted = false
        let manager = NoteReminderManager(repository: repo, scheduler: fake)
        await manager.schedule(noteID: UUID(), afterHours: 2)
        XCTAssertTrue(try repo.all().isEmpty)
        XCTAssertTrue(fake.pending.isEmpty)
        XCTAssertNotNil(manager.errorMessage)
    }

    func testCancelAndMarkReviewedPersistAcrossRelaunch() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repo = NoteReminderRepository(rootURL: directory)
        let fake = FakeNoteScheduler()
        let id = UUID()
        let manager = NoteReminderManager(repository: repo, scheduler: fake)
        await manager.schedule(noteID: id, afterHours: 1)
        manager.cancel(id)
        XCTAssertEqual(manager.reminder(for: id)?.status, .cancelled)
        XCTAssertTrue(fake.pending.isEmpty)

        let relaunch = NoteReminderManager(repository: repo, scheduler: fake)
        XCTAssertEqual(relaunch.reminder(for: id)?.status, .cancelled)
        await relaunch.reconcile()
        XCTAssertTrue(fake.pending.isEmpty)

        await relaunch.schedule(noteID: id, afterHours: 2)
        relaunch.markReviewed(id)
        XCTAssertEqual(relaunch.reminder(for: id)?.status, .reviewed)
        XCTAssertTrue(fake.pending.isEmpty)
        let again = NoteReminderManager(repository: repo, scheduler: fake)
        XCTAssertEqual(again.reminder(for: id)?.status, .reviewed)
    }

    func testMissedNotificationRequestIsRepairedAfterCrash() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repo = NoteReminderRepository(rootURL: directory)
        let fake = FakeNoteScheduler()
        let id = UUID()
        let entry = NoteReminder(
            id: id, createdAt: Date(),
            remindAt: Date().addingTimeInterval(3600), status: .scheduled
        )
        try repo.put(entry) // Crash occurred after durable intent, before system add.
        let relaunched = NoteReminderManager(repository: repo, scheduler: fake)
        await relaunched.reconcile()
        XCTAssertEqual(fake.pending[entry.notificationIdentifier], entry)
        await relaunched.reconcile()
        XCTAssertEqual(fake.scheduledCount, 1)
    }

    func testSchedulingFailureRollsBackDurableState() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repo = NoteReminderRepository(rootURL: directory)
        let fake = FakeNoteScheduler()
        fake.failSchedule = true
        let manager = NoteReminderManager(repository: repo, scheduler: fake)
        await manager.schedule(noteID: UUID(), afterHours: 1)
        XCTAssertTrue(try repo.all().isEmpty)
        XCTAssertTrue(fake.pending.isEmpty)
        XCTAssertNotNil(manager.errorMessage)
    }

    func testDeletingNoteRemovesOnlyItsReminder() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repo = NoteReminderRepository(rootURL: directory)
        let fake = FakeNoteScheduler()
        let manager = NoteReminderManager(repository: repo, scheduler: fake)
        let deleted = UUID()
        let kept = UUID()
        await manager.schedule(noteID: deleted, afterHours: 1)
        await manager.schedule(noteID: kept, afterHours: 2)
        manager.noteWasDeleted(deleted)
        XCTAssertNil(manager.reminder(for: deleted))
        XCTAssertNotNil(manager.reminder(for: kept))
        XCTAssertEqual(fake.pending.count, 1)
        XCTAssertEqual(try repo.all().map(\.id), [kept])
    }

    func testNotificationBodyNeverContainsPrivateText() {
        let id = UUID()
        let content = DeviceNoteReminderScheduler.privateNotificationContent(noteID: id)
        XCTAssertEqual(content.userInfo["noteID"] as? String, id.uuidString)
        XCTAssertFalse(content.title.contains("Confidential patient records"))
        XCTAssertFalse(content.body.contains("Confidential patient records"))
        XCTAssertFalse(content.body.contains(id.uuidString))
    }
}
