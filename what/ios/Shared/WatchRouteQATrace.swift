#if WATCH_ROUTE_QA
import Foundation

/// Isolated QA-only transport breadcrumbs on the physical devices.
/// Never captures audio, messageData, private transcripts or recording content.
/// This is not compiled into the production iOS/watchOS project.
enum WatchRouteQATrace {
    struct Event: Codable {
        let time: TimeInterval
        let uptime: TimeInterval
        let kind: String
        let id: String?
        let note: String
    }

    private static let lock = NSLock()
    private static let url: URL = {
        let folder = FileManager.default.urls(for: .documentDirectory,
            in: .userDomainMask)[0].appendingPathComponent("WatchRouteQA",
                isDirectory: true)
        try? FileManager.default.createDirectory(
            at: folder, withIntermediateDirectories: true
        )
        return folder.appendingPathComponent("events.json")
    }()

    static func add(_ kind: String, id: UUID? = nil, note: String = "") {
        lock.lock()
        defer { lock.unlock() }
        let event = Event(time: Date().timeIntervalSince1970,
                          uptime: ProcessInfo.processInfo.systemUptime,
                          kind: kind, id: id?.uuidString, note: note)
        let existing = (try? Data(contentsOf: url)).flatMap {
            try? JSONDecoder().decode([Event].self, from: $0)
        } ?? []
        let updated = Array((existing + [event]).suffix(350))
        guard let data = try? JSONEncoder().encode(updated) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
#endif
