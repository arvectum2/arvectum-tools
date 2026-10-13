import Foundation

/// Extractive answers only: never invent content, summarize unseen audio or
/// turn a weakly related vector neighbor into a factual assertion.
struct GroundedMemoryAnswer {
    let evidence: [SemanticSearchHit]
    var hasEvidence: Bool { !evidence.isEmpty }

    static func focusQuery(_ userQuestion: String) -> String {
        let words = TranscriptLexicalMatcher.tokens(userQuestion)
        let filler: Set<String> = [
            "где", "когда", "что", "кто", "какой", "какая", "какие",
            "какое", "кому", "чем", "почему", "зачем", "как", "сколько",
            "напомни", "расскажи", "найди", "сказал", "сказала",
            "говорил", "говорила", "записывал", "записал", "помню",
            "оставил", "оставила", "положил", "положила", "лежит",
            "лежат", "находится", "находятся",
            "помнить", "пожалуйста", "покажи", "мой", "моя", "мои",
            "мне", "меня", "я", "мы", "ты", "вы", "он", "она",
            "это", "было", "были", "был", "будет", "есть",
            "о", "об", "про", "в", "на", "с", "со", "у", "по", "к",
            "из", "за", "для", "ли", "и", "или", "не"
        ]
        let focused = words.filter { !filler.contains($0) }
        // Do not erase a fully stopword query and accidentally expose all notes.
        return focused.isEmpty ? userQuestion : focused.joined(separator: " ")
    }

    enum Assessment: Equatable {
        case clearEvidence
        case weakSimilarity
        case ambiguousSimilarity
        case noEvidence
    }

    let assessment: Assessment

    static func extract(_ results: SemanticSearchOutput) -> GroundedMemoryAnswer {
        let direct = results.hits.filter {
            $0.match == .text || $0.match == .number ||
                $0.match == .concept
        }
        if !direct.isEmpty {
            // Lexical evidence is attributable to actual stored words; no
            // similarity score needs to be mistaken for a probability.
            return GroundedMemoryAnswer(
                evidence: Array(direct.prefix(3)),
                assessment: .clearEvidence
            )
        }

        let candidates = results.hits
            .filter { $0.match == .semantic }
            .sorted { $0.score > $1.score }
        guard let top = candidates.first else {
            return GroundedMemoryAnswer(evidence: [], assessment: .noEvidence)
        }

        // Contextual token embeddings aren't calibrated sentence similarity.
        // Arbitrary queries often score every note surprisingly highly.
        // Require both absolute strength and corpus-level separation.
        guard top.score >= 0.76 else {
            return GroundedMemoryAnswer(evidence: [], assessment: .weakSimilarity)
        }
        if candidates.count == 1 {
            // One candidate lacks a baseline; require a strong absolute
            // similarity before presenting it as a possible source.
            return GroundedMemoryAnswer(
                evidence: top.score >= 0.81 ? [top] : [],
                assessment: top.score >= 0.81 ? .clearEvidence : .weakSimilarity
            )
        }
        let second = candidates[1].score
        // A run of equal-scoring notes is NOT evidence for three answers.
        guard top.score - second >= 0.045 else {
            return GroundedMemoryAnswer(evidence: [], assessment: .ambiguousSimilarity)
        }
        if candidates.count >= 3 {
            let middle = candidates[candidates.count / 2].score
            guard top.score - middle >= 0.065 else {
                return GroundedMemoryAnswer(
                    evidence: [], assessment: .ambiguousSimilarity
                )
            }
        }
        return GroundedMemoryAnswer(
            evidence: [top], assessment: .clearEvidence
        )
    }
}
