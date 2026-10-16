import AVFoundation
import Foundation

/// A crash-safe local capture journal. Each session owns its own folder and a
/// stable UUID used by LocalNoteRepository to prevent duplicate recovery.
/// No operation touches Watch audio files, the audio index or user transcripts.
final class VideoCaptureJournal {
    // Process-local exclusion: launch recovery must never pick up a movie
    // which AVFoundation is currently writing in the *same* app process.
    private static let activeLock = NSLock()
    private nonisolated(unsafe) static var activeCaptures = Set<UUID>()

    static func setActive(_ id: UUID, active: Bool) {
        activeLock.lock()
        defer { activeLock.unlock() }
        if active {
            activeCaptures.insert(id)
        } else {
            activeCaptures.remove(id)
        }
    }

    private static func isActive(_ id: UUID) -> Bool {
        activeLock.lock()
        defer { activeLock.unlock() }
        return activeCaptures.contains(id)
    }

    struct Manifest: Codable {
        enum State: String, Codable { case recording, discarded }
        let id: UUID
        let startedAt: Date
        var state: State
    }

    struct Pending: Identifiable {
        let id: UUID
        let folder: URL
        let segments: [URL]
    }

    private let files: FileManager
    private let captures: URL

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.files = fileManager
        if let rootURL {
            captures = rootURL
        } else {
            let support = fileManager.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            captures = support.appendingPathComponent(
                "What/VideoCaptures", isDirectory: true
            )
        }
    }

    func begin(id: UUID = UUID()) throws -> UUID {
        let folder = sessionFolder(id)
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        let manifest = Manifest(id: id, startedAt: Date(), state: .recording)
        try persist(manifest)
        return id
    }

    func segmentURL(for id: UUID, index: Int) -> URL {
        sessionFolder(id).appendingPathComponent(
            String(format: "segment-%06d.mov", index)
        )
    }

    func mergedURL(for id: UUID) -> URL {
        sessionFolder(id).appendingPathComponent("combined.mov")
    }

    func markDiscarded(_ id: UUID) throws {
        guard let manifest = try readManifest(id) else { return }
        try persist(Manifest(id: manifest.id, startedAt: manifest.startedAt,
                             state: .discarded))
    }

    /// Never invoked before LocalNoteRepository durably persists the note.
    func removeSavedSession(_ id: UUID) throws {
        let folder = sessionFolder(id)
        if files.fileExists(atPath: folder.path) {
            try files.removeItem(at: folder)
        }
    }

    func pendingSessions() throws -> [Pending] {
        guard files.fileExists(atPath: captures.path) else { return [] }
        return try files.contentsOfDirectory(
            at: captures, includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ).compactMap { folder in
            guard (try? folder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  let id = UUID(uuidString: folder.lastPathComponent),
                  !Self.isActive(id),
                  let manifest = try readManifest(id),
                  manifest.id == id,
                  manifest.state == .recording else { return nil }
            let children = try files.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            // Never confuse an unfinished export with a camera clip.
            let clips = children.filter {
                $0.lastPathComponent.hasPrefix("segment-") &&
                $0.pathExtension.lowercased() == "mov"
            }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            guard !clips.isEmpty else { return nil }
            return Pending(id: id, folder: folder, segments: clips)
        }.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private func sessionFolder(_ id: UUID) -> URL {
        captures.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func manifestURL(_ id: UUID) -> URL {
        sessionFolder(id).appendingPathComponent("session.json")
    }

    private func readManifest(_ id: UUID) throws -> Manifest? {
        let url = manifestURL(id)
        guard files.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
    }

    private func persist(_ manifest: Manifest) throws {
        try files.createDirectory(
            at: sessionFolder(manifest.id), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(manifest).write(
            to: manifestURL(manifest.id), options: .atomic
        )
    }
}

/// Called after launch, before any new camera recording, while no capture is
/// active. Valid finished segments are imported automatically; failed/partial
/// files remain untouched so the user can retry after a later launch.
enum VideoCaptureRecovery {
    struct Result {
        let recovered: Int
        let unresolved: Int
    }

    static func recover(
        journal: VideoCaptureJournal,
        repository: LocalNoteRepository
    ) async throws -> Result {
        let pending = try journal.pendingSessions()
        var recovered = 0
        var unresolved = 0

        for session in pending {
            // Crash after durable repository commit but before source cleanup:
            // never add a second note for the same capture UUID.
            if try repository.hasVideo(id: session.id) {
                // On a previous partial salvage, do not delete corrupt clips.
                var allReadable = true
                for clip in session.segments {
                    let asset = AVURLAsset(url: clip)
                    guard let duration = try? await asset.load(.duration),
                          duration.isNumeric, duration.seconds.isFinite,
                          duration.seconds > 0,
                          let tracks = try? await asset.loadTracks(withMediaType: .video),
                          !tracks.isEmpty else {
                        allReadable = false
                        break
                    }
                }
                if allReadable {
                    try? journal.removeSavedSession(session.id)
                } else {
                    unresolved += 1
                }
                continue
            }

            var valid: [URL] = []
            for clip in session.segments {
                let asset = AVURLAsset(url: clip)
                guard let duration = try? await asset.load(.duration),
                      duration.isNumeric, duration.seconds.isFinite,
                      duration.seconds > 0,
                      let tracks = try? await asset.loadTracks(withMediaType: .video),
                      !tracks.isEmpty else {
                    continue
                }
                valid.append(clip)
            }

            guard !valid.isEmpty else {
                unresolved += 1
                continue
            }

            let merged = journal.mergedURL(for: session.id)
            // A prior crashed export may have left an unfinished combined file.
            // Remove only that generated export, never source segments.
            try? FileManager.default.removeItem(at: merged)
            do {
                let result = try await VideoSegmentComposer.compose(
                    valid, destination: merged
                )
                try repository.importVideo(
                    from: result.url, duration: result.duration, id: session.id
                )
                recovered += 1
                if valid.count == session.segments.count {
                    try? journal.removeSavedSession(session.id)
                } else {
                    // Recover the valid portion, but retain damaged originals
                    // for inspection/backup. The stable ID prevents reimport.
                    unresolved += 1
                }
            } catch {
                unresolved += 1
                // Do not erase original segments after a failure.
            }
        }
        return Result(recovered: recovered, unresolved: unresolved)
    }
}
