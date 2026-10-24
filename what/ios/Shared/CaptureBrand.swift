import Foundation

/// Public voice-inbox identity stays unchanged across app upgrades; the
/// same Watch/phone URL scheme also routes new text and video notes.
enum CaptureBrand {
    /// Speech recognition is a separate setting from the visual interface.
    /// Interface follows iOS per-app/device language in RU/EN/ES/FR/DE/PT-BR/IT; unsupported
    /// interface languages have an English fallback. Watch and widget process
    /// locales are resolved independently. Existing recording language
    /// preferences and original audio remain untouched.
    static let languagePreferenceKey = "what.transcription.locale"

    static var selectedTranscriptionLocale: String {
        if let stored = UserDefaults.standard.string(forKey: languagePreferenceKey),
           ["ru-RU", "en-US", "es-ES", "fr-FR"].contains(stored) {
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
        case "fr": return "fr-FR"
        default: return "en-US"
        }
    }

    /// iOS per-app language choice takes precedence over the system language.
    /// Do not couple the visible language to SFSpeechRecognizer locale.
    static func resolvedInterfaceLanguage(for preferredLanguages: [String]) -> String {
        for identifier in preferredLanguages {
            let language = Locale(identifier: identifier)
                .language.languageCode?.identifier.lowercased()
            if let language, ["ru", "en", "es", "fr", "de", "pt", "it", "ja"].contains(language) {
                return language
            }
        }
        return "en"
    }

    static var interfaceLocale: Locale {
        Locale(identifier: selectedInterfaceLanguage)
    }

    static var isRussian: Bool {
        selectedInterfaceLanguage == "ru"
    }

    private static var selectedInterfaceLanguage: String {
        resolvedInterfaceLanguage(for: Locale.preferredLanguages)
    }

    private static let spanishBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "es", ofType: "lproj")
        else { return nil }
        return Bundle(path: path)
    }()

    private static let frenchBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "fr", ofType: "lproj")
        else { return nil }
        return Bundle(path: path)
    }()

    private static let germanBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "de", ofType: "lproj")
        else { return nil }
        return Bundle(path: path)
    }()

    private static let brazilianPortugueseBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "pt-BR", ofType: "lproj")
        else { return nil }
        return Bundle(path: path)
    }()

    private static let italianBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "it", ofType: "lproj")
        else { return nil }
        return Bundle(path: path)
    }()

    private static let japaneseBundle: Bundle? = {
        guard let path = Bundle.main.path(forResource: "ja", ofType: "lproj")
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
        if code.hasPrefix("fr") {
            return frenchBundle?.localizedString(
                forKey: english, value: english, table: nil
            ) ?? english
        }
        if code.hasPrefix("de") {
            return germanBundle?.localizedString(
                forKey: english, value: english, table: nil
            ) ?? english
        }
        if code.hasPrefix("pt") {
            return brazilianPortugueseBundle?.localizedString(
                forKey: english, value: english, table: nil
            ) ?? english
        }
        if code.hasPrefix("it") {
            return italianBundle?.localizedString(
                forKey: english, value: english, table: nil
            ) ?? english
        }
        if code.hasPrefix("ja") {
            return japaneseBundle?.localizedString(
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
            code.hasPrefix("es") ? "es_ES" :
            code.hasPrefix("fr") ? "fr_FR" :
            code.hasPrefix("de") ? "de_DE" :
            code.hasPrefix("pt") ? "pt_BR" :
            code.hasPrefix("it") ? "it_IT" :
            code.hasPrefix("ja") ? "ja_JP" : "en_US"
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
        if language.hasPrefix("fr") {
            return "\(count) \(count == 1 ? "note" : "notes")"
        }
        if language.hasPrefix("de") {
            return "\(count) \(count == 1 ? "Notiz" : "Notizen")"
        }
        if language.hasPrefix("pt") {
            return "\(count) \(count == 1 ? "nota" : "notas")"
        }
        if language.hasPrefix("it") {
            return "\(count) \(count == 1 ? "nota" : "note")"
        }
        if language.hasPrefix("ja") {
            return "\(count)件のメモ"
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
