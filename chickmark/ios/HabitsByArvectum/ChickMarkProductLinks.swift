import Foundation

/// Public product pages published by arvectum-site.
enum ChickMarkProductLinks {
    static func landingPage(for languageIdentifier: String) -> URL {
        let language = languageIdentifier
            .split(separator: "-")
            .first?
            .lowercased() ?? "en"
        let path: String
        switch language {
        case "ru":
            path = "/tools/chickmark/index.html"
        case "es":
            path = "/tools/chickmark/es/index.html"
        default:
            path = "/tools/chickmark/en/index.html"
        }
        return URL(string: "https://arvectum.com" + path)!
    }

    static var localizedLandingPage: URL {
        landingPage(
            for: ChickMarkLanguage.effectiveIdentifier(
                for: ChickMarkLanguage.selected
            )
        )
    }
}
