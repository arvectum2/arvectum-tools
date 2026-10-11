import XCTest
@testable import HabitsByArvectum

final class HabitDeepLinkTests: XCTestCase {
    func testHabitURLRoundTrips() {
        let id = UUID()
        let url = HabitDeepLink.habitURL(id)

        XCTAssertEqual(
            HabitDeepLink.destination(from: url),
            .habit(id)
        )
    }

    func testTodayURLParses() {
        XCTAssertEqual(
            HabitDeepLink.destination(from: HabitDeepLink.todayURL),
            .today
        )
    }

    func testForeignAndMalformedURLsAreRejected() {
        XCTAssertNil(
            HabitDeepLink.destination(
                from: URL(string: "https://example.com/habit")!
            )
        )
        XCTAssertNil(
            HabitDeepLink.destination(
                from: URL(string: "habits-arvectum://habit/not-a-uuid")!
            )
        )
        XCTAssertNil(
            HabitDeepLink.destination(
                from: URL(string: "habits-arvectum://unknown")!
            )
        )
    }
}
