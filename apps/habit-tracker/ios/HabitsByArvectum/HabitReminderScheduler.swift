import Foundation
import UserNotifications

enum HabitReminderScheduler {
    private static let prefix = "habit-reminder"

    static func ensureAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(
                options: [.alert, .sound]
            )) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func sync(habit: Habit) async -> Bool {
        let center = UNUserNotificationCenter.current()
        remove(habitID: habit.id)

        guard
            habit.reminderEnabled,
            !habit.isArchived,
            !habit.isPaused
        else {
            return true
        }
        guard await ensureAuthorization() else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = L10n.string("reminder.notification.body")
        content.sound = .default

        for components in notificationComponents(
            schedule: habit.schedule,
            hour: habit.reminderHour,
            minute: habit.reminderMinute
        ) {
            let weekday = components.weekday ?? 0
            let request = UNNotificationRequest(
                identifier: identifier(
                    habitID: habit.id,
                    weekday: weekday
                ),
                content: content,
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )
            )

            do {
                try await center.add(request)
            } catch {
                return false
            }
        }

        return true
    }

    static func remove(habitID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: (1...7).map {
                    identifier(habitID: habitID, weekday: $0)
                }
            )
    }

    static func notificationComponents(
        schedule: HabitSchedule,
        hour: Int,
        minute: Int
    ) -> [DateComponents] {
        weekdayNumbers(for: schedule).map { weekday in
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            return components
        }
    }

    static func weekdayNumbers(
        for schedule: HabitSchedule
    ) -> [Int] {
        (1...7).filter {
            schedule.contains(HabitSchedule.option(for: $0))
        }
    }

    private static func identifier(
        habitID: UUID,
        weekday: Int
    ) -> String {
        "\(prefix)-\(habitID.uuidString)-\(weekday)"
    }

#if DEBUG
    static func debugDumpIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains(
            "--diagnose-notifications"
        ) else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(prefix) }
            .sorted { $0.identifier < $1.identifier }

        print("HABITS_NOTIFICATION_AUTH=\(settings.authorizationStatus.rawValue)")
        print("HABITS_PENDING_COUNT=\(requests.count)")

        for request in requests {
            let next = (request.trigger as? UNCalendarNotificationTrigger)?
                .nextTriggerDate()?
                .ISO8601Format() ?? "nil"
            let components = (request.trigger as? UNCalendarNotificationTrigger)?
                .dateComponents.description ?? "nil"
            print(
                "HABITS_PENDING id=\(request.identifier) " +
                "title=\(request.content.title) " +
                "components=\(components) next=\(next)"
            )
        }
    }
#endif
}
