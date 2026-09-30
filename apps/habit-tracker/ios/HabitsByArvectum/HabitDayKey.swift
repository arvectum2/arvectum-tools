import Foundation

enum HabitDayKey {
    static func make(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func matches(
        _ checkIn: HabitCheckIn,
        on date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        let targetKey = make(for: date, calendar: calendar)

        if let storedKey = checkIn.dayKey {
            return storedKey == targetKey
        }

        return calendar.isDate(checkIn.day, inSameDayAs: date)
    }
}
