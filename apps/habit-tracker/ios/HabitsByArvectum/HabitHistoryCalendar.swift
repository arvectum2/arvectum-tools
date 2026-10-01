import Foundation

enum HabitHistoryCalendar {
    static func visibleDays(
        endingInWeekContaining date: Date,
        weeks: Int = 6,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Date] {
        guard weeks > 0 else { return [] }

        let today = calendar.startOfDay(for: date)
        let currentWeekStart =
            calendar.dateInterval(of: .weekOfYear, for: today)?.start
            ?? today
        let start = calendar.date(
            byAdding: .weekOfYear,
            value: -(weeks - 1),
            to: currentWeekStart
        ) ?? currentWeekStart

        return (0..<(weeks * 7)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
    }

    static func weekdaySymbols(
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar

        let symbols = formatter.veryShortStandaloneWeekdaySymbols
            ?? formatter.veryShortWeekdaySymbols
            ?? ["S", "M", "T", "W", "T", "F", "S"]

        guard symbols.count == 7 else { return symbols }

        let first = max(1, min(calendar.firstWeekday, 7)) - 1
        return Array(symbols[first...]) + Array(symbols[..<first])
    }
}
