import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale.current,
            arguments: arguments
        )
    }

    static func streak(_ count: Int) -> String {
        if count == 1 {
            return string("habit.streak.one")
        }
        return format("habit.streak.format", count)
    }
}
