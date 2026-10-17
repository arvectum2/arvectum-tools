// The Watch-face complication's deep link is not guaranteed to reach the
// Watch app on physical devices. A foreground activation is sufficient user
// intent to start a fresh voice note, except while an existing capture or an
// actionable error is already being shown.
enum WatchCaptureLaunchPolicy {
    static func shouldAutoStart(_ state: WatchCaptureController.CaptureState) -> Bool {
        switch state {
        case .idle, .saved:
            return true
        case .preparing, .recording, .error:
            return false
        }
    }
}
