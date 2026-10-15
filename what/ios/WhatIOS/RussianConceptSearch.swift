import Foundation
import NaturalLanguage

/// Offline ontology-based Russian concept matching.
///
/// This engine can run with any compatible, properly licensed concept graph.
/// The development graph is generated separately and is intentionally NOT
/// committed to Git: RuWordNet's corpus redistribution terms need review.
final class RussianConceptSearch {
    struct Graph: Codable {
        let rev: Int
        let source: String
        let terms: [String: [Int]]
        let forms: [String: String]
        let parents: [[Int]]
        let hyponyms: [Int]
    }

    private let graph: Graph
    private let common: Set<String> = Set("""
        раз два три четыре пять шесть семь восемь девять десять
        сейчас потом просто этот весь какой что который быть это один свой
        мой мне себя уже делать сделать нужно такой где вот там все очень
        на по тут как этого когда если для здесь тоже сначала тогда
        пожалуйста про об его ее они мы вы наше ваш
        """.split(whereSeparator: \.isWhitespace).map(String.init))

    init(graph: Graph) {
        self.graph = graph
    }

    convenience init?(bundled: Bundle = .main) {
        guard let url = bundled.url(
                  forResource: "RussianConceptGraph.json",
                  withExtension: "zlib"
              ),
              let bytes = try? Data(contentsOf: url),
              let plain = try? (bytes as NSData).decompressed(using: .zlib),
              let graph = try? JSONDecoder().decode(Graph.self, from: plain as Data),
              graph.rev == 2,
              graph.parents.count == graph.hyponyms.count
        else { return nil }
        self.init(graph: graph)
    }

    /// Apple Russian lemmatizer supports running without a third-party
    /// morphological dictionary or an external network.
    func terms(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = text
        guard !text.isEmpty else { return [] }
        tagger.setLanguage(.russian, range: text.startIndex..<text.endIndex)
        var tokens: [String] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            let raw = Self.normalize(String(text[range]))
            let lemma = Self.normalize(tag?.rawValue ?? raw)
            // Morphology shipped as a compact local lookup. It corrects
            // Apple lemmatizer omissions ("красоту" -> "красота") and
            // normalizes common Russian inflections entirely offline.
            let word: String
            if graph.terms[raw] != nil {
                word = raw
            } else if let canonical = graph.forms[raw] ??
                        graph.forms[lemma] {
                // Prefer unambiguous dictionary inflections to Apple's
                // occasional incorrect Russian lemma (эстетику -> эстетик).
                word = canonical
            } else {
                word = lemma
            }
            if word.count >= 3 && !common.contains(word) &&
                word.unicodeScalars.contains(where: {
                    CharacterSet.letters.contains($0)
                }) {
                tokens.append(word)
            }
            return true
        }
        var expanded = tokens
        // The ontology contains true noun phrases; don't erase context.
        for position in tokens.indices {
            for length in [2, 3] where position + length <= tokens.count {
                let compound = tokens[position..<(position + length)].joined(separator: " ")
                if graph.terms[compound] != nil {
                    expanded.append(compound)
                }
            }
        }
        return Array(Set(expanded)).sorted()
    }

    private static func normalize(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: "ё", with: "е")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func ancestors(_ node: Int, maxDepth: Int = 3) -> [Int: Int] {
        guard graph.parents.indices.contains(node) else { return [:] }
        var best: [Int: Int] = [:]
        var queue: [(Int, Int)] = [(node, 0)]
        var cursor = 0
        while cursor < queue.count {
            let (current, depth) = queue[cursor]
            cursor += 1
            if let old = best[current], old <= depth { continue }
            best[current] = depth
            if depth < maxDepth && graph.parents.indices.contains(current) {
                for parent in graph.parents[current] {
                    queue.append((parent, depth + 1))
                }
            }
        }
        return best
    }

    /// A graph match is *evidence of a known semantic relation*, not a
    /// probability or an ungrounded contextual vector neighbor.
    func score(query: String, passage: String) -> Double? {
        let asked = terms(query)
        let present = terms(passage)
        guard !asked.isEmpty && !present.isEmpty else { return nil }
        var best = 0.0
        for queryTerm in asked {
            for sourceTerm in present {
                if queryTerm == sourceTerm {
                    best = max(best, 1.35)
                    continue
                }
                guard let querySenses = graph.terms[queryTerm],
                      let sourceSenses = graph.terms[sourceTerm] else { continue }

                var relations: [Int: Int] = [:]
                for sense in querySenses {
                    for (node, depth) in ancestors(sense) {
                        relations[node] = min(relations[node] ?? .max, depth)
                    }
                }
                for sense in sourceSenses {
                    for (node, distance) in ancestors(sense) {
                        guard let opposite = relations[node] else { continue }
                        let hops = opposite + distance
                        guard hops > 0 && hops <= 3 else { continue }
                        // Match a genuine class or specific relation.
                        // Common ancestors such as "thing" must never create
                        // a claimed similarity between unrelated objects.
                        if opposite > 0 && distance > 0 &&
                            graph.hyponyms.indices.contains(node) &&
                            graph.hyponyms[node] > 10 {
                            continue
                        }
                        let relationScore: Double = switch hops {
                        case 1: 1.10
                        case 2: 0.96
                        default: 0.80
                        }
                        best = max(best, relationScore)
                    }
                }
            }
        }
        return best > 0 ? best : nil
    }
}
