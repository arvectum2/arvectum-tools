import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct BrandHeader: View {
    let showHome: Bool
    let onHome: () -> Void

    var body: some View {
        HStack {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 102, height: 30)

            Spacer()

            if showHome {
                Button(action: onHome) {
                    Label(tr("Фото и PDF под размер"), systemImage: "house.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tr("На главный экран")))
                .accessibilityIdentifier("home-button")
            } else {
                Text(tr("Фото и PDF под размер"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Color.arvectumNavy, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ModeSelector: View {
    let kind: InputKind
    let mode: ToolMode
    let onPhotoMode: (ToolMode) -> Void
    let onPDF: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ToolMode.allCases) { item in
                Button {
                    onPhotoMode(item)
                } label: {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumPrimaryText)
                .background(
                    kind == .photo && mode == item ? Color.arvectumMint : Color.arvectumSurface,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            kind == .photo && mode == item ? Color.arvectumMint : Color.arvectumBorder,
                            lineWidth: 1
                        )
                )
            }

            Button(action: onPDF) {
                Text("PDF")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(
                kind == .pdf ? Color.arvectumMint : Color.arvectumSurface,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(kind == .pdf ? Color.arvectumMint : Color.arvectumBorder, lineWidth: 1)
            )
        }
    }
}

struct Chip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(text, action: action)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .allowsTightening(true)
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                selected ? Color.arvectumMint : Color.arvectumBackground,
                in: RoundedRectangle(cornerRadius: 10)
            )
    }
}
