import Foundation

final class RecordingRepository {
    enum RepositoryError: Error { case invalidMetadata }

    private let fileManager: FileManager
    private let rootURL: URL
    private let audioDirectory: URL
    private let indexURL: URL
    private let lock = NSLock()

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
        try? fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
    }

    func allRecordings() -> [RecordingEnvelope] {
        lock.lock()
        defer { lock.unlock() }
        return loadIndex().sorted { $0.createdAt > $1.createdAt }
    }

    func audioURL(for recording: RecordingEnvelope) -> URL {
        audioDirectory.appendingPathComponent(recording.fileName)
    }

    @discardableResult
    func acceptTemporaryFile(_ sourceURL: URL, metadata: [String: Any]) throws -> RecordingEnvelope {
        guard
            let idString = metadata[TransferMetadataKey.id] as? String,
            let id = UUID(uuidString: idString),
            let createdAtValue = metadata[TransferMetadataKey.createdAt] as? Double,
            let duration = metadata[TransferMetadataKey.duration] as? Double
        else { throw RepositoryError.invalidMetadata }

        lock.lock()
        defer { lock.unlock() }

        var index = loadIndex()
        let fileName = "\(id.uuidString).m4a"
        let destination = audioDirectory.appendingPathComponent(fileName)

        if let existing = index.first(where: { $0.id == id }) {
            if !fileManager.fileExists(atPath: destination.path) {
                try persistIncomingFile(from: sourceURL, to: destination)
            }
            return existing
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
        return recording
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
            let decoded = try? JSONDecoder().decode([RecordingEnvelope].self, from: data)
        else { return [] }
        return decoded
    }

    private func persistIndex(_ recordings: [RecordingEnvelope]) throws {
        let data = try JSONEncoder().encode(recordings)
        try data.write(to: indexURL, options: .atomic)
    }
}
