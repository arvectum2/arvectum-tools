import Foundation

/// Changes to the Watch queue become visible in memory only after the
/// corresponding on-disk index is atomically committed. The original audio
/// files are never touched by these mutations.
enum WatchDurableQueue {
    static func enqueue(
        _ recording: RecordingEnvelope,
        into queue: inout [RecordingEnvelope],
        at indexURL: URL
    ) throws {
        var next = queue.filter { $0.id != recording.id }
        next.append(recording)
        try persist(next, to: indexURL)
        queue = next
    }

    /// Removes the index entry first; the caller can remove the original
    /// .m4a only after this function returns successfully.
    @discardableResult
    static func acknowledge(
        _ id: UUID,
        in queue: inout [RecordingEnvelope],
        at indexURL: URL
    ) throws -> RecordingEnvelope? {
        guard let entry = queue.first(where: { $0.id == id }) else {
            return nil
        }
        let next = queue.filter { $0.id != id }
        try persist(next, to: indexURL)
        queue = next
        return entry
    }

    static func recover(
        _ recordings: [RecordingEnvelope],
        into queue: inout [RecordingEnvelope],
        at indexURL: URL
    ) throws {
        let existing = Set(queue.map(\.id))
        let newlyRecovered = recordings.filter { !existing.contains($0.id) }
        guard !newlyRecovered.isEmpty else { return }
        let next = queue + newlyRecovered
        try persist(next, to: indexURL)
        queue = next
    }

    private static func persist(_ next: [RecordingEnvelope], to url: URL) throws {
        let encoded = try JSONEncoder().encode(next)
        try encoded.write(to: url, options: .atomic)
    }
}
