import Foundation
import XCTest
@testable import ArvectumCore

final class AppStoreUpdateTests: XCTestCase {
    func testNumericComparison() {
        XCTAssertTrue(AppStoreVersionOrder.isNewer("1.10.0", than: "1.9.9"))
        XCTAssertTrue(AppStoreVersionOrder.isNewer("1.0.1", than: "1.0"))
        XCTAssertFalse(AppStoreVersionOrder.isNewer("1.0", than: "1.0.0"))
        XCTAssertFalse(AppStoreVersionOrder.isNewer("1.2", than: "1.3"))
        XCTAssertFalse(AppStoreVersionOrder.isNewer("1.bad", than: "1.2"))
        XCTAssertFalse(AppStoreVersionOrder.isNewer("1..3", than: "1.2"))
        XCTAssertFalse(AppStoreVersionOrder.isNewer("1.2", than: ""))
        XCTAssertFalse(AppStoreVersionOrder.isNewer("999999999999999999999", than: "1"))
    }

    private func fixture(
        bundleID: String = "ru.arvectum.tools.habits",
        version: String = "1.6.0",
        url: String = "https://apps.apple.com/ru/app/chickmark/id12345"
    ) -> Data {
        let json: [String: Any] = ["results": [[
            "bundleId": bundleID, "version": version, "trackViewUrl": url
        ]]]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    func testNewVersionHasValidStoreURL() {
        let release = AppStoreUpdateLookup.candidate(
            from: fixture(), bundleID: "ru.arvectum.tools.habits", installedVersion: "1.5.0"
        )
        XCTAssertEqual(release?.version, "1.6.0")
        XCTAssertEqual(release?.storeURL.host, "apps.apple.com")
    }

    func testNoPromptForSameOrOlderVersion() {
        for version in ["1.5.0", "1.4.9"] {
            XCTAssertNil(AppStoreUpdateLookup.candidate(
                from: fixture(version: version),
                bundleID: "ru.arvectum.tools.habits",
                installedVersion: "1.5.0"
            ))
        }
    }

    func testLookupRequestsCurrentRegionAndFallsBackOnlyForMissingListing() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LookupStubURLProtocol.self]
        let session = URLSession(configuration: config)
        defer {
            session.invalidateAndCancel()
            LookupStubURLProtocol.handler = nil
        }

        var countries: [String] = []
        LookupStubURLProtocol.handler = { request in
            let country = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "country" })?.value ?? ""
            countries.append(country)
            let data = country == "gb"
                ? Data(#"{"results":[]}"#.utf8)
                : self.fixture()
            return (200, data)
        }
        let result = await AppStoreUpdateLookup.check(
            bundleID: "ru.arvectum.tools.habits",
            installedVersion: "1.5.0",
            country: "GB",
            session: session
        )
        XCTAssertEqual(result?.version, "1.6.0")
        XCTAssertEqual(countries, ["gb", "ru"])
    }

    func testLookupServerErrorSkipsWithoutPrompt() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LookupStubURLProtocol.self]
        let session = URLSession(configuration: config)
        defer {
            session.invalidateAndCancel()
            LookupStubURLProtocol.handler = nil
        }
        LookupStubURLProtocol.handler = { _ in (503, Data()) }
        let result = await AppStoreUpdateLookup.check(
            bundleID: "ru.arvectum.tools.habits",
            installedVersion: "1.5.0",
            country: "ru",
            session: session
        )
        XCTAssertNil(result)
    }

    func testRejectsWrongBundleAndNonAppleLinks() {
        XCTAssertNil(AppStoreUpdateLookup.candidate(
            from: fixture(bundleID: "com.someother.app"),
            bundleID: "ru.arvectum.tools.habits", installedVersion: "1.5.0"
        ))
        for url in ["https://example.com/redirect", "http://apps.apple.com/app/id123"] {
            XCTAssertNil(AppStoreUpdateLookup.candidate(
                from: fixture(url: url),
                bundleID: "ru.arvectum.tools.habits", installedVersion: "1.5.0"
            ))
        }
        XCTAssertNil(AppStoreUpdateLookup.candidate(
            from: Data("not JSON".utf8),
            bundleID: "ru.arvectum.tools.habits", installedVersion: "1.5.0"
        ))
    }
}


private final class LookupStubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler,
              let url = request.url,
              let client else { return }
        let (status, data) = handler(request)
        guard let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil
        ) else { return }
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: data)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
