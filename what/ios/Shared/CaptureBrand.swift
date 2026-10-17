import Foundation

/// User-facing identity is localized. This isolated P2a QA build intentionally
/// keeps its bundle identifiers and deep links separate from installed QA11.
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

/// Use one unambiguous URL for the isolated Watch QA app and complication.
/// The stable production and QA11 apps keep their existing URL schemes.
enum WatchCaptureRouting {
    static let scheme = "whatp2aqa"
    static let captureURL = URL(string: "\(scheme)://capture")!
}
