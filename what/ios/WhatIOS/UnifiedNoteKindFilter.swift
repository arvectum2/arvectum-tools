import Foundation

/// A presentation-only filter over one unified Inbox. Filtering must never
/// mutate or migrate the existing Watch audio ledger or local text/video data.
enum UnifiedNoteKindFilter: String, CaseIterable, Identifiable {
    case all, audio, text, video

    var id: String { rawValue }

    func matches(_ note: UnifiedNote) -> Bool {
        switch (self, note) {
        case (.all, _), (.audio, .audio): return true
        case (.text, .local(let local)): return local.kind == .text
        case (.video, .local(let local)): return local.kind == .video
        default: return false
        }
    }

    func notes(in allNotes: [UnifiedNote]) -> [UnifiedNote] {
        allNotes.filter(matches)
    }

    func count(in allNotes: [UnifiedNote]) -> Int {
        allNotes.lazy.filter(matches).count
    }
}
