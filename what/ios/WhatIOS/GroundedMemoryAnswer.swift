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

    static func extract(_ results: SemanticSearchOutput) -> GroundedMemoryAnswer {
        // A semantic hit is useful only when its absolute cosine score met
        // the local engine's threshold. The search engine enforces it and
        // assigns a score <= 0.90. Lexical evidence has a stronger tier.
        // No speculative composition or text generation is performed.
        let sufficientlyGrounded = results.hits.filter { hit in
            switch hit.match {
            // Score is cosine * 0.90. A semantic result is a candidate
            // excerpt for user inspection, not a factual synthesized answer.
            case .semantic: return hit.score >= 0.60
            case .text, .number: return hit.score >= 0.72
            }
        }
        return GroundedMemoryAnswer(evidence: Array(sufficientlyGrounded.prefix(3)))
    }
}
