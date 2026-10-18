import SwiftUI

/// Shazam-like home screen: one prominent action, saved recordings one tap
/// away. The recording sheet starts capture automatically on presentation.
struct QuickCaptureHomeView: View {
    let recordingsCount: Int
    let startRecording: () -> Void
    let openLibrary: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let accent = Color(red: 0.68, green: 1.0, blue: 0.81)
    private let background = Color(red: 0.004, green: 0.075, blue: 0.19)

    private var compactLayout: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var isRussian: Bool { CaptureBrand.isRussian }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background.ignoresSafeArea()

                Circle()
                    .fill(accent.opacity(0.09))
                    .frame(width: min(410, geometry.size.width * 0.85),
                           height: min(410, geometry.size.width * 0.85))
                    .blur(radius: 85)
                    .offset(x: geometry.size.width * 0.3, y: -75)
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    topBar

                    Spacer(minLength: compactLayout ? 10 : 22)

                    VStack(spacing: compactLayout ? 8 : 16) {
                        Text(isRussian ? "Ухвати мысль" : "Catch that thought")
                            .font(.system(
                                size: compactLayout ? 28 : 33,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.75)
                            .lineLimit(1)

                        if !compactLayout {
                            Text(isRussian
                                ? "Одно нажатие — и говори."
                                : "One tap. Start speaking.")
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        recordButton(
                            diameter: min(
                                232,
                                geometry.size.width * 0.66,
                                geometry.size.height * (compactLayout ? 0.27 : 0.34)
                            )
                        )
                        .padding(.top, compactLayout ? 8 : 25)

                        Text(isRussian ? "Нажми, чтобы записать" : "Tap to record")
                            .font(.system(size: compactLayout ? 17 : 21, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.top, compactLayout ? 7 : 12)

                        Label(
                            isRussian ? "Сохраняется на iPhone" : "Saved on your iPhone",
                            systemImage: "lock.shield"
                        )
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.56))
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: compactLayout ? 10 : 18)

                    libraryButton
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, min(25, geometry.size.width * 0.045))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                Image("WhatGlyph")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)

                Text(CaptureBrand.name)
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            if !compactLayout {
                Text(isRussian ? "БЫСТРАЯ ЗАПИСЬ" : "QUICK CAPTURE")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.7)
                    .foregroundStyle(.white.opacity(0.53))
            }
        }
        .padding(.top, 18)
        .accessibilityAddTraits(.isHeader)
    }

    private func recordButton(diameter: CGFloat) -> some View {
        Button(action: startRecording) {
            ZStack {
                // Echo the approved circular What? brand button. The mint
                // emblem is extracted from the user-approved app icon.
                Circle()
                    .strokeBorder(accent.opacity(0.12), lineWidth: 1.5)
                    .frame(width: diameter, height: diameter)

                Circle()
                    .fill(accent.opacity(0.075))
                    .frame(width: diameter * 0.95, height: diameter * 0.95)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.07, green: 0.29, blue: 0.53),
                                Color(red: 0.012, green: 0.13, blue: 0.32),
                                background
                            ],
                            center: .init(x: 0.42, y: 0.32),
                            startRadius: 0,
                            endRadius: diameter * 0.48
                        )
                    )
                    .frame(width: diameter * 0.81, height: diameter * 0.81)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.73, green: 1.0, blue: 0.88),
                                        accent,
                                        Color(red: 0.26, green: 0.78, blue: 0.75)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: diameter * 0.035
                            )
                    }
                    .shadow(color: accent.opacity(0.34), radius: diameter * 0.075)
                    .shadow(color: accent.opacity(0.16), radius: diameter * 0.15)

                Image("WhatGlyph")
                    .resizable()
                    .scaledToFit()
                    .frame(width: diameter * 0.84, height: diameter * 0.84)
                    .accessibilityHidden(true)
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
        }
        .buttonStyle(QuickRecordButtonStyle())
        .accessibilityLabel(isRussian ? "Начать запись" : "Start recording")
        .accessibilityHint(isRussian
            ? "Откроет запись и сразу включит микрофон"
            : "Opens the recorder and immediately activates the microphone")
    }

    private var libraryButton: some View {
        Button(action: openLibrary) {
            HStack(spacing: 15) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 21))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(accent)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 4) {
                    Text(isRussian ? "Мои записи" : "My recordings")
                        .font(.system(size: 19, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white)

                    Text(isRussian
                        ? "\(recordingsCount) сохранено"
                        : "\(recordingsCount) saved")
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.56))
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(compactLayout ? 11 : 14)
            .frame(maxWidth: .infinity)
            .background(
                Color.white.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 23, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRussian
            ? "Мои записи, \(recordingsCount)"
            : "My recordings, \(recordingsCount)")
        .accessibilityHint(isRussian
            ? "Открыть сохранённые заметки"
            : "Open saved voice notes")
    }
}

private struct QuickRecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    QuickCaptureHomeView(
        recordingsCount: 17,
        startRecording: {},
        openLibrary: {}
    )
}
