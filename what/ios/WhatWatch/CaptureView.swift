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
            controller.refreshPendingAudioAfterUnlock()
#if WATCH_PHYSICAL_QA
            WatchPhysicalQAProbe.shared.startIfRequested(controller: controller)
            WatchPhysicalQAProbe.shared.observeLifecycle("view-appear", state: controller.state)
#endif
            if scenePhase == .active {
                startCaptureOnForeground()
            }
        }
        .onChange(of: scenePhase) { _, phase in
#if WATCH_PHYSICAL_QA
            WatchPhysicalQAProbe.shared.observeLifecycle("phase-" + String(describing: phase), state: controller.state)
#endif
            switch phase {
            case .active:
                controller.refreshPendingAudioAfterUnlock()
                // Some physical Watch faces launch the app without forwarding
                // the complication's widgetURL. Foreground arrival must itself
                // start recording, including after a previous capture was saved.
                startCaptureOnForeground()
            case .background:
                // Digital Crown / app switch: finalize audio before watchOS
                // suspends the app, even if the user never pressed Stop.
                controller.finishCaptureWhenBackgrounded()
            default:
                break
            }
        }
        .onOpenURL { url in
            guard url.scheme == WatchCaptureRouting.scheme, url.host == WatchCaptureRouting.captureURL.host else { return }
            // Keep deep-link support; startCapture is idempotent while preparing
            // or recording, so foreground + URL never starts two recordings.
            controller.startCapture()
        }
    }

    private func startCaptureOnForeground() {
#if WATCH_PHYSICAL_QA
        // The diagnostic executable never silently opens the microphone when
        // an automation merely relaunches it to inspect a completed ACK.
        // The explicit QA probe owns startCapture for its opt-in test modes.
        return
#else
        guard WatchCaptureLaunchPolicy.shouldAutoStart(controller.state) else { return }
        controller.startCapture()
#endif
    }

    private func elapsed(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
