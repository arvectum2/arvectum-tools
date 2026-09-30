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

        guard habit.reminderEnabled, !habit.isArchived else {
            return true
        }
        guard await ensureAuthorization() else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = "Время выполнить привычку"
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
}
