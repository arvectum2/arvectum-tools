import Foundation

/// Crash-safe proof that a specific UUID was acknowledged by iPhone *before*
/// Watch removes it from queue.json or deletes its original audio.
/// A short-lived marker prevents an orphan .m4a from being re-enqueued after
/// process death between queue commit and physical file cleanup.
enum WatchAcknowledgementJournal {
    private static let folderName = "Acknowledged"

    static func markerURL(for id: UUID, in outbound: URL) -> URL {
        outbound.appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent(id.uuidString + ".ack")
    }

    static func pendingIDs(in outbound: URL, fileManager: FileManager = .default) -> Set<UUID> {
        let folder = outbound.appendingPathComponent(folderName, isDirectory: true)
        guard let urls = try? fileManager.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return [] }
        return Set(urls.compactMap { url -> UUID? in
            guard url.pathExtension == "ack" else { return nil }
            return UUID(uuidString: url.deletingPathExtension().lastPathComponent)
        })
    }

    /// Returns true only when the matching queued recording was durably ACKed.
    /// If either the marker or queue commit fails, the original audio remains.
    @discardableResult
    static func acknowledge(
        _ id: UUID,
        in queue: inout [RecordingEnvelope],
        at indexURL: URL,
        outbound: URL,
        fileManager: FileManager = .default
    ) throws -> Bool {
        guard queue.contains(where: { $0.id == id }) else { return false }
        let marker = markerURL(for: id, in: outbound)
        try fileManager.createDirectory(
            at: marker.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("ack".utf8).write(to: marker, options: .atomic)
        // iPhone has already committed this UUID. Queue changes must be durable
        // before deleting the only Watch copy, regardless of callback ordering.
        _ = try WatchDurableQueue.acknowledge(id, in: &queue, at: indexURL)
        cleanup(id, marker: marker, outbound: outbound, fileManager: fileManager)
        return true
    }

    /// Call only after queue.json is readable. If its prior atomic write
    /// failed, this completes the ACK using the marker before orphan scanning.
    static func reconcile(
        queue: inout [RecordingEnvelope],
        at indexURL: URL,
        outbound: URL,
        fileManager: FileManager = .default
    ) throws {
        let ids = pendingIDs(in: outbound, fileManager: fileManager)
        for id in ids.sorted(by: { $0.uuidString < $1.uuidString }) {
            if queue.contains(where: { $0.id == id }) {
                _ = try WatchDurableQueue.acknowledge(id, in: &queue, at: indexURL)
            }
            cleanup(id, marker: markerURL(for: id, in: outbound),
                    outbound: outbound, fileManager: fileManager)
        }
    }

    private static func cleanup(
        _ id: UUID,
        marker: URL,
        outbound: URL,
        fileManager: FileManager
    ) {
        // Never accept a path from received metadata as a deletion target.
        let source = outbound.appendingPathComponent(id.uuidString + ".m4a")
        if fileManager.fileExists(atPath: source.path) {
            try? fileManager.removeItem(at: source)
        }
        // The marker is the final thing removed: if cleanup was interrupted,
        // the next launch can safely resume without resurrecting an orphan.
        if !fileManager.fileExists(atPath: source.path) {
            try? fileManager.removeItem(at: marker)
        }
    }
}
