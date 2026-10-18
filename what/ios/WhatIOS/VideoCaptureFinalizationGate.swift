import Foundation

/// MOV export may only begin after AVCaptureMovieFileOutput has closed EVERY
/// segment it started. This prevents saving a playable prefix when a switch
/// or scene background races with the final recording delegate callback.
enum VideoCaptureFinalizationGate {
    static func canCompose(startedSegments: Int, finalizedSegments: Int,
                           writerIsRecording: Bool) -> Bool {
        startedSegments > 0 && finalizedSegments == startedSegments && !writerIsRecording
    }
}
