import Foundation
import SwiftUI

/// iOS app releases are compared by dotted numeric marketing versions, never
/// lexicographically or by build number.
public enum AppStoreVersionOrder {
    public static func isNewer(_ published: String, than installed: String) -> Bool {
        guard let publishedParts = parts(published), let installedParts = parts(installed) else {
            return false
        }
        for index in 0..<max(publishedParts.count, installedParts.count) {
            let lhs = index < publishedParts.count ? publishedParts[index] : 0
            let rhs = index < installedParts.count ? installedParts[index] : 0
            if lhs != rhs { return lhs > rhs }
        }
        return false
    }

    private static func parts(_ version: String) -> [Int]? {
        let segments = version.split(separator: ".", omittingEmptySubsequences: false)
        guard !segments.isEmpty, segments.count <= 4 else { return nil }
        let values = segments.compactMap { part -> Int? in
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }) else {
                return nil
            }
            return Int(part)
        }
        return values.count == segments.count ? values : nil
    }
}

public struct AppStorePublishedUpdate: Equatable {
    public let version: String
    public let storeURL: URL
}

/// Only Apple's public, unauthenticated Lookup API is queried. Failure (including
/// offline, timeout, or a missing storefront listing) never blocks the app.
public enum AppStoreUpdateLookup {
    private struct Response: Decodable {
        let results: [Entry]
    }

    private struct Entry: Decodable {
        let bundleId: String
        let version: String
        let trackViewUrl: URL
    }

    /// Kept separate from networking for deterministic unit tests.
    static func candidate(
        from data: Data,
        bundleID: String,
        installedVersion: String
    ) -> AppStorePublishedUpdate? {
        guard let response = try? JSONDecoder().decode(Response.self, from: data),
              let match = response.results.first(where: { $0.bundleId == bundleID }),
              AppStoreVersionOrder.isNewer(match.version, than: installedVersion),
              match.trackViewUrl.scheme == "https",
              match.trackViewUrl.host?.lowercased() == "apps.apple.com" else {
            return nil
        }
        return AppStorePublishedUpdate(version: match.version, storeURL: match.trackViewUrl)
    }

    public static func check(
        bundleID: String,
        installedVersion: String,
        country: String,
        session: URLSession = .shared
    ) async -> AppStorePublishedUpdate? {
        guard !bundleID.isEmpty, !installedVersion.isEmpty else { return nil }
        // A missing listing for one storefront must not hide a valid app. RU
        // is a fallback for the portfolio's established App Store storefront.
        let countries = Array(NSOrderedSet(array: [country.lowercased(), "ru"])) as? [String] ?? ["ru"]
        for currentCountry in countries {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "itunes.apple.com"
            components.path = "/lookup"
            components.queryItems = [
                URLQueryItem(name: "bundleId", value: bundleID),
                URLQueryItem(name: "country", value: currentCountry)
            ]
            guard let url = components.url else { return nil }
            var request = URLRequest(url: url)
            request.timeoutInterval = 7
            request.cachePolicy = .reloadIgnoringLocalCacheData
            do {
                let (data, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    return nil
                }
                if let release = candidate(
                    from: data, bundleID: bundleID, installedVersion: installedVersion
                ) {
                    return release
                }
                // Only retry a missing listing, not an equal/older published version.
                if let decoded = try? JSONDecoder().decode(Response.self, from: data),
                   decoded.results.contains(where: { $0.bundleId == bundleID }) {
                    return nil
                }
            } catch {
                return nil
            }
        }
        return nil
    }
}

private struct AppStoreUpdateCopy {
    let title: String
    let update: String
    let later: String
    let message: (String) -> String

    static func forLocale(_ locale: Locale) -> Self {
        switch locale.language.languageCode?.identifier.lowercased() {
        case "ru":
            return Self(
                title: "Доступно обновление", update: "Обновить", later: "Позже",
                message: { "В App Store доступна версия \($0). Установить обновление?" }
            )
        case "es":
            return Self(
                title: "Actualización disponible", update: "Actualizar", later: "Más tarde",
                message: { "La versión \($0) está disponible en App Store. ¿Actualizar?" }
            )
        default:
            return Self(
                title: "Update available", update: "Update", later: "Later",
                message: { "Version \($0) is available on the App Store. Update now?" }
            )
        }
    }
}

private struct AppStoreUpdatePromptModifier: ViewModifier {
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var environmentLocale
    @State private var didCheck = false
    @State private var release: AppStorePublishedUpdate?
    @State private var showingAlert = false

    let enabled: Bool
    let preferredLocale: Locale?

    func body(content: Content) -> some View {
        let copy = AppStoreUpdateCopy.forLocale(preferredLocale ?? environmentLocale)
        content
            .task(id: enabled) {
                guard enabled, !didCheck else { return }
                let args = ProcessInfo.processInfo.arguments
#if DEBUG
                // Deterministic UI automation, compiled out of App Store builds.
                // A synthetic release is shown only when *both* QA flags are present.
                if args.contains("--ui-testing") && args.contains("--qa-appstore-update"),
                   let fixtureURL = URL(string: "https://apps.apple.com/ru/app/id000000000") {
                    didCheck = true
                    release = AppStorePublishedUpdate(
                        version: "99.9.9",
                        storeURL: fixtureURL
                    )
                    showingAlert = true
                    return
                }
#endif
                guard !args.contains("--ui-testing") else { return }
                didCheck = true
                guard let bundleID = Bundle.main.bundleIdentifier,
                      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                else { return }

                let country = (preferredLocale ?? Locale.current).region?.identifier ?? "ru"
                let result = await AppStoreUpdateLookup.check(
                    bundleID: bundleID, installedVersion: version, country: country
                )
                guard !Task.isCancelled, let result else { return }
                release = result
                showingAlert = true
            }
            .alert(copy.title, isPresented: $showingAlert) {
                Button(copy.later, role: .cancel) { showingAlert = false }
                Button(copy.update) {
                    if let release { openURL(release.storeURL) }
                    showingAlert = false
                }
            } message: {
                if let release { Text(copy.message(release.version)) }
            }
    }
}

public extension View {
    /// Check once per application launch / root-view lifetime, without delaying
    /// startup or blocking functionality. "Later" simply dismisses the prompt.
    func appStoreUpdatePrompt(
        enabled: Bool = true,
        locale: Locale? = nil
    ) -> some View {
        modifier(AppStoreUpdatePromptModifier(enabled: enabled, preferredLocale: locale))
    }
}
