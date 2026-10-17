import XCTest
import UserNotifications
@testable import WhatIOS

private final class FakeNoteScheduler: NoteReminderScheduling {
    var accessGranted = true
    var failSchedule = false
    var pending = [String: NoteReminder]()
    var cancelled = [String]()
    var scheduledCount = 0
    var permissionPromptCount = 0

    func requestAccess() async throws -> Bool {
        permissionPromptCount += 1
        return accessGranted
    }
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

    private func isolatedPreferences() -> UserDefaults {
        let suiteName = "what-auto-reminders-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testAutomaticFollowUpDefaultsOffAndNeverRequestsPermissionOnLaunch() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fake = FakeNoteScheduler()
        let defaults = isolatedPreferences()
        let manager = NoteReminderManager(repository: NoteReminderRepository(rootURL: directory),
                                          scheduler: fake, preferences: defaults)
        XCTAssertEqual(manager.automaticDelayHours, 0)
        await manager.scheduleAutomaticallyIfEnabled(noteID: UUID())
        XCTAssertEqual(fake.permissionPromptCount, 0)
        XCTAssertEqual(fake.scheduledCount, 0)
        XCTAssertTrue(try NoteReminderRepository(rootURL: directory).all().isEmpty)
    }

    func testExplicitOptInSchedulesOnlyOnceAndNeverOverridesManualOrCancelled() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fake = FakeNoteScheduler()
        let defaults = isolatedPreferences()
        let repo = NoteReminderRepository(rootURL: directory)
        let manager = NoteReminderManager(repository: repo, scheduler: fake,
                                          preferences: defaults)
        await manager.configureAutomaticFollowUp(hours: 2)
        XCTAssertEqual(manager.automaticDelayHours, 2)
        XCTAssertEqual(fake.permissionPromptCount, 1)

        let watchNote = UUID()
        await manager.scheduleAutomaticallyIfEnabled(noteID: watchNote)
        await manager.scheduleAutomaticallyIfEnabled(noteID: watchNote) // Duplicate ACK.
        let scheduled = try XCTUnwrap(manager.reminder(for: watchNote))
        XCTAssertTrue(abs(scheduled.remindAt.timeIntervalSinceNow - 7200) < 5)
        XCTAssertEqual(fake.scheduledCount, 1)
        XCTAssertEqual(fake.permissionPromptCount, 1,
                       "A background Watch delivery must never prompt")
        XCTAssertEqual(fake.pending.count, 1)
        XCTAssertEqual(try repo.all().count, 1)

        let manuallyScheduled = UUID()
        await manager.schedule(noteID: manuallyScheduled, afterHours: 3)
        let original = try XCTUnwrap(manager.reminder(for: manuallyScheduled))
        await manager.scheduleAutomaticallyIfEnabled(noteID: manuallyScheduled)
        XCTAssertEqual(manager.reminder(for: manuallyScheduled), original)
        XCTAssertEqual(fake.scheduledCount, 2)

        manager.cancel(manuallyScheduled)
        await manager.scheduleAutomaticallyIfEnabled(noteID: manuallyScheduled)
        XCTAssertEqual(manager.reminder(for: manuallyScheduled)?.status, .cancelled)
        XCTAssertEqual(fake.scheduledCount, 2,
                       "Automatic mode must never resurrect an explicit cancellation")
        let relaunched = NoteReminderManager(repository: repo, scheduler: fake,
                                             preferences: defaults)
        XCTAssertEqual(relaunched.automaticDelayHours, 2)
        await relaunched.configureAutomaticFollowUp(hours: 0)
        XCTAssertEqual(relaunched.automaticDelayHours, 0)
        await relaunched.scheduleAutomaticallyIfEnabled(noteID: UUID())
        XCTAssertEqual(fake.scheduledCount, 2)
        XCTAssertEqual(NoteReminderManager(repository: repo, scheduler: fake,
                                           preferences: defaults).automaticDelayHours, 0)
        XCTAssertEqual(manager.reminder(for: watchNote), scheduled,
                       "Turning off the rule must not erase existing reminders")
    }

    func testPermissionDenialDoesNotEnableAutomaticRuleOrPersistSettings() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fake = FakeNoteScheduler()
        fake.accessGranted = false
        let defaults = isolatedPreferences()
        let manager = NoteReminderManager(repository: NoteReminderRepository(rootURL: directory),
                                          scheduler: fake, preferences: defaults)
        await manager.configureAutomaticFollowUp(hours: 1)
        XCTAssertEqual(manager.automaticDelayHours, 0)
        XCTAssertEqual(fake.permissionPromptCount, 1)
        XCTAssertNotNil(manager.errorMessage)
        await manager.scheduleAutomaticallyIfEnabled(noteID: UUID())
        XCTAssertEqual(fake.scheduledCount, 0)
        XCTAssertTrue(try NoteReminderRepository(rootURL: directory).all().isEmpty)
        XCTAssertEqual(NoteReminderManager(repository: NoteReminderRepository(rootURL: directory),
                                           scheduler: fake, preferences: defaults).automaticDelayHours, 0)
    }

    func testAutomaticRuleDoesNotPromptIfUserRevokesPermissionLater() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fake = FakeNoteScheduler()
        let manager = NoteReminderManager(repository: NoteReminderRepository(rootURL: directory),
                                          scheduler: fake, preferences: isolatedPreferences())
        await manager.configureAutomaticFollowUp(hours: 1)
        fake.accessGranted = false
        await manager.scheduleAutomaticallyIfEnabled(noteID: UUID())
        XCTAssertEqual(fake.permissionPromptCount, 1)
        XCTAssertEqual(fake.scheduledCount, 0)
    }

    func testCatchUpOnRelaunchOnlyForNewNotesSinceOptIn() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fake = FakeNoteScheduler()
        let defaults = isolatedPreferences()
        let repo = NoteReminderRepository(rootURL: directory)
        let manager = NoteReminderManager(repository: repo, scheduler: fake,
                                          preferences: defaults)
        let old = UUID(), recent = UUID(), veryOld = UUID()
        let beforeOptIn = Date().addingTimeInterval(-40)
        await manager.configureAutomaticFollowUp(hours: 2)
        let createdAfterOptIn = Date().addingTimeInterval(1)
        let input: [(id: UUID, createdAt: Date)] = [
            (old, beforeOptIn),
            (recent, createdAfterOptIn),
            (veryOld, Date().addingTimeInterval(-4 * 24 * 3600))
        ]
        await manager.catchUpNewNotes(input)
        await manager.catchUpNewNotes(input) // Launch/reconnect duplication.
        XCTAssertNil(manager.reminder(for: old))
        XCTAssertNil(manager.reminder(for: veryOld))
        XCTAssertEqual(manager.reminder(for: recent)?.status, .scheduled)
        XCTAssertEqual(fake.scheduledCount, 1)
        XCTAssertEqual(fake.permissionPromptCount, 1,
                       "Relaunch catch-up must never show another permission prompt")
        XCTAssertEqual(try repo.all().count, 1)

        let anotherManager = NoteReminderManager(repository: repo, scheduler: fake,
                                                 preferences: defaults)
        await anotherManager.catchUpNewNotes(input)
        XCTAssertEqual(fake.scheduledCount, 1,
                       "New manager must recognize existing UUID reminder")
        await anotherManager.configureAutomaticFollowUp(hours: 0)
        await anotherManager.catchUpNewNotes([(UUID(), Date().addingTimeInterval(2))])
        XCTAssertEqual(fake.scheduledCount, 1)
    }

    func testMigratedOptInRuleDoesNotBackfillOldInbox() async throws {
        let directory = try root()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fake = FakeNoteScheduler()
        let defaults = isolatedPreferences()
        defaults.set(1, forKey: "what.autoFollowUp.hours")
        let manager = NoteReminderManager(repository: NoteReminderRepository(rootURL: directory),
                                          scheduler: fake, preferences: defaults)
        XCTAssertEqual(manager.automaticDelayHours, 1)
        await manager.catchUpNewNotes([(UUID(), Date().addingTimeInterval(-90))])
        XCTAssertEqual(fake.scheduledCount, 0)
        XCTAssertEqual(fake.permissionPromptCount, 0)
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
