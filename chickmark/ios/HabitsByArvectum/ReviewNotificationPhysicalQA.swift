#if REVIEW_HANDOFF_QA
import Foundation
import SwiftData
import UserNotifications

/// Explicit physical QA only. Never compiled into a store/ordinary QA build.
/// The trigger exercises the regular SwiftData OneOff -> HabitReminderCoordinator
/// -> UNCalendarNotificationTrigger path, not a synthetic notification shortcut.
@MainActor
enum ReviewNotificationPhysicalQA {
    static let launchFlag = "--review-notification-physical-qa"
    private static let fileName = "review-notification-physical-qa.json"
    private static let privateSentinel = "QA_PRIVATE_NOTE_NEVER_SHOW_ON_LOCKSCREEN"

    struct Result: Codable {
        var id: UUID
        var createdAt: Date
        var dueAt: Date
        var stage: String
        var permission: Int?
        var pending: Bool?
        var delivered: Bool?
        var privateTextOnNotification: Bool?
        var genericTitle: String?
        var actualTapAt: Date?
        var totalManagedPending: Int?
        var qaOneOffExists: Bool?
        var schedulerAttempts: Int?
        var lastScheduleError: String?
        var lastNextTriggerDate: Date?
        var lastDidAdd: Bool?
    }

    static var reportURL: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("ChickMark", isDirectory: true)
        return base.appendingPathComponent(fileName)
    }

    static func readReport() -> Result? {
        guard let data = try? Data(contentsOf: reportURL) else { return nil }
        return try? JSONDecoder().decode(Result.self, from: data)
    }

    private static func write(_ result: Result) {
        do {
            try FileManager.default.createDirectory(
                at: reportURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try JSONEncoder().encode(result).write(to: reportURL, options: .atomic)
        } catch {
            // The notification test must never crash user-facing UI.
        }
    }

    static func seedIfRequested(container: ModelContainer) {
        guard ProcessInfo.processInfo.arguments.contains(launchFlag) else { return }
        // Allow another explicit QA run after the previous trigger time.
        // Never create two active synthetic reminders simultaneously.
        if let previous = readReport(), previous.dueAt > Date().addingTimeInterval(10) {
            return
        }
        let id = UUID()
        let now = Date()
        let dueAt = now.addingTimeInterval(100)
        let text = "\(privateSentinel)_\(id.uuidString.prefix(8))"
        do {
            let payload = try ReviewNoteHandoff(
                noteID: id, kind: .text, createdAt: now, text: text
            )
            let context = ModelContext(container)
            let attachment = ReviewNoteAttachment(payload)
            try ReviewNoteAttachmentRepository().put(attachment)
            do {
                context.insert(OneOffReminder(
                    id: id,
                    title: "Разобрать заметку: \(text)",
                    dueAt: dueAt
                ))
                try context.save()
            } catch {
                context.rollback()
                try? ReviewNoteAttachmentRepository().remove(id)
                throw error
            }
            write(Result(id: id, createdAt: now, dueAt: dueAt, stage: "seeded"))
        } catch {
            // Failure will be visible as a missing QA report.
        }
    }

    static func inspectScheduledAndDelivered(context: ModelContext? = nil) async {
        guard var report = readReport() else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        report.permission = settings.authorizationStatus.rawValue
        let requestID = HabitReminderScheduler.oneOffRequestIdentifier(reminderID: report.id)
        let pendingAll = await center.pendingNotificationRequests()
        report.totalManagedPending = pendingAll.filter {
            $0.identifier.hasPrefix("one-off-reminder") ||
            $0.identifier.hasPrefix("habit-reminder")
        }.count
        if let context,
           let oneOffs = try? context.fetch(FetchDescriptor<OneOffReminder>()) {
            report.qaOneOffExists = oneOffs.contains { $0.id == report.id }
        }
        let pending = pendingAll.first {
            $0.identifier == requestID
        }
        let delivered = await center.deliveredNotifications().first {
            $0.request.identifier == requestID
        }
        report.pending = pending != nil
        report.delivered = delivered != nil
        if let notification = delivered?.request.content ?? pending?.content {
            report.genericTitle = notification.title
            report.privateTextOnNotification =
                notification.title.contains(privateSentinel) ||
                notification.body.contains(privateSentinel)
        }
        report.stage = report.actualTapAt != nil ? "tapped" :
            delivered != nil ? "delivered" :
            pending != nil ? "pending" : "not_found"
        write(report)
    }

    static func recordSchedulerState(
        requestID: String, nextFire: Date?, added: Bool?, error: Error? = nil
    ) {
        guard var report = readReport(),
              requestID == HabitReminderScheduler.oneOffRequestIdentifier(reminderID: report.id)
        else { return }
        report.schedulerAttempts = (report.schedulerAttempts ?? 0) + 1
        report.lastNextTriggerDate = nextFire
        if let added { report.lastDidAdd = added }
        if let error { report.lastScheduleError = String(describing: error) }
        write(report)
    }

    static func recordTap(noteID: UUID) {
        guard var report = readReport(), report.id == noteID else { return }
        report.actualTapAt = Date()
        report.stage = "tapped"
        write(report)
    }
}
#endif
