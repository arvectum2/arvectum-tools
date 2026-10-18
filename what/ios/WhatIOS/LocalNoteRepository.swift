import Foundation

/// User-authored text and video notes are additive to the legacy Watch audio
/// ledger. This avoids migrating or rewriting durable Watch recordings.
struct LocalNote: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case text, video }
    let id: UUID
    let kind: Kind
    let createdAt: Date
    var updatedAt: Date
    var body: String
    var fileName: String?
    var duration: TimeInterval?
    var archived: Bool
    var sourceDevice: String
}

enum UnifiedNote: Identifiable {
    case audio(RecordingEnvelope)
    case local(LocalNote)

    var id: UUID {
        switch self {
        case .audio(let note): return note.id
        case .local(let note): return note.id
        }
    }
    var createdAt: Date {
        switch self {
        case .audio(let note): return note.createdAt
        case .local(let note): return note.createdAt
        }
    }
}

struct UnifiedNoteGroup: Identifiable {
    let day: InboxDay
    let notes: [UnifiedNote]
    var id: InboxDay { day }
}

enum UnifiedInbox {
    static func visible(
        recordings: [RecordingEnvelope],
        localNotes: [LocalNote],
        archivedAudioIDs: Set<UUID>,
        folder: InboxFolder,
        query: String,
        transcripts: [UUID: String]
    ) -> [UnifiedNote] {
        let audio = InboxOrganizer.recordings(
            recordings, archivedIDs: archivedAudioIDs,
            folder: folder, query: query, transcripts: transcripts
        ).map(UnifiedNote.audio)
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let local = localNotes.filter { note in
            guard note.archived == (folder == .archive) else { return false }
            guard !needle.isEmpty else { return true }
            let date = DateFormatter.localizedString(
                from: note.createdAt, dateStyle: .medium, timeStyle: .short
            )
            return note.body.localizedStandardContains(needle)
                || date.localizedStandardContains(needle)
                || note.kind.rawValue.localizedStandardContains(needle)
        }.map(UnifiedNote.local)
        return (audio + local).sorted { a, b in
            a.createdAt == b.createdAt
                ? a.id.uuidString < b.id.uuidString
                : a.createdAt > b.createdAt
        }
    }

    static func groups(_ items: [UnifiedNote], now: Date = Date(),
                       calendar: Calendar = .current) -> [UnifiedNoteGroup] {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let grouped = Dictionary(grouping: items) { item -> InboxDay in
            if calendar.isDate(item.createdAt, inSameDayAs: now) { return .today }
            if calendar.isDate(item.createdAt, inSameDayAs: yesterday) { return .yesterday }
            return .earlier
        }
        return InboxDay.allCases.compactMap { day in
            guard let notes = grouped[day], !notes.isEmpty else { return nil }
            return UnifiedNoteGroup(day: day, notes: notes)
        }
    }
}

/// Dedicated on-device ledger for new media. Existing recordings.json stays
/// wire-compatible with Watch ACK and tombstone logic.
final class LocalNoteRepository {
    enum NoteError: Error { case missingNote, invalidMedia, incorrectKind }
    private let fileManager: FileManager
    private let root: URL
    private let indexURL: URL
    private let videosURL: URL
    private let lock = RecordingRepository.sharedStorageLock

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            root = rootURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask).first!
            root = support.appendingPathComponent("What", isDirectory: true)
        }
        indexURL = root.appendingPathComponent("local-notes.json")
        videosURL = root.appendingPathComponent("Videos", isDirectory: true)
        try? fileManager.createDirectory(at: videosURL, withIntermediateDirectories: true)
    }

    private func readIndex() throws -> [LocalNote] {
        guard fileManager.fileExists(atPath: indexURL.path) else { return [] }
        return try ArvectumJSONCodec.decode(
            [LocalNote].self, from: Data(contentsOf: indexURL)
        )
    }

    private func writeIndex(_ notes: [LocalNote]) throws {
        try ArvectumJSONCodec.encode(notes).write(to: indexURL, options: .atomic)
    }

    func allNotes() throws -> [LocalNote] {
        lock.lock()
        defer { lock.unlock() }
        return try readIndex().sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func saveText(id: UUID, body: String, sourceDevice: String = "iOS") throws -> LocalNote? {
        lock.lock()
        defer { lock.unlock() }
        var notes = try readIndex()
        if let index = notes.firstIndex(where: { $0.id == id }) {
            guard notes[index].kind == .text else { throw NoteError.incorrectKind }
            notes[index].body = body
            notes[index].updatedAt = Date()
            try writeIndex(notes)
            return notes[index]
        }
        // Tapping + and closing an empty editor must not create empty notes.
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let now = Date()
        let note = LocalNote(id: id, kind: .text, createdAt: now, updatedAt: now,
                             body: body, fileName: nil, duration: nil,
                             archived: false, sourceDevice: sourceDevice)
        notes.append(note)
        try writeIndex(notes)
        return note
    }

    func hasVideo(id: UUID) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return try readIndex().contains {
            $0.id == id && $0.kind == .video &&
            fileManager.fileExists(atPath: videosURL.appendingPathComponent(
                id.uuidString + ".mov"
            ).path)
        }
    }

    @discardableResult
    func importVideo(from source: URL, duration: TimeInterval,
                     id: UUID = UUID(),
                     sourceDevice: String = "iOS") throws -> LocalNote {
        guard duration > 0, fileManager.fileExists(atPath: source.path),
              let size = try fileManager.attributesOfItem(atPath: source.path)[.size] as? NSNumber,
              size.int64Value > 0 else { throw NoteError.invalidMedia }
        lock.lock()
        defer { lock.unlock() }
        var notes = try readIndex()
        if let existing = notes.first(where: { $0.id == id }) {
            guard existing.kind == .video else { throw NoteError.incorrectKind }
            let path = videosURL.appendingPathComponent(id.uuidString + ".mov")
            if fileManager.fileExists(atPath: path.path) { return existing }
            // A crashed file-system migration may leave the index but not
            // the original. Reconstruct the missing media without a duplicate.
            let staged = videosURL.appendingPathComponent("." + id.uuidString + ".repair")
            try fileManager.copyItem(at: source, to: staged)
            do {
                try fileManager.moveItem(at: staged, to: path)
            } catch {
                try? fileManager.removeItem(at: staged)
                throw error
            }
            return existing
        }
        let name = id.uuidString + ".mov"
        let destination = videosURL.appendingPathComponent(name)
        let staging = videosURL.appendingPathComponent("." + name + ".incoming")
        try fileManager.copyItem(at: source, to: staging)
        do {
            try fileManager.moveItem(at: staging, to: destination)
            let now = Date()
            let note = LocalNote(id: id, kind: .video, createdAt: now,
                                 updatedAt: now, body: "", fileName: name,
                                 duration: duration, archived: false,
                                 sourceDevice: sourceDevice)
            notes.append(note)
            try writeIndex(notes)
            return note
        } catch {
            try? fileManager.removeItem(at: staging)
            try? fileManager.removeItem(at: destination)
            throw error
        }
    }

    func videoURL(for note: LocalNote) -> URL? {
        guard note.kind == .video, let name = note.fileName,
              name == note.id.uuidString + ".mov" else { return nil }
        return videosURL.appendingPathComponent(name)
    }

    func setArchived(_ id: UUID, archived: Bool) throws {
        lock.lock()
        defer { lock.unlock() }
        var notes = try readIndex()
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw NoteError.missingNote
        }
        notes[index].archived = archived
        try writeIndex(notes)
    }

    func delete(_ id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        var notes = try readIndex()
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let removed = notes.remove(at: index)
        // Persist deletion before removing media. If interrupted, the note
        // stays hidden rather than resurrecting deleted user content.
        try writeIndex(notes)
        if let url = videoURL(for: removed), fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
