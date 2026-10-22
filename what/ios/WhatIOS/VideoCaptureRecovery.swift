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
        // AVFoundation creates its recovery MOV segments inside this folder.
        // Set the directory protection before allocating any camera outputs.
        try PrivateMediaProtection.protect(folder, fileManager: files)
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
                  !Self.isActive(id) else { return nil }
            // Only inactive crash-recovery sessions are touched; an in-flight
            // AVFoundation writer must never have its media modified.
            try PrivateMediaProtection.protect(folder, fileManager: files)
            try PrivateMediaProtection.migrateFiles(in: folder, fileManager: files)
            guard let manifest = try readManifest(id),
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
            // A crash before AVFoundation finalized its first segment may
            // leave only a manifest. Surface it as unresolved rather than
            // silently forgetting that the user started a recording.
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
            to: manifestURL(manifest.id),
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
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
        repository: LocalNoteRepository,
        requireCompleteSegments: Bool = false,
        expectedSegmentCount: Int = 0
    ) async throws -> Result {
        let pending = try journal.pendingSessions()
        var recovered = 0
        var unresolved = 0

        for session in pending {
            // Crash after durable repository commit but before source cleanup:
            // never add a second note for the same capture UUID.
            if try repository.hasVideo(id: session.id) {
                // On a previous partial salvage, never delete a later segment
                // that has not yet been included in the saved movie. It may
                // become finalized after the foreground recovery returned.
                var allReadable = true
                var combinedSourceDuration = 0.0
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
                    combinedSourceDuration += duration.seconds
                }
                let indexedDuration = try repository.indexedVideoDuration(id: session.id) ?? 0
                // Already-indexed partial clips might have extra readable
                // content: retain ALL originals for a safe future repair.
                if allReadable, session.segments.count >= expectedSegmentCount,
                   combinedSourceDuration <= indexedDuration + 0.15 {
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

            // Foreground return is NOT a crash: the final camera segment may
            // still be flushing to disk. Do not import a playable *prefix* of
            // an incomplete multi-camera recording as the final note.
            if requireCompleteSegments,
               (session.segments.count < expectedSegmentCount ||
                valid.count != session.segments.count) {
                unresolved += 1
                continue
            }

            // An empty session or an unfinalized first MOV is not playable.
            // Keep its manifest and original bytes for another attempt, and
            // report the unresolved capture to the UI without inventing a note.
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
