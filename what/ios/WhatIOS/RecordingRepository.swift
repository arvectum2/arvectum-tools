import Foundation

enum IncomingRecordingResult {
    case stored(RecordingEnvelope)
    case previouslyDeleted(UUID)

    var id: UUID {
        switch self {
        case .stored(let recording): return recording.id
        case .previouslyDeleted(let id): return id
        }
    }
}

final class RecordingRepository {
    enum RepositoryError: Error { case invalidMetadata, recordingUnavailable, emptyTranscript }

    private let fileManager: FileManager
    private let rootURL: URL
    private let audioDirectory: URL
    private let indexURL: URL
    private let transcriptURL: URL
    private let deletedIDsURL: URL
    // PhoneStore and WatchConnectivity use different repository instances.
    // A shared lock serializes transfer and deletion against the same files.
    private static let sharedStorageLock = NSLock()
    private var lock: NSLock { Self.sharedStorageLock }

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.rootURL = support.appendingPathComponent("What", isDirectory: true)
        }
        audioDirectory = self.rootURL.appendingPathComponent("Audio", isDirectory: true)
        indexURL = self.rootURL.appendingPathComponent("recordings.json")
        transcriptURL = self.rootURL.appendingPathComponent("transcripts.json")
        deletedIDsURL = self.rootURL.appendingPathComponent("deleted-recordings.json")
        try? fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        // Finish cleanup interrupted after writing the durable deletion marker.
        try? resumePendingDeletions()
    }

    func allRecordings() -> [RecordingEnvelope] {
        lock.lock()
        defer { lock.unlock() }
        // If the deletion ledger cannot be read, do not risk displaying erased entries.
        guard let deleted = try? loadDeletedIDs() else { return [] }
        return loadIndex().filter { !deleted.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func audioURL(for recording: RecordingEnvelope) -> URL {
        audioDirectory.appendingPathComponent(recording.fileName)
    }

    @discardableResult
    func acceptTemporaryFile(_ sourceURL: URL, metadata: [String: Any]) throws -> IncomingRecordingResult {
        guard
            let idString = metadata[TransferMetadataKey.id] as? String,
            let id = UUID(uuidString: idString),
            let createdAtValue = metadata[TransferMetadataKey.createdAt] as? Double,
            let duration = metadata[TransferMetadataKey.duration] as? Double
        else { throw RepositoryError.invalidMetadata }

        lock.lock()
        defer { lock.unlock() }

        // A late Watch transfer must still be ACKed, but never resurrect deleted data.
        if try loadDeletedIDs().contains(id) {
            return .previouslyDeleted(id)
        }

        var index = loadIndex()
        let fileName = "\(id.uuidString).m4a"
        let destination = audioDirectory.appendingPathComponent(fileName)

        if let existing = index.first(where: { $0.id == id }) {
            if !fileManager.fileExists(atPath: destination.path) {
                try persistIncomingFile(from: sourceURL, to: destination)
            }
            return .stored(existing)
        }

        try persistIncomingFile(from: sourceURL, to: destination)
        let recording = RecordingEnvelope(
            id: id,
            createdAt: Date(timeIntervalSince1970: createdAtValue),
            duration: duration,
            fileName: fileName
        )
        index.append(recording)
        try persistIndex(index)
        return .stored(recording)
    }

    /// A durable deletion marker is written before any data is erased. This makes
    /// deletion resilient to interrupted cleanup and late WatchConnectivity retries.
    func deleteRecording(_ id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        var deleted = try loadDeletedIDs()
        if deleted.insert(id).inserted {
            try persistDeletedIDs(deleted)
        }

        try cleanupDeletedArtifacts(deleted)
    }

    private func resumePendingDeletions() throws {
        lock.lock()
        defer { lock.unlock() }
        try cleanupDeletedArtifacts(loadDeletedIDs())
    }

    // Caller must hold the shared storage lock.
    private func cleanupDeletedArtifacts(_ deleted: Set<UUID>) throws {
        guard !deleted.isEmpty else { return }
        let index = loadIndex()
        let remaining = index.filter { !deleted.contains($0.id) }
        if remaining.count != index.count {
            try persistIndex(remaining)
        }

        let existing = loadTranscripts()
        let cleaned = existing.filter {
            guard let id = UUID(uuidString: $0.key) else { return true }
            return !deleted.contains(id)
        }
        if cleaned.count != existing.count {
            try ArvectumJSONCodec.encode(cleaned).write(to: transcriptURL, options: .atomic)
        }

        for id in deleted {
            // Use the canonical UUID-based filename, never a stored path.
            let audio = audioDirectory.appendingPathComponent("\(id.uuidString).m4a")
            if fileManager.fileExists(atPath: audio.path) {
                try fileManager.removeItem(at: audio)
            }
        }
    }

    func audioExists(for recording: RecordingEnvelope) -> Bool {
        fileManager.fileExists(atPath: audioURL(for: recording).path)
    }

    func transcripts() -> [UUID: String] {
        lock.lock()
        defer { lock.unlock() }
        // Exclude tombstoned transcripts even if a previous cleanup was interrupted.
        guard let deleted = try? loadDeletedIDs() else { return [:] }
        return Dictionary(uniqueKeysWithValues: loadTranscripts().compactMap { key, value in
            guard let id = UUID(uuidString: key), !deleted.contains(id) else { return nil }
            return (id, value)
        })
    }

    func saveTranscript(_ text: String, for id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        guard !(try loadDeletedIDs()).contains(id) else { return }
        var existing = loadTranscripts()
        existing[id.uuidString] = text
        try ArvectumJSONCodec.encode(existing).write(to: transcriptURL, options: .atomic)
    }

    /// User-edited text is stored independently from the immutable source audio.
    /// Unlike the initial speech path, manual edits require an existing, live note.
    func updateTranscript(_ text: String, for id: UUID) throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RepositoryError.emptyTranscript
        }
        lock.lock()
        defer { lock.unlock() }

        guard !(try loadDeletedIDs()).contains(id),
              loadIndex().contains(where: { $0.id == id }) else {
            throw RepositoryError.recordingUnavailable
        }
        var existing = loadTranscripts()
        existing[id.uuidString] = text
        try ArvectumJSONCodec.encode(existing).write(to: transcriptURL, options: .atomic)
    }

    private func loadTranscripts() -> [String: String] {
        guard let data = try? Data(contentsOf: transcriptURL) else { return [:] }
        return (try? ArvectumJSONCodec.decode([String: String].self, from: data)) ?? [:]
    }

    private func loadDeletedIDs() throws -> Set<UUID> {
        guard fileManager.fileExists(atPath: deletedIDsURL.path) else { return [] }
        let data = try Data(contentsOf: deletedIDsURL)
        let strings = try ArvectumJSONCodec.decode([String].self, from: data)
        guard strings.allSatisfy({ UUID(uuidString: $0) != nil }) else {
            throw RepositoryError.invalidMetadata
        }
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private func persistDeletedIDs(_ ids: Set<UUID>) throws {
        let data = try ArvectumJSONCodec.encode(ids.map(\.uuidString).sorted())
        try data.write(to: deletedIDsURL, options: .atomic)
    }

    private func persistIncomingFile(from sourceURL: URL, to destination: URL) throws {
        let staging = audioDirectory.appendingPathComponent(".\(destination.lastPathComponent).incoming")
        if fileManager.fileExists(atPath: staging.path) {
            try fileManager.removeItem(at: staging)
        }
        try fileManager.copyItem(at: sourceURL, to: staging)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: staging)
        } else {
            try fileManager.moveItem(at: staging, to: destination)
        }
    }

    private func loadIndex() -> [RecordingEnvelope] {
        guard
            let data = try? Data(contentsOf: indexURL),
            let decoded = try? ArvectumJSONCodec.decode([RecordingEnvelope].self, from: data)
        else { return [] }
        return decoded
    }

    private func persistIndex(_ recordings: [RecordingEnvelope]) throws {
        let data = try ArvectumJSONCodec.encode(recordings)
        try data.write(to: indexURL, options: .atomic)
    }
}
