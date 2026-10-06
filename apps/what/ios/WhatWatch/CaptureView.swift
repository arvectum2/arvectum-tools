import SwiftUI

struct CaptureView: View {
    @StateObject private var controller = WatchCaptureController()

    var body: some View {
        VStack(spacing: 12) {
            switch controller.state {
            case .recording(let startedAt):
                TimelineView(.periodic(from: startedAt, by: 1)) { context in
                    Text(elapsed(from: startedAt, to: context.date))
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                }

                Button {
                    controller.stopCapture()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

            case .saved:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42))
                Text("Saved")
                    .font(.headline)

            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Button("Try again") {
                    controller.startCapture()
                }

            case .idle:
                Button {
                    controller.startCapture()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 34))
                        Text("Record")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 78)
                }
                .buttonStyle(.borderedProminent)
            }

            if controller.pendingCount > 0 {
                Label("\(controller.pendingCount) waiting for iPhone", systemImage: "iphone.and.arrow.forward")
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
