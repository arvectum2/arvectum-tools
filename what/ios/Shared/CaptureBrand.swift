import Foundation

/// Public voice-inbox identity stays unchanged across app upgrades; the
/// same Watch/phone URL scheme also routes new text and video notes.
enum CaptureBrand {
    /// The phone currently follows its RU/EN/ES transcription choice for
    /// the user-facing interface; other system languages fall back to EN.
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

    static var interfaceLocale: Locale {
        Locale(identifier: selectedTranscriptionLocale)
    }

    static var isRussian: Bool {
        selectedTranscriptionLocale == "ru-RU"
    }

    private static var selectedInterfaceLanguage: String {
        switch selectedTranscriptionLocale {
        case "ru-RU": return "ru"
        case "es-ES": return "es"
        default: return "en"
        }
    }

    private static let spanishBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "es", ofType: "lproj")
        else { return nil }
        return Bundle(path: path)
    }()

    static var name: String { isRussian ? "Ухват" : "UhWhat?" }

    static func text(
        _ russian: String, _ english: String, language: String? = nil
    ) -> String {
        let code = (language ?? selectedInterfaceLanguage).lowercased()
        if code.hasPrefix("ru") { return russian }
        if code.hasPrefix("es") {
            return spanishBundle?.localizedString(
                forKey: english, value: english, table: nil
            ) ?? english
        }
        return english
    }

    /// The older fixed "N notes" label fails for singular and Russian plurals.
    /// Count nouns follow the spoken/UI locale; full ICU plural templates
    /// can replace this compatibility method in a later language tier.
    /// Format complete sentences, not concatenated translated fragments.
    static func formatted(
        _ russian: String, _ english: String,
        language: String? = nil, _ values: CVarArg...
    ) -> String {
        let code = language ?? selectedInterfaceLanguage
        let locale = Locale(identifier:
            code.hasPrefix("ru") ? "ru_RU" :
            code.hasPrefix("es") ? "es_ES" : "en_US"
        )
        return String(
            format: text(russian, english, language: code),
            locale: locale,
            arguments: values
        )
    }

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
        if language.hasPrefix("es") {
            return "\(count) \(count == 1 ? "nota" : "notas")"
        }
        return "\(count) \(count == 1 ? "note" : "notes")"
    }

    static func noteCount(_ count: Int) -> String {
        noteCount(count, language: selectedInterfaceLanguage)
    }
}

/// Use one stable URL for the production Watch app and its complication.
enum WatchCaptureRouting {
    static let scheme = "what"
    static let captureURL = URL(string: "\(scheme)://capture")!
}
