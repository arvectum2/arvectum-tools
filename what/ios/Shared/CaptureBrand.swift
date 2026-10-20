import Foundation

/// Public voice-inbox identity stays unchanged across app upgrades; the
/// same Watch/phone URL scheme also routes new text and video notes.
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
        return defaultTranscriptionLocale(
            for: Locale.current.language.languageCode?.identifier
        )
    }

    /// Never default to Russian when the system language is unsupported.
    /// A transcription language picker is separate from future UI translations.
    static func defaultTranscriptionLocale(for language: String?) -> String {
        switch language {
        case "ru": return "ru-RU"
        case "es": return "es-ES"
        default: return "en-US"
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

    /// The older fixed "N notes" label fails for singular and Russian plurals.
    /// Add locale-specific plurals as .stringsdict resources with the next
    /// language-pack implementation; do not claim any new locale here.
    static func noteCount(_ count: Int, language: String) -> String {
        if language == "ru" {
            let lastTwo = count % 100
            let lastDigit = count % 10
            let form: String
            if (11...14).contains(lastTwo) {
                form = "заметок"
            } else if lastDigit == 1 {
                form = "заметка"
            } else if (2...4).contains(lastDigit) {
                form = "заметки"
            } else {
                form = "заметок"
            }
            return "\(count) \(form)"
        }
        return "\(count) \(count == 1 ? "note" : "notes")"
    }

    static func noteCount(_ count: Int) -> String {
        noteCount(count, language: isRussian ? "ru" : "en")
    }
}

/// Use one stable URL for the production Watch app and its complication.
enum WatchCaptureRouting {
    static let scheme = "what"
    static let captureURL = URL(string: "\(scheme)://capture")!
}
