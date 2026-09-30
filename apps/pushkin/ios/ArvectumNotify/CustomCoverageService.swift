import Foundation

struct AppStoreCoverageResult: Decodable, Identifiable, Hashable {
    let trackId: Int
    let trackName: String
    let bundleId: String
    let sellerName: String?

    var id: String { bundleId }
}

private struct AppStoreSearchResponse: Decodable {
    let results: [AppStoreCoverageResult]
}

enum CustomCoverageError: LocalizedError {
    case invalidResponse
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "PUSHKIN could not prepare coverage for this app."
        case .serviceUnavailable:
            return "Custom app coverage is temporarily unavailable."
        }
    }
}


enum CustomCoverageService {
    static func searchAppStore(
        term: String,
        countryCodes: [String]? = nil
    ) async throws -> [AppStoreCoverageResult] {
        let localCountry = Locale.current.region?.identifier.lowercased()
        let requested = countryCodes ?? [
            localCountry,
            "us",
            "gb"
        ].compactMap { $0 }

        var countries: [String] = []
        for country in requested where !countries.contains(country) {
            countries.append(country)
        }

        var merged: [AppStoreCoverageResult] = []
        var seen = Set<String>()
        var lastError: Error?

        for country in countries {
            do {
                let results = try await searchAppStore(
                    term: term,
                    country: country
                )
                for result in results where seen.insert(result.bundleId).inserted {
                    merged.append(result)
                }
            } catch {
                lastError = error
            }
        }

        if merged.isEmpty, let lastError {
            throw lastError
        }
        return merged
    }

    private static func searchAppStore(
        term: String,
        country: String
    ) async throws -> [AppStoreCoverageResult] {
        var components = URLComponents(
            string: "https://itunes.apple.com/search"
        )!
        components.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "country", value: country)
        ]

        let (data, response) = try await URLSession.shared.data(
            from: components.url!
        )
        try validate(response)
        return try JSONDecoder().decode(
            AppStoreSearchResponse.self,
            from: data
        ).results
    }

    static func signedPackage(
        for app: AppStoreCoverageResult
    ) async throws -> URL {
        guard let baseURL = signerBaseURL else {
            throw CustomCoverageError.serviceUnavailable
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/coverage/shortcut"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "bundleIdentifier", value: app.bundleId),
            URLQueryItem(name: "name", value: app.trackName)
        ]

        let (data, response) = try await URLSession.shared.data(
            from: components.url!
        )
        try validate(response)
        guard data.count > 1024 else {
            throw CustomCoverageError.invalidResponse
        }

        let safeBundle = app.bundleId.replacingOccurrences(
            of: "/",
            with: "-"
        )
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PUSHKIN-Custom-\(safeBundle).shortcut"
            )
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw CustomCoverageError.invalidResponse
        }
    }


    static var signerBaseURL: URL? {
#if DEBUG
        if let override = ProcessInfo.processInfo.environment[
            "PUSHKIN_CUSTOM_COVERAGE_SERVICE_URL"
        ], let url = URL(string: override), url.scheme != nil {
            return url
        }
        return URL(string: "http://Mac-mini-master.local:8766")
#else
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "PUSHKINCustomCoverageServiceURL"
        ) as? String,
              let url = URL(string: value),
              url.scheme == "https",
              url.host != nil
        else {
            return nil
        }
        return url
#endif
    }
}
