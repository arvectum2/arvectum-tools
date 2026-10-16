import Foundation

/// A camera switch closes the current clip before a new one starts. Stop or
/// Discard always wins over a pending switch, so the user's original video
/// cannot be silently lost to a late camera reconfiguration.
struct VideoCaptureTransition {
    enum Intent: Equatable {
        case recording
        case switchCamera
        case finish
        case discard
    }

    private(set) var intent: Intent = .recording

    mutating func requestSwitch(isRecording: Bool) -> Bool {
        guard isRecording && intent == .recording else { return false }
        intent = .switchCamera
        return true
    }

    mutating func requestStop(discard: Bool) {
        if discard {
            intent = .discard
        } else if intent != .discard {
            intent = .finish
        }
    }

    mutating func didStartNextClip() {
        if intent == .switchCamera { intent = .recording }
    }

    var shouldSwitchAfterClip: Bool { intent == .switchCamera }
    var shouldDiscard: Bool { intent == .discard }
    var isStopping: Bool { intent == .finish || intent == .discard }
}
