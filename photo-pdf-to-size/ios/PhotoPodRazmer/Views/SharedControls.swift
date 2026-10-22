import ArvectumCore
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct BrandHeader: View {
    let showHome: Bool
    let onHome: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 102, height: 30)
                .accessibilityHidden(true) // Decorative logo, not an unnamed action.

            Spacer()

            if showHome {
                Button(action: onHome) {
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            // In the 46pt header, icon-only avoids clipping
                            // while the full action remains spoken by VoiceOver.
                            Image(systemName: "house.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 44, height: 44)
                        } else {
                            Label(tr("Фото и PDF под размер"), systemImage: "house.fill")
                                .font(.headline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.84)
                        }
                    }
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tr("На главный экран")))
                .accessibilityIdentifier("home-button")
            } else {
                Text(tr("Фото и PDF под размер"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .xxxLarge : dynamicTypeSize)
        .background(Color.arvectumNavy, in: RoundedRectangle(cornerRadius: 20))
    }
}

/// At accessibility text sizes the four modes get two rows instead of
/// four clipped captions squeezed into one row. Each button retains its
/// stable automation/accessibility identifier across both layouts.
struct ModeSelector: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let kind: InputKind
    let mode: ToolMode
    let onPhotoMode: (ToolMode) -> Void
    let onPDF: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 6),
                              GridItem(.flexible(), spacing: 6)],
                    spacing: 6
                ) {
                    modeButtons
                }
            } else {
                HStack(spacing: 6) {
                    modeButtons
                }
            }
        }
    }

    @ViewBuilder
    private var modeButtons: some View {
        ForEach(ToolMode.allCases) { item in
            Button {
                onPhotoMode(item)
            } label: {
                modeCaption(item.title)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("mode-\(item.rawValue)")
            .accessibilityLabel(Text(item.accessibilityTitle))
            .accessibilityAddTraits(kind == .photo && mode == item ? [.isSelected] : [])
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
            modeCaption("PDF")
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mode-pdf")
        .accessibilityLabel(Text(tr("Обработать PDF")))
        .accessibilityAddTraits(kind == .pdf ? [.isSelected] : [])
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

    private func modeCaption(_ caption: String) -> some View {
        Text(caption)
            .font(.caption.weight(.semibold))
            // Navigation labels use a generous but bounded type size.
            // Otherwise an AXXXL caption takes five lines and pushes the
            // actual editing controls outside the initial viewport.
            .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
            .multilineTextAlignment(.center)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 86 : 46)
            .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 6 : 0)
            .contentShape(Rectangle())
    }
}

/// Two-column layout at accessibility sizes, not six truncated preset
/// labels in a single row. Normal-size typography retains its compact row.
struct AdaptiveChipRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 6),
                          GridItem(.flexible(), spacing: 6)],
                spacing: 6
            ) { content() }
        } else {
            HStack(spacing: 6) { content() }
        }
    }
}

struct Chip: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(text, action: action)
            .font(.caption2.weight(.semibold))
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.88 : 0.72)
            .allowsTightening(true)
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 62 : 34)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
            .background(
                selected ? Color.arvectumMint : Color.arvectumBackground,
                in: RoundedRectangle(cornerRadius: 10)
            )
    }
}
