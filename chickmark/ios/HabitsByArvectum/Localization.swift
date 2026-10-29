import Foundation

/// The in-app language preference is local to the device, not CloudKit.
/// "system" preserves Apple's normal per-app/system localization behavior.
enum ChickMarkLanguage {
    static let storageKey = "chickmark.language.preference"
    static let system = "system"

    /// Only localizations actually packaged in the current app bundle are
    /// selectable. A 50-locale product registry does not mean 50 translated
    /// catalogues; never show a language with no usable local strings.
    static let supported: [String] = {
        func bundledKeys(for code: String) -> Set<String>? {
            guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
                  let bundle = Bundle(path: path),
                  let file = bundle.url(forResource: "Localizable", withExtension: "strings"),
                  let data = try? Data(contentsOf: file),
                  let catalog = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil
                  ) as? [String: String],
                  !catalog.isEmpty
            else { return nil }
            return Set(catalog.keys)
        }

        // A partial .lproj is not a selectable translation. It must include
        // every key in the English source (not just one menu label). The repo
        // QA gate validates the same key and placeholder parity at build time.
        guard let sourceKeys = bundledKeys(for: "en") else {
            return ["en"]
        }
        return orderedLanguages(Bundle.main.localizations.filter {
            $0 != "Base" && bundledKeys(for: $0) == sourceKeys
        })
    }()

    /// Keep the existing user-facing order for RU/EN/ES; future fully
    /// bundled locales appear automatically after them, alphabetically.
    static func orderedLanguages(_ available: [String]) -> [String] {
        let discovered = Set(available.filter { !$0.isEmpty && $0 != "Base" })
        let pinned = ["ru", "en", "es"].filter { discovered.contains($0) }
        return pinned + discovered.subtracting(pinned).sorted()
    }

    static var selected: String {
        let preference = UserDefaults.standard.string(forKey: storageKey) ?? system
        return preference == system || supported.contains(preference)
            ? preference : system
    }

    /// Separate pure resolver enables tests for devices whose first language
    /// is not shipped (e.g. Japanese, French or Hindi). This must select the
    /// bundled English fallback rather than an untranslated system locale.
    static func resolvedIdentifier(
        for selection: String,
        preferred: [String],
        available: [String]
    ) -> String {
        if available.contains(selection) { return selection }
        for preference in preferred {
            let code = preference
                .split(whereSeparator: { $0 == "-" || $0 == "_" })
                .first.map(String.init)?.lowercased() ?? ""
            let normalized = preference.lowercased().replacingOccurrences(of: "_", with: "-")
            if code == "zh" {
                let traditional = normalized.hasPrefix("zh-hant") ||
                    normalized.hasPrefix("zh-tw") || normalized.hasPrefix("zh-hk") ||
                    normalized.hasPrefix("zh-mo")
                if traditional && available.contains("zh-Hant") { return "zh-Hant" }
                if !traditional && available.contains("zh-Hans") { return "zh-Hans" }
                continue
            }
            if available.contains(code) { return code }
            // Locale identifiers can be regional (pt-BR). Keep fully
            // translated regional catalogues selectable under system locale.
            if let regional = available.first(where: {
                $0.lowercased() == preference.replacingOccurrences(
                    of: "_", with: "-").lowercased()
            }) {
                return regional
            }
            if let firstRegion = available.first(where: {
                $0.lowercased().hasPrefix(code + "-")
            }) {
                return firstRegion
            }
        }
        if available.contains("en") { return "en" }
        return available.first ?? "en"
    }

    static func effectiveIdentifier(for selection: String) -> String {
        resolvedIdentifier(
            for: selection,
            preferred: Bundle.main.preferredLocalizations + Locale.preferredLanguages,
            available: supported
        )
    }

    static func displayName(for selection: String) -> String {
        switch selection {
        case "ru": return "Русский"
        case "en": return "English"
        case "es": return "Español"
        case "pt-BR": return "Português (Brasil)"
        case "pt-PT": return "Português (Portugal)"
        case "it": return "Italiano"
        case "ja": return "日本語"
        case "ko": return "한국어"
        case "tr": return "Türkçe"
        case "zh-Hans": return "简体中文"
        case "zh-Hant": return "繁體中文"
        case system: return L10n.string("language.system")
        default:
            // Autonym, rather than displaying the language name in the
            // device's current language, as the catalog list grows.
            return Locale(identifier: selection)
                .localizedString(forLanguageCode: selection)
                ?? selection
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
