import Foundation
import NaturalLanguage
import CryptoKit

struct SemanticSearchHit: Identifiable {
    enum Match: String {
        case semantic = "Meaning"
        case text = "Text"
        case number = "Number"
    }

    let recording: RecordingEnvelope
    let snippet: String
    let score: Double
    let match: Match
    var id: UUID { recording.id }
}

struct SemanticSearchOutput {
    let hits: [SemanticSearchHit]
    let semanticAvailable: Bool
    let indexedCount: Int
}

/// Index is a disposable derived cache. Original audio and user text stay in
/// RecordingRepository; cache entries for deleted UUIDs are purged on each search.
final class LocalSemanticSearch {
    struct Chunk: Codable {
        // Derived vectors only; no raw transcript content in the cache.
        let vector: [Double]
    }

    struct CachedEntry: Codable {
        let digest: String
        let chunks: [Chunk]
    }

    struct Cache: Codable {
        let revision: Int
        let modelKey: String
        var entries: [UUID: CachedEntry]
    }

    typealias Vectorizer = (String) -> [Double]?
    static let revision = 1

    private let cacheURL: URL

    init(cacheURL: URL) {
        self.cacheURL = cacheURL
    }

    static func digest(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func chunks(_ text: String, limit: Int = 300) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        // Approximate sentence/paragraph chunks, without truncating long notes.
        // Keep small on-device embedding inputs well below token limits.
        let sentences = trimmed
            .replacingOccurrences(of: "\n", with: ". ")
            .split(whereSeparator: { ".!?。！？".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var output: [String] = []
        var current = ""
        for sentence in sentences {
            if sentence.count > limit {
                if !current.isEmpty { output.append(current); current = "" }
                var piece = ""
                for word in sentence.split(whereSeparator: { $0.isWhitespace }) {
                    let candidate = piece.isEmpty ? String(word) : piece + " " + word
                    if candidate.count > limit && !piece.isEmpty {
                        output.append(piece)
                        piece = String(word)
                    } else {
                        piece = candidate
                    }
                }
                if !piece.isEmpty { output.append(piece) }
            } else if current.count + sentence.count + 2 <= limit {
                current = current.isEmpty ? sentence : current + ". " + sentence
            } else {
                if !current.isEmpty { output.append(current) }
                current = sentence
            }
        }
        if !current.isEmpty { output.append(current) }
        return output
    }

    static func cosine(_ lhs: [Double], _ rhs: [Double]) -> Double? {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return nil }
        let dot = zip(lhs, rhs).reduce(0.0) { $0 + $1.0 * $1.1 }
        let left = lhs.reduce(0.0) { $0 + $1 * $1 }
        let right = rhs.reduce(0.0) { $0 + $1 * $1 }
        guard left > 0, right > 0 else { return nil }
        let value = dot / sqrt(left * right)
        return value.isFinite ? value : nil
    }

    private func loadCache(key: String) -> Cache {
        guard let data = try? Data(contentsOf: cacheURL),
              let cache = try? JSONDecoder().decode(Cache.self, from: data),
              cache.revision == Self.revision,
              cache.modelKey == key else {
            return Cache(revision: Self.revision, modelKey: key, entries: [:])
        }
        return cache
    }

    /// Pure local search with injection for deterministic, offline unit tests.
    func search(
        query: String,
        recordings: [RecordingEnvelope],
        transcripts: [UUID: String],
        vectorizer: Vectorizer?,
        modelKey: String = "text-only"
    ) -> SemanticSearchOutput {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else {
            return SemanticSearchOutput(hits: [], semanticAvailable: vectorizer != nil, indexedCount: 0)
        }
        let availableIDs = Set(recordings.map(\.id))
        var cache = loadCache(key: modelKey)
        cache.entries = cache.entries.filter { availableIDs.contains($0.key) && transcripts[$0.key] != nil }
        let queryVector = vectorizer?(needle)
        let searchTerms = TranscriptLexicalMatcher.tokens(needle)
        // A single rare word is an exact lookup, not a semantic question.
        // Averaged contextual token vectors give high false-positive cosine
        // scores for unrelated notes on one-word queries.
        let allowSemantic = searchTerms.count >= 2
        var hits: [SemanticSearchHit] = []
        var indexed = 0

        for recording in recordings {
            guard let text = transcripts[recording.id],
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            indexed += 1

            let digest = Self.digest(text)
            if cache.entries[recording.id]?.digest != digest {
                cache.entries[recording.id] = CachedEntry(
                    digest: digest,
                    chunks: Self.chunks(text).map { chunk in
                        Chunk(vector: vectorizer?(chunk) ?? [])
                    }
                )
            }

            let sourceChunks = Self.chunks(text)
            let chunks = cache.entries[recording.id]?.chunks ?? []
            var bestScore = 0.0
            var bestSnippet = ""
            var bestMatch = SemanticSearchHit.Match.text

            for (position, chunkText) in sourceChunks.enumerated() {
                let lexicalResult = TranscriptLexicalMatcher.match(
                    query: searchTerms, transcript: chunkText
                )
                let lexical = lexicalResult?.score ?? 0
                // A contextual embedding can be unavailable even if the model
                // exists. Never label a text-only hit "semantic".
                let semantic = queryVector.flatMap { vector in
                    guard position < chunks.count else { return nil }
                    return Self.cosine(vector, chunks[position].vector)
                } ?? 0
                let validSemantic = allowSemantic && semantic >= 0.82
                    ? semantic * 0.90 : 0
                let score = max(lexical, validSemantic)
                if score > bestScore {
                    bestScore = score
                    bestSnippet = chunkText
                    bestMatch = validSemantic > lexical
                        ? .semantic
                        : (lexicalResult?.usedNumberAlias == true ? .number : .text)
                }
            }
            if bestScore > 0 {
                hits.append(SemanticSearchHit(
                    recording: recording,
                    snippet: bestSnippet,
                    score: bestScore,
                    match: bestMatch
                ))
            }
        }

        // Cache is never authoritative. Serialize cache writes with the
        // repository's deletion lock and check its current tombstones/index
        // so a concurrent search cannot recreate deleted note vectors.
        RecordingRepository.sharedStorageLock.lock()
        defer { RecordingRepository.sharedStorageLock.unlock() }
        let root = cacheURL.deletingLastPathComponent()
        let indexURL = root.appendingPathComponent("recordings.json")
        let deletedURL = root.appendingPathComponent("deleted-recordings.json")
        if FileManager.default.fileExists(atPath: indexURL.path),
           let indexData = try? Data(contentsOf: indexURL),
           let index = try? JSONDecoder().decode([RecordingEnvelope].self, from: indexData) {
            let deletedData = try? Data(contentsOf: deletedURL)
            let deletedIDs = Set(
                (deletedData.flatMap {
                    try? JSONDecoder().decode([String].self, from: $0)
                } ?? []).compactMap(UUID.init(uuidString:))
            )
            let liveIDs = Set(index.map(\.id)).subtracting(deletedIDs)
            cache.entries = cache.entries.filter { liveIDs.contains($0.key) }
        } else if FileManager.default.fileExists(atPath: deletedURL.path) {
            // Corrupt index? Do not write back unverified derived data.
            cache.entries = [:]
        }
        if let data = try? JSONEncoder().encode(cache) {
            try? FileManager.default.createDirectory(
                at: root, withIntermediateDirectories: true
            )
            try? data.write(to: cacheURL, options: .atomic)
        }
        hits.sort {
            if $0.score == $1.score {
                return $0.recording.createdAt > $1.recording.createdAt
            }
            return $0.score > $1.score
        }
        return SemanticSearchOutput(
            hits: hits,
            semanticAvailable: queryVector != nil,
            indexedCount: indexed
        )
    }
}

/// No network calls, no automatic model download.
/// For languages without local assets, return nil and use the lexical search.
final class AppleLocalEmbedder {
    private let model: NLContextualEmbedding?
    let key: String

    init(query: String) {
        let language: NLLanguage
        if query.unicodeScalars.contains(where: { (0x0400...0x052F).contains($0.value) }) {
            language = .russian
        } else {
            language = NLLanguageRecognizer.dominantLanguage(for: query) ?? .english
        }

        if let candidate = NLContextualEmbedding(language: language),
           candidate.hasAvailableAssets,
           (try? candidate.load()) != nil {
            model = candidate
            key = "apple-contextual-\(candidate.modelIdentifier)-\(candidate.revision)"
        } else {
            model = nil
            key = "text-only"
        }
    }

    var isAvailable: Bool { model != nil }

    deinit { model?.unload() }

    func vector(for text: String) -> [Double]? {
        guard let model,
              let result = try? model.embeddingResult(for: text, language: nil) else {
            return nil
        }
        var values = [Double](repeating: 0, count: model.dimension)
        var count = 0
        result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { vector, _ in
            guard vector.count == values.count else { return true }
            for i in values.indices {
                values[i] += vector[i]
            }
            count += 1
            return true
        }
        guard count > 0 else { return nil }
        return values.map { $0 / Double(count) }
    }
}
