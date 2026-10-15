import Combine
import Foundation
import NaturalLanguage

/// Models are managed by iOS, not bundled in the application container.
/// Apple's public API does not expose compressed download size, total bytes,
/// percentage, or transfer speed: progress is necessarily indeterminate.
@MainActor
final class RussianModelManager: ObservableObject {
    static let shared = RussianModelManager()

    enum Phase: Equatable {
        case unchecked
        case checking
        case missing
        case requesting
        case verifying
        case ready
        case failed(String)

        var isBusy: Bool {
            self == .requesting || self == .verifying || self == .checking
        }
    }

    @Published private(set) var phase: Phase = .unchecked
    @Published private(set) var startedAt: Date?

    private init() {}

    func refresh() {
        // Do not overwrite an active transfer state with a parallel check.
        guard phase != .requesting && phase != .verifying else { return }
        phase = .checking
        Task {
            let available = await Task.detached(priority: .utility) {
                Self.checkAvailability()
            }.value
            phase = available ? .ready : .missing
        }
    }

    func startInstall() {
        guard phase != .requesting && phase != .verifying else { return }
        startedAt = Date()
        phase = .requesting
        Task {
            do {
                let received = try await Task.detached(priority: .utility) {
                    guard let embedding = NLContextualEmbedding(language: .russian)
                    else { return false }
                    let result = try await embedding.requestAssets()
                    return result == .available
                }.value
                phase = .verifying
                let verified = await Task.detached(priority: .utility) {
                    Self.checkAvailability()
                }.value
                let usable = received && verified
                phase = usable ? .ready : .failed(
                    "Apple did not make the Russian language model available. Check connectivity and free storage, then retry."
                )
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    nonisolated private static func checkAvailability() -> Bool {
        guard let embedding = NLContextualEmbedding(language: .russian),
              embedding.hasAvailableAssets else { return false }
        do {
            try embedding.load()
            let phrase = "проверка модели"
            let result = try embedding.embeddingResult(
                for: phrase, language: .russian
            )
            var foundVector = false
            result.enumerateTokenVectors(
                in: phrase.startIndex..<phrase.endIndex
            ) { vector, _ in
                foundVector = !vector.isEmpty
                return false
            }
            embedding.unload()
            return foundVector
        } catch {
            embedding.unload()
            return false
        }
    }
}
