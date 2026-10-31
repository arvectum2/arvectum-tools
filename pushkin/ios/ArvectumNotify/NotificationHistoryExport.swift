import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// An explicit, user-controlled plaintext export. Never called by background
/// automation and never uploads or logs notification content.
enum NotificationHistoryCSV {
    static func serialize(_ items: [NotificationHistoryItem]) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!

        let headers = [
            "ID", "App", "Title", "Subtitle", "Message",
            "ReceivedAtUTC", "PossibleDuplicate"
        ]
        let rows = items.map { item in
            [
                item.id.uuidString,
                item.sourceApp,
                item.titleText,
                item.subtitleText,
                item.bodyText,
                dateFormatter.string(from: item.receivedAt),
                item.duplicateCandidate ? "true" : "false"
            ]
        }

        // UTF-8 BOM helps spreadsheet applications recognize Cyrillic and
        // other scripts without a lossy system encoding.
        return "\u{FEFF}" + ([headers] + rows)
            .map { $0.map(escapedField).joined(separator: ",") }
            .joined(separator: "\r\n") + "\r\n"
    }

    private static func escapedField(_ text: String) -> String {
        // CSV is data, but spreadsheet apps interpret leading = + - @ as
        // formulas. Preserve the source text as a quoted literal.
        let leading = text.drop(while: { $0 == " " })
        let potentiallyExecutable = leading.first.map {
            "=+-@\t\r\n".contains($0)
        } ?? false
        let safeText = potentiallyExecutable ? "'" + text : text
        return "\"" + safeText.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

struct NotificationCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    private var csv: String

    init(items: [NotificationHistoryItem]) {
        csv = NotificationHistoryCSV.serialize(items)
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let content = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        csv = content
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(csv.utf8))
    }
}
