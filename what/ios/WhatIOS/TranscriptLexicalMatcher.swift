import Foundation

/// Word-boundary local retrieval that never silently rewrites transcripts.
/// A narrow number alias supports a known iOS Speech shorthand: "раз 2345"
/// may be the spoken count "раз два три четыре пять".
enum TranscriptLexicalMatcher {
    struct Result {
        let score: Double
        let usedNumberAlias: Bool
    }

    private static let spokenDigits: [Character: String] = [
        "1": "один", "2": "два", "3": "три", "4": "четыре",
        "5": "пять", "6": "шесть", "7": "семь",
        "8": "восемь", "9": "девять"
    ]

    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    /// Only sequential digit groups in an explicit counting context.
    /// Never treat an arbitrary telephone number, year or identifier as a list
    /// of spoken single digits. 2345 + preceding "раз" is unambiguous enough
    /// to offer a *lower ranked* derived match, without changing saved text.
    private static func expandedCountingTokens(_ source: [String]) -> [String] {
        var expanded: [String] = []
        for (position, token) in source.enumerated() {
            let digits = Array(token)
            let precedingCount = position > 0 &&
                ["раз", "один", "одна", "первый", "считаю"].contains(source[position - 1])
            let ascending = digits.count >= 3 && digits.count <= 8 &&
                digits.allSatisfy { spokenDigits[$0] != nil } &&
                zip(digits, digits.dropFirst()).allSatisfy {
                    guard let a = $0.wholeNumberValue,
                          let b = $1.wholeNumberValue else { return false }
                    return b == a + 1
                }

            if precedingCount && ascending {
                expanded.append(contentsOf: digits.compactMap { spokenDigits[$0] })
            } else {
                expanded.append(token)
            }
        }
        return expanded
    }

    /// Prefix matching supports "тест" -> "тестовое", not typo/fuzzy
    /// equivalence: "тест" must never match "текст".
    private static func termMatches(_ query: String, _ source: String) -> Bool {
        if query == source { return true }
        return query.count >= 4 && query.allSatisfy { $0.isLetter } &&
            source.hasPrefix(query)
    }

    private static func phraseExists(_ query: [String], in source: [String]) -> Bool {
        guard !query.isEmpty, source.count >= query.count else { return false }
        for start in 0...(source.count - query.count) {
            if query.enumerated().allSatisfy({
                termMatches($0.element, source[start + $0.offset])
            }) { return true }
        }
        return false
    }

    private static func allWordsMatch(_ query: [String], in source: [String]) -> Bool {
        query.allSatisfy { word in
            source.contains { termMatches(word, $0) }
        }
    }

    static func match(query: [String], transcript: String) -> Result? {
        guard !query.isEmpty else { return nil }
        let source = tokens(transcript)
        guard !source.isEmpty else { return nil }
        if phraseExists(query, in: source) {
            return Result(score: 1.20, usedNumberAlias: false)
        }
        // For multi-word queries, all terms can appear in the same chunk but
        // separated by other words. A single word needs an actual token match.
        if query.count > 1 && allWordsMatch(query, in: source) {
            return Result(score: 0.82, usedNumberAlias: false)
        }
        let expanded = expandedCountingTokens(source)
        if expanded != source {
            if phraseExists(query, in: expanded) {
                return Result(score: 1.00, usedNumberAlias: true)
            }
            if query.count > 1 && allWordsMatch(query, in: expanded) {
                return Result(score: 0.72, usedNumberAlias: true)
            }
        }
        return nil
    }
}
