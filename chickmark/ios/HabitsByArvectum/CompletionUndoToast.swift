import SwiftUI

struct CompletionUndoOffer: Identifiable, Equatable {
    let id: UUID
    let habitID: UUID
    let dayKey: String
    var slot: Int? = nil
}

struct CompletionUndoToast: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onUndo: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    message
                    undoButton
                }
            } else {
                HStack(spacing: 12) {
                    message
                    Spacer(minLength: 8)
                    undoButton
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 3)
    }

    private var message: some View {
        Label(
            L10n.string("habit.completed.toast"),
            systemImage: "checkmark.circle.fill"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
    }

    private var undoButton: some View {
        Button(L10n.string("common.undo"), action: onUndo)
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.borderless)
            .frame(minHeight: 44)
    }
}
