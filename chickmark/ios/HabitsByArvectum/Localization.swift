import Foundation

/// The in-app language preference is local to the device, not CloudKit.
/// "system" preserves Apple's normal per-app/system localization behavior.
enum ChickMarkLanguage {
    static let storageKey = "chickmark.language.preference"
    static let system = "system"
    static let supported = ["ru", "en", "es"]

    static var selected: String {
        UserDefaults.standard.string(forKey: storageKey) ?? system
    }

    static func effectiveIdentifier(for selection: String) -> String {
        if supported.contains(selection) { return selection }
        return Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "en"
    }

    static func displayName(for selection: String) -> String {
        switch selection {
        case "ru": return "Русский"
        case "en": return "English"
        case "es": return "Español"
        default: return L10n.string("language.system")
        }
    }
}

enum L10n {
    static func string(_ key: String) -> String {
        string(key, language: ChickMarkLanguage.selected)
    }

    /// Explicit language parameter makes localization behavior testable without
    /// changing global UserDefaults or the device's preferred languages.
    static func string(_ key: String, language: String) -> String {
        guard ChickMarkLanguage.supported.contains(language),
              let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, comment: "")
        }
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        return value == key ? NSLocalizedString(key, comment: "") : value
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let selected = ChickMarkLanguage.selected
        let locale = ChickMarkLanguage.supported.contains(selected)
            ? Locale(identifier: selected)
            : Locale.current
        return String(
            format: string(key),
            locale: locale,
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
