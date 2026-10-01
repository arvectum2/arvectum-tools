import Foundation

enum HabitDayBoundary {
    static func next(
        after date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(
            byAdding: .day,
            value: 1,
            to: start
        ) ?? date.addingTimeInterval(86_400)
    }

    static func delay(
        from date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> TimeInterval {
        max(next(after: date, calendar: calendar).timeIntervalSince(date), 1)
    }
}
