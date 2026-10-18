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

        if habit.usesCompletionInterval {
            return completionIntervalReminderDates(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                from: referenceDate,
                calendar: calendar
            )
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
                calendar: calendar,
                target: habit.dailyTarget
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

    private static func completionIntervalReminderDates(
        habit: Habit,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        from referenceDate: Date,
        calendar: Calendar
    ) -> [Date] {
        guard var candidateDay = HabitFrequency.nextCompletionIntervalDueDate(
            habit: habit,
            checkIns: checkIns,
            through: referenceDate,
            calendar: calendar
        ) else {
            return []
        }

        let today = calendar.startOfDay(for: referenceDate)
        if candidateDay < today {
            candidateDay = today
        }

        // Only the next occurrence is knowable: completing it will move the
        // following due date. One request also supports intervals beyond the
        // normal 60-day rolling horizon.
        for _ in 0..<366 {
            let completed = HabitMetrics.isCompleted(
                habitID: habit.id,
                on: candidateDay,
                checkIns: checkIns,
                calendar: calendar,
                target: habit.dailyTarget
            )
            let skipped = HabitMetrics.isSkipped(
                habitID: habit.id,
                on: candidateDay,
                skips: skips,
                calendar: calendar
            )

            if !completed && !skipped,
               let fireDate = calendar.date(
                   bySettingHour: habit.reminderHour,
                   minute: habit.reminderMinute,
                   second: 0,
                   of: candidateDay
               ),
               fireDate > referenceDate {
                return [fireDate]
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: candidateDay
            ) else {
                return []
            }
            candidateDay = nextDay
        }

        return []
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
        let eligibleHabits = habits.filter(shouldSchedule)
        let pendingOneOffs = oneOffReminders.filter {
            !$0.isCompleted && $0.dueAt > referenceDate
        }

        // Do not erase the previously scheduled requests before rebuilding.
        // UNUserNotificationCenter.removePendingNotificationRequests is
        // asynchronous; a subsequent add may race with that removal and leave
        // NO pending requests when iOS suspends the app immediately.
        if !eligibleHabits.isEmpty || !pendingOneOffs.isEmpty {
            guard await isAuthorized() else { return false }
        }

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
                createdAt: habit.createdAt,
                kind: .habit(habit, dayKey: item.dayKey)
            )
        }

        let oneOffCandidates = pendingOneOffs.map {
            ManagedCandidate(
                fireDate: $0.dueAt,
                createdAt: $0.createdAt,
                kind: .oneOff($0)
            )
        }

        // One-off reminders represent explicit commitments and must not
        // be crowded out by a dense recurring-habit schedule. Reserve the
        // system budget for them first, then fill the remaining slots with
        // the nearest recurring habit reminders.
        let reservedOneOffs = oneOffCandidates
            .sorted {
                if $0.fireDate != $1.fireDate {
                    return $0.fireDate < $1.fireDate
                }
                return $0.createdAt < $1.createdAt
            }
            .prefix(maxPendingRequests)

        let remainingCapacity = max(
            0,
            maxPendingRequests - reservedOneOffs.count
        )
        let recurringHabits = habitCandidates
            .sorted {
                if $0.fireDate != $1.fireDate {
                    return $0.fireDate < $1.fireDate
                }
                return $0.createdAt < $1.createdAt
            }
            .prefix(remainingCapacity)

        let plan = Array(reservedOneOffs) + Array(recurringHabits)

        var desiredRequests: [UNNotificationRequest] = []
        desiredRequests.reserveCapacity(plan.count)
        for item in plan {
            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
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

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components, repeats: false
            )
            desiredRequests.append(UNNotificationRequest(
                identifier: identifier, content: content, trigger: trigger
            ))
        }

        let existing = await center.pendingNotificationRequests()
        let changes = reconcile(existing: existing, desired: desiredRequests)

        // Schedule replacements FIRST; never introduce an empty-queue gap.
        // Adding a request with an existing identifier replaces just that item.
        for request in changes.toAdd {
            let trigger = request.trigger as? UNCalendarNotificationTrigger
#if REVIEW_HANDOFF_QA
            ReviewNotificationPhysicalQA.recordSchedulerState(
                requestID: request.identifier, nextFire: trigger?.nextTriggerDate(),
                added: nil
            )
#endif
            do {
                try await center.add(request)
#if REVIEW_HANDOFF_QA
                ReviewNotificationPhysicalQA.recordSchedulerState(
                    requestID: request.identifier, nextFire: trigger?.nextTriggerDate(),
                    added: true
                )
#endif
            } catch {
#if REVIEW_HANDOFF_QA
                ReviewNotificationPhysicalQA.recordSchedulerState(
                    requestID: request.identifier, nextFire: trigger?.nextTriggerDate(),
                    added: false, error: error
                )
#endif
                // Retain all previously pending items on failure; a later
                // refresh can retry without losing reminders already queued.
                return false
            }
        }

        // Only truly stale identifiers are removed, *after* additions finish.
        // There is no delete/add pair for a current reminder. A rapid
        // background suspension therefore preserves its old valid request.
        if !changes.toRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: changes.toRemove)
        }
        return true
    }

    struct ScheduleChanges {
        let toAdd: [UNNotificationRequest]
        let toRemove: [String]
    }

    static func reconcile(
        existing: [UNNotificationRequest],
        desired: [UNNotificationRequest]
    ) -> ScheduleChanges {
        let previous = Dictionary(uniqueKeysWithValues: existing
            .filter(isManaged)
            .map { ($0.identifier, $0) })
        let wanted = Set(desired.map(\.identifier))
        return ScheduleChanges(
            toAdd: desired.filter { request in
                guard let current = previous[request.identifier] else { return true }
                return !sameNotification(current, request)
            },
            toRemove: previous.keys.filter { !wanted.contains($0) }.sorted()
        )
    }

    private static func isManaged(_ request: UNNotificationRequest) -> Bool {
        request.identifier.hasPrefix(prefix + "-") ||
            request.identifier.hasPrefix(oneOffPrefix + "-")
    }

    private static func sameNotification(
        _ old: UNNotificationRequest,
        _ new: UNNotificationRequest
    ) -> Bool {
        guard let oldTrigger = old.trigger as? UNCalendarNotificationTrigger,
              let newTrigger = new.trigger as? UNCalendarNotificationTrigger
        else { return false }
        return oldTrigger.repeats == newTrigger.repeats &&
            oldTrigger.dateComponents == newTrigger.dateComponents &&
            old.content.title == new.content.title &&
            old.content.body == new.content.body &&
            old.content.categoryIdentifier == new.content.categoryIdentifier &&
            NSDictionary(dictionary: old.content.userInfo)
                .isEqual(to: new.content.userInfo) &&
            ((old.content.sound == nil && new.content.sound == nil) ||
             (old.content.sound?.isEqual(new.content.sound) == true))
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
        for reminder: OneOffReminder,
        attachmentStore: ReviewNoteAttachmentRepository = ReviewNoteAttachmentRepository()
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        // An imported transcript can be the full reminder title in the UI,
        // but it must NEVER appear on a locked screen or notification.
        // Fail closed: restoring an older backup or a damaged attachment file
        // must never publish a truncated private transcript on the lock screen.
        // All imported one-offs use this reserved title prefix.
        // Titles already saved under Russian/English/Spanish must remain
        // protected even when the user changes their chosen UI language or
        // the attachment file is missing during backup/restore.
        let protectedPrefixes = ["ru", "en", "es"].map {
            L10n.string("review.note.prefix", language: $0)
        }
        let isImported = protectedPrefixes.contains(where: {
            reminder.title.hasPrefix($0)
        }) || (try? attachmentStore.get(reminder.id)) != nil
        if isImported {
            content.title = L10n.string("review.notification.genericTitle")
        } else {
            content.title = reminder.title
        }
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
