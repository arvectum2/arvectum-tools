import Foundation

/// The user-facing identity is localized; bundle identifiers and existing
/// what:// deep links stay unchanged so installed recordings and widgets survive.
enum CaptureBrand {
    /// The phone's app language follows its speech-recognition language so
    /// changing RU ↔ EN never leaves the menu and navigation in another locale.
    /// Watch and widget processes have separate UserDefaults stores; if there
    /// is no local choice, continue using their device locale.
    static let languagePreferenceKey = "what.transcription.locale"

    static var selectedTranscriptionLocale: String {
        if let stored = UserDefaults.standard.string(forKey: languagePreferenceKey),
           ["ru-RU", "en-US", "es-ES"].contains(stored) {
            return stored
        }
        switch Locale.current.language.languageCode?.identifier {
        case "en": return "en-US"
        case "es": return "es-ES"
        default: return "ru-RU"
        }
    }

    /// Spanish is supported by on-device Speech but the application does not
    /// yet have Spanish UI strings. Display English UI for that legacy choice
    /// and state that limitation explicitly in the picker.
    static var interfaceLocale: Locale {
        Locale(identifier: selectedTranscriptionLocale == "ru-RU" ? "ru-RU" : "en-US")
    }

    static var isRussian: Bool {
        selectedTranscriptionLocale == "ru-RU"
    }

    static var name: String { isRussian ? "Ухват" : "UhWhat?" }

    static func text(_ russian: String, _ english: String) -> String {
        isRussian ? russian : english
    }
}
