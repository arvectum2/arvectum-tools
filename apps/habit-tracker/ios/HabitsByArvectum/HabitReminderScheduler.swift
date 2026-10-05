import Foundation
import UserNotifications

enum HabitReminderScheduler {
    private static let prefix = "habit-reminder"
    private static let oneOffPrefix = "one-off-reminder"
    static let planningDayCount = 60
    static let maxPendingRequests = 60


    struct ReminderPlanItem: Equatable {
        let habitID: UUID
        let fireDate: Date
        let dayKey: String
    }

    private struct Candidate {
        let habit: Habit
        let fireDate: Date
        let dayKey: String
    }

    private enum ManagedCandidateKind {
        case habit(Habit, dayKey: String)
        case oneOff(OneOffReminder)
    }

    private struct ManagedCandidate {
        let fireDate: Date
        let priority: Int
        let createdAt: Date
        let kind: ManagedCandidateKind
    }

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

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func shouldSchedule(habit: Habit) -> Bool {
        habit.reminderEnabled &&
        !habit.isArchived &&
        !habit.isPaused &&
        !habit.usesFlexibleWeeklyTarget
    }

    static func reminderDates(
        habit: Habit,
        checkIns: [HabitCheckIn] = [],
        skips: [HabitSkip] = [],
        from referenceDate: Date,
        daysAhead: Int = planningDayCount,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Date] {
        guard shouldSchedule(habit: habit), daysAhead > 0 else {
            return []
        }

        let start = calendar.startOfDay(for: referenceDate)
        var dates: [Date] = []

        for offset in 0..<daysAhead {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: start
            ) else { continue }

            guard habit.schedule.includes(day, calendar: calendar) else {
                continue
            }

            let completed = HabitMetrics.isCompleted(
                habitID: habit.id,
                on: day,
                checkIns: checkIns,
                calendar: calendar
            )
            let skipped = HabitMetrics.isSkipped(
                habitID: habit.id,
                on: day,
                skips: skips,
                calendar: calendar
            )
            guard !completed && !skipped else { continue }

            guard let fireDate = calendar.date(
                bySettingHour: habit.reminderHour,
                minute: habit.reminderMinute,
                second: 0,
                of: day
            ), fireDate > referenceDate else {
                continue
            }

            dates.append(fireDate)
        }

        return dates
    }


    static func reminderPlan(
        habits: [Habit],
        checkIns: [HabitCheckIn] = [],
        skips: [HabitSkip] = [],
        from referenceDate: Date,
        daysAhead: Int = planningDayCount,
        limit: Int = maxPendingRequests,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ReminderPlanItem] {
        guard daysAhead > 0, limit > 0 else { return [] }

        let candidates = habits
            .filter(shouldSchedule)
            .flatMap { habit in
                reminderDates(
                    habit: habit,
                    checkIns: checkIns,
                    skips: skips,
                    from: referenceDate,
                    daysAhead: daysAhead,
                    calendar: calendar
                ).map { fireDate in
                    Candidate(
                        habit: habit,
                        fireDate: fireDate,
                        dayKey: HabitDayKey.make(
                            for: fireDate,
                            calendar: calendar
                        )
                    )
                }
            }
            .sorted {
                if $0.fireDate != $1.fireDate {
                    return $0.fireDate < $1.fireDate
                }
                if $0.habit.sortOrder != $1.habit.sortOrder {
                    return $0.habit.sortOrder < $1.habit.sortOrder
                }
                return $0.habit.createdAt < $1.habit.createdAt
            }

        return candidates.prefix(limit).map {
            ReminderPlanItem(
                habitID: $0.habit.id,
                fireDate: $0.fireDate,
                dayKey: $0.dayKey
            )
        }
    }

    @MainActor
    static func syncAll(
        habits: [Habit],
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        oneOffReminders: [OneOffReminder] = [],
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) async -> Bool {
        let center = UNUserNotificationCenter.current()
        await removeAllManagedRequests(center: center)

        let eligibleHabits = habits.filter(shouldSchedule)
        let pendingOneOffs = oneOffReminders.filter {
            !$0.isCompleted && $0.dueAt > referenceDate
        }

        guard !eligibleHabits.isEmpty || !pendingOneOffs.isEmpty else {
            return true
        }
        guard await isAuthorized() else { return false }

        let habitCandidates = reminderPlan(
            habits: eligibleHabits,
            checkIns: checkIns,
            skips: skips,
            from: referenceDate,
            limit: maxPendingRequests,
            calendar: calendar
        ).compactMap { item -> ManagedCandidate? in
            guard let habit = eligibleHabits.first(where: {
                $0.id == item.habitID
            }) else { return nil }
            return ManagedCandidate(
                fireDate: item.fireDate,
                priority: 1,
                createdAt: habit.createdAt,
                kind: .habit(habit, dayKey: item.dayKey)
            )
        }

        let oneOffCandidates = pendingOneOffs.map {
            ManagedCandidate(
                fireDate: $0.dueAt,
                priority: 0,
                createdAt: $0.createdAt,
                kind: .oneOff($0)
            )
        }

        let plan = (habitCandidates + oneOffCandidates)
            .sorted {
                if $0.fireDate != $1.fireDate {
                    return $0.fireDate < $1.fireDate
                }
                if $0.priority != $1.priority {
                    return $0.priority < $1.priority
                }
                return $0.createdAt < $1.createdAt
            }
            .prefix(maxPendingRequests)

        for item in plan {
            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: item.fireDate
            )
            components.calendar = nil

            let identifier: String
            let content: UNMutableNotificationContent

            switch item.kind {
            case .habit(let habit, let dayKey):
                // Recurring habits follow the device's current local wall time.
                components.timeZone = nil
                identifier = requestIdentifier(
                    habitID: habit.id,
                    dayKey: dayKey
                )
                content = notificationContent(for: habit)
            case .oneOff(let reminder):
                // A one-off reminder represents one concrete moment.
                components.timeZone = calendar.timeZone
                identifier = oneOffRequestIdentifier(reminderID: reminder.id)
                content = oneOffNotificationContent(for: reminder)
            }

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
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

    private static func removeAllManagedRequests(
        center: UNUserNotificationCenter
    ) async {
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter {
                $0.hasPrefix(prefix) || $0.hasPrefix(oneOffPrefix)
            }

        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    static func notificationContent(
        for habit: Habit
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = L10n.string("reminder.notification.body")
        content.sound = .default
        content.categoryIdentifier = HabitNotificationActions.categoryIdentifier
        content.userInfo = [
            HabitNotificationActions.habitIDKey: habit.id.uuidString
        ]
        return content
    }

    static func oneOffNotificationContent(
        for reminder: OneOffReminder
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = L10n.string("oneoff.notification.body")
        content.sound = .default
        content.categoryIdentifier =
            OneOffReminderNotificationActions.categoryIdentifier
        content.userInfo = [
            OneOffReminderNotificationActions.reminderIDKey:
                reminder.id.uuidString
        ]
        return content
    }

    static func requestIdentifier(
        habitID: UUID,
        dayKey: String
    ) -> String {
        [prefix, habitID.uuidString, dayKey].joined(separator: "-")
    }

    static func oneOffRequestIdentifier(reminderID: UUID) -> String {
        [oneOffPrefix, reminderID.uuidString].joined(separator: "-")
    }

#if DEBUG
    static func debugDumpIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains(
            "--diagnose-notifications"
        ) else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
            .filter {
                $0.identifier.hasPrefix(prefix) ||
                $0.identifier.hasPrefix(oneOffPrefix)
            }
            .sorted { $0.identifier < $1.identifier }

        HabitDebugLog.emit(
            "HABITS_NOTIFICATION_AUTH=" +
            String(settings.authorizationStatus.rawValue)
        )
        HabitDebugLog.emit(
            "HABITS_PENDING_COUNT=" + String(requests.count)
        )

        let delivered = await center.deliveredNotifications()
            .filter {
                $0.request.identifier.hasPrefix(prefix) ||
                $0.request.identifier.hasPrefix(oneOffPrefix)
            }
            .sorted { $0.request.identifier < $1.request.identifier }
        HabitDebugLog.emit(
            "HABITS_DELIVERED_COUNT=" + String(delivered.count)
        )
        for notification in delivered {
            HabitDebugLog.emit(
                "HABITS_DELIVERED id=" + notification.request.identifier +
                " title=" + notification.request.content.title
            )
        }

        for request in requests {
            let next = (request.trigger as? UNCalendarNotificationTrigger)?
                .nextTriggerDate()?
                .ISO8601Format() ?? "nil"
            let components = (request.trigger as? UNCalendarNotificationTrigger)?
                .dateComponents.description ?? "nil"
            HabitDebugLog.emit(
                "HABITS_PENDING id=" + request.identifier +
                " title=" + request.content.title +
                " components=" + components +
                " next=" + next
            )
        }
    }
#endif
}
