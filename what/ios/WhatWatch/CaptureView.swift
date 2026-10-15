import SwiftUI

struct CaptureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var controller: WatchCaptureController

    var body: some View {
        VStack(spacing: 12) {
            switch controller.state {
            case .preparing:
                ProgressView(CaptureBrand.text("Включаем микрофон…", "Preparing microphone…"))
                    .font(.headline)
                    .multilineTextAlignment(.center)

            case .recording(let startedAt):
                TimelineView(.periodic(from: startedAt, by: 1)) { context in
                    Text(elapsed(from: startedAt, to: context.date))
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                }

                Button {
                    controller.stopCapture()
                } label: {
                    Label(CaptureBrand.text("Стоп", "Stop"), systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

            case .saved:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42))
                Text(CaptureBrand.text("Сохранено", "Saved"))
                    .font(.headline)

            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Button(CaptureBrand.text("Повторить", "Try again")) {
                    controller.startCapture()
                }

            case .idle:
                Button {
                    controller.startCapture()
                } label: {
                    VStack(spacing: 6) {
                        Image("WhatGlyph")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                            .accessibilityHidden(true)
                        Text(CaptureBrand.text("Записать", "Record"))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 78)
                }
                .buttonStyle(.borderedProminent)
            }

            if controller.pendingCount > 0 {
                Label(CaptureBrand.text("Ожидают iPhone: \(controller.pendingCount)", "\(controller.pendingCount) waiting for iPhone"), systemImage: "iphone.and.arrow.forward")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .tint(Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255))
        .onAppear {
            controller.activateConnectivity()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                // Digital Crown / app switch: finalize audio before watchOS
                // suspends the app, even if the user never pressed Stop.
                controller.finishCaptureWhenBackgrounded()
            }
        }
        .onOpenURL { url in
            guard url.scheme == "what", url.host == "capture" else { return }
            controller.startCapture()
        }
    }

    private func elapsed(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
