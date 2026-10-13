import Foundation

/// The user-facing identity is localized; bundle identifiers and existing
/// what:// deep links stay unchanged so installed recordings and widgets survive.
enum CaptureBrand {
    static var isRussian: Bool {
        Locale.current.language.languageCode?.identifier == "ru"
    }

    static var name: String { isRussian ? "Ухват" : "UhWhat?" }

    static func text(_ russian: String, _ english: String) -> String {
        isRussian ? russian : english
    }
}
