import Foundation
import UserNotifications

/// Manual, opt-in reminders. A notification contains only a generic prompt;
/// private transcripts, note text and audio never leave local app storage.
struct NoteReminder: Codable, Identifiable, Equatable {
    enum Status: String, Codable { case scheduled, cancelled, reviewed }
    let id: UUID                 // The stable note/recording UUID
    let createdAt: Date
    var remindAt: Date
    var status: Status

    var notificationIdentifier: String { "what.review.\(id.uuidString)" }
}

final class NoteReminderRepository {
    private let indexURL: URL
    private let files: FileManager
    private let lock = NSLock()

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        files = fileManager
        let root = rootURL ?? fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("What", isDirectory: true)
        indexURL = root.appendingPathComponent("review-reminders.json")
    }

    func all() throws -> [NoteReminder] {
        lock.lock()
        defer { lock.unlock() }
        return try read()
    }

    func put(_ reminder: NoteReminder) throws {
        lock.lock()
        defer { lock.unlock() }
        var reminders = try read()
        reminders.removeAll { $0.id == reminder.id }
        reminders.append(reminder)
        try persist(reminders)
    }

    func remove(_ id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        var reminders = try read()
        reminders.removeAll { $0.id == id }
        try persist(reminders)
    }

    func updateStatus(_ id: UUID, to status: NoteReminder.Status) throws {
        lock.lock()
        defer { lock.unlock() }
        var reminders = try read()
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[i].status = status
        try persist(reminders)
    }

    private func read() throws -> [NoteReminder] {
        guard files.fileExists(atPath: indexURL.path) else { return [] }
        return try JSONDecoder().decode(
            [NoteReminder].self, from: Data(contentsOf: indexURL)
        )
    }

    private func persist(_ values: [NoteReminder]) throws {
        try files.createDirectory(
            at: indexURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(values).write(to: indexURL, options: .atomic)
    }
}

protocol NoteReminderScheduling {
    func requestAccess() async throws -> Bool
    func notificationsAuthorized() async -> Bool
    func schedule(_ reminder: NoteReminder) async throws
    func pendingIdentifiers() async -> Set<String>
    func cancel(identifier: String)
}

struct DeviceNoteReminderScheduler: NoteReminderScheduling {
    private var center: UNUserNotificationCenter { .current() }

    func requestAccess() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func notificationsAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional
    }

    static func privateNotificationContent(noteID: UUID) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = CaptureBrand.text("Ухват: вернуться к заметке",
                                         "UhWhat?: review a note")
        content.body = CaptureBrand.text("Вы сохранили мысль. Время её пересмотреть.",
                                        "A saved thought is ready to review.")
        content.sound = .default
        content.userInfo = ["noteID": noteID.uuidString]
        return content
    }

    func schedule(_ reminder: NoteReminder) async throws {
        let content = Self.privateNotificationContent(noteID: reminder.id)
        let seconds = max(1, reminder.remindAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: reminder.notificationIdentifier,
            content: content, trigger: trigger
        )
        try await center.add(request)
    }

    func pendingIdentifiers() async -> Set<String> {
        Set(await center.pendingNotificationRequests().map(\.identifier))
    }

    func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

/// Per-UUID serialization avoids accidental double requests when a user taps
/// a preset repeatedly. Interrupted scheduling is repaired on the next launch.
@MainActor
final class NoteReminderManager: ObservableObject {
    @Published private(set) var reminders: [UUID: NoteReminder] = [:]
    @Published var errorMessage: String?
    /// 0 = off. No new user gets automatic notifications by default.
    @Published private(set) var automaticDelayHours = 0
    private static let autoDelayKey = "what.autoFollowUp.hours"
    private static let autoEnabledDateKey = "what.autoFollowUp.enabledAt"

    private let repository: NoteReminderRepository
    private let scheduler: any NoteReminderScheduling
    private let preferences: UserDefaults
    private var busy = Set<UUID>()

    init(
        repository: NoteReminderRepository = NoteReminderRepository(),
        scheduler: any NoteReminderScheduling = DeviceNoteReminderScheduler(),
        preferences: UserDefaults = .standard
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.preferences = preferences
        let stored = preferences.integer(forKey: Self.autoDelayKey)
        automaticDelayHours = (1...3).contains(stored) ? stored : 0
        // A setting from an older build has no creation-time watermark.
        // Start its catch-up window now rather than notify for old notes.
        if automaticDelayHours > 0,
           preferences.object(forKey: Self.autoEnabledDateKey) == nil {
            preferences.set(Date(), forKey: Self.autoEnabledDateKey)
        }
        do {
            reminders = Dictionary(uniqueKeysWithValues: try repository.all().map {
                ($0.id, $0)
            })
        } catch {
            errorMessage = CaptureBrand.text(
                "Не удалось открыть напоминания: ",
                "Could not load reminders: "
            ) + error.localizedDescription
        }
    }

    func reminder(for noteID: UUID) -> NoteReminder? {
        reminders[noteID]
    }

    /// The user explicitly chooses Off, 1, 2 or 3 hours in the settings menu.
    /// Only enabling the rule may request system notification permission.
    func configureAutomaticFollowUp(hours: Int) async {
        guard (0...3).contains(hours) else { return }
        if hours == 0 {
            automaticDelayHours = 0
            preferences.set(0, forKey: Self.autoDelayKey)
            preferences.removeObject(forKey: Self.autoEnabledDateKey)
            return
        }
        do {
            guard try await scheduler.requestAccess() else {
                errorMessage = CaptureBrand.text(
                    "Разрешение на уведомления не предоставлено.",
                    "Notifications are disabled. Enable them in Settings."
                )
                return // Never enable a rule which cannot schedule alerts.
            }
            if automaticDelayHours == 0 {
                preferences.set(Date(), forKey: Self.autoEnabledDateKey)
            }
            automaticDelayHours = hours
            preferences.set(hours, forKey: Self.autoDelayKey)
        } catch {
            errorMessage = CaptureBrand.text(
                "Не удалось включить автоматические напоминания: ",
                "Could not enable automatic reminders: "
            ) + error.localizedDescription
        }
    }

    /// Called only for a newly, durably saved local note/recording; never
    /// when enumerating old notes on launch or replaying an old Watch UUID.
    /// It must not prompt from a background WatchConnectivity callback.
    func scheduleAutomaticallyIfEnabled(noteID: UUID) async {
        let hours = automaticDelayHours
        guard (1...3).contains(hours), reminders[noteID] == nil,
              !busy.contains(noteID), await scheduler.notificationsAuthorized(),
              automaticDelayHours == hours, reminders[noteID] == nil
        else { return }
        await scheduleVerified(noteID: noteID, afterHours: hours,
                               needsPermissionPrompt: false, onlyIfUnscheduled: true)
    }

    /// Recover newly created notes whose Watch import or phone save completed
    /// while the UI was not alive. Never scan the entire historical Inbox.
    /// A bounded 24h lookback prevents a newly enabled rule from notifying
    /// for old recordings after an upgrade or a long period offline.
    func catchUpNewNotes(_ candidates: [(id: UUID, createdAt: Date)]) async {
        guard automaticDelayHours > 0,
              let enabledAt = preferences.object(forKey: Self.autoEnabledDateKey) as? Date
        else { return }
        let oldest = max(enabledAt, Date().addingTimeInterval(-24 * 3600))
        for item in candidates where item.createdAt >= oldest {
            await scheduleAutomaticallyIfEnabled(noteID: item.id)
        }
    }

    func schedule(noteID: UUID, afterHours hours: Int) async {
        await scheduleVerified(noteID: noteID, afterHours: hours,
                               needsPermissionPrompt: true, onlyIfUnscheduled: false)
    }

    private func scheduleVerified(noteID: UUID, afterHours hours: Int,
                                  needsPermissionPrompt: Bool,
                                  onlyIfUnscheduled: Bool) async {
        guard (1...72).contains(hours), !busy.contains(noteID),
              !onlyIfUnscheduled || reminders[noteID] == nil else { return }
        busy.insert(noteID)
        defer { busy.remove(noteID) }
        let original = reminders[noteID]
        do {
            if needsPermissionPrompt {
                guard try await scheduler.requestAccess() else {
                    errorMessage = CaptureBrand.text(
                        "Разрешение на уведомления не предоставлено.",
                        "Notifications are disabled. Enable them in Settings."
                    )
                    return
                }
            }
            let reminder = NoteReminder(
                id: noteID, createdAt: original?.createdAt ?? Date(),
                remindAt: Date().addingTimeInterval(TimeInterval(hours) * 3600),
                status: .scheduled
            )
            // Durable intention first; reconcile recreates a missing system
            // request if the app is killed before add completes.
            try repository.put(reminder)
            do {
                try await scheduler.schedule(reminder)
                reminders[noteID] = reminder
            } catch {
                if let original { try repository.put(original) }
                else { try repository.remove(noteID) }
                reminders[noteID] = original
                throw error
            }
        } catch {
            errorMessage = CaptureBrand.text(
                "Не удалось установить напоминание: ",
                "Could not schedule reminder: "
            ) + error.localizedDescription
        }
    }

    func cancel(_ noteID: UUID) {
        guard let reminder = reminders[noteID] else { return }
        do {
            try repository.updateStatus(noteID, to: .cancelled)
            var updated = reminder
            updated.status = .cancelled
            reminders[noteID] = updated
            scheduler.cancel(identifier: reminder.notificationIdentifier)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markReviewed(_ noteID: UUID) {
        guard let reminder = reminders[noteID] else { return }
        do {
            try repository.updateStatus(noteID, to: .reviewed)
            var updated = reminder
            updated.status = .reviewed
            reminders[noteID] = updated
            scheduler.cancel(identifier: reminder.notificationIdentifier)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func noteWasDeleted(_ noteID: UUID) {
        do {
            try repository.remove(noteID)
            reminders.removeValue(forKey: noteID)
            scheduler.cancel(identifier: "what.review.\(noteID.uuidString)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Reconcile only authorized requests. Never prompt on app launch and
    /// never reschedule expired or explicitly cancelled/reviewed reminders.
    func reconcile() async {
        guard await scheduler.notificationsAuthorized() else { return }
        let pending = await scheduler.pendingIdentifiers()
        for reminder in reminders.values {
            guard !busy.contains(reminder.id) else { continue }
            if reminder.status != .scheduled {
                if pending.contains(reminder.notificationIdentifier) {
                    scheduler.cancel(identifier: reminder.notificationIdentifier)
                }
            } else if reminder.remindAt > Date(),
                      !pending.contains(reminder.notificationIdentifier) {
                do {
                    try await scheduler.schedule(reminder)
                } catch {
                    errorMessage = CaptureBrand.text(
                        "Одно из напоминаний не удалось восстановить: ",
                        "Could not restore a reminder: "
                    ) + error.localizedDescription
                }
            }
        }
    }
}
