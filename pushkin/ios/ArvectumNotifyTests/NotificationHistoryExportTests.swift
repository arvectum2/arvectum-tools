import XCTest
@testable import ArvectumNotify

@MainActor
final class NotificationHistoryExportTests: XCTestCase {
    private func item(
        source: String,
        title: String = "",
        message: String = "",
        duplicate: Bool = false
    ) -> NotificationHistoryItem {
        NotificationHistoryItem(CapturedNotification(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            sourceApp: source,
            titleText: title,
            subtitleText: "",
            bodyText: message,
            receivedAt: Date(timeIntervalSince1970: 0),
            duplicateCandidate: duplicate
        ))
    }

    func testCsvEscapesQuotesCommasNewlinesAndPreservesUnicode() {
        let record = item(
            source: "Почта, личная",
            title: "Написал \"привет\"",
            message: "Первая строка\nВторая, строка",
            duplicate: true
        )
        let csv = NotificationHistoryCSV.serialize([record])

        XCTAssertTrue(csv.hasPrefix("\u{FEFF}\"ID\",\"App\""))
        XCTAssertTrue(csv.contains("\"Почта, личная\""))
        XCTAssertTrue(csv.contains("\"Написал \"\"привет\"\"\""))
        XCTAssertTrue(csv.contains("\"Первая строка\nВторая, строка\""))
        XCTAssertTrue(csv.contains("\"1970-01-01T00:00:00.000Z\""))
        XCTAssertTrue(csv.contains("\"true\""))
        XCTAssertTrue(csv.hasSuffix("\r\n"))
    }

    func testCsvNeutralizesSpreadsheetFormulas() {
        let value = item(
            source: "=HYPERLINK(\"https://bad.example\")",
            title: " +SUM(1,1)",
            message: "@unknown"
        )
        let csv = NotificationHistoryCSV.serialize([value])

        XCTAssertTrue(csv.contains("\"'=HYPERLINK(\"\"https://bad.example\"\")\""))
        XCTAssertTrue(csv.contains("\"' +SUM(1,1)\""))
        XCTAssertTrue(csv.contains("\"'@unknown\""))
    }

    func testCsvExportIsReadOnlyAndDoesNotIncludeRawDiagnostics() {
        let model = CapturedNotification(
            sourceApp: "Messages",
            titleText: "Hello",
            subtitleText: "",
            bodyText: "Visible text",
            receivedAt: Date(timeIntervalSince1970: 0),
            rawMessageText: "UNEXPORTED_RAW_SECRET"
        )
        let snapshot = NotificationHistoryItem(model)
        let csv = NotificationHistoryCSV.serialize([snapshot])

        XCTAssertTrue(csv.contains("Visible text"))
        XCTAssertFalse(csv.contains("UNEXPORTED_RAW_SECRET"))
        XCTAssertEqual(snapshot.bodyText, "Visible text")
        XCTAssertEqual(model.bodyText, "Visible text")
        XCTAssertEqual(csv.components(separatedBy: "\r\n").count, 3)
    }
}
