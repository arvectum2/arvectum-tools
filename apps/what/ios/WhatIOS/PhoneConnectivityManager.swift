import Foundation
import WatchConnectivity

final class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager()

    private let repository = RecordingRepository()
    private var activated = false

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported(), !activated else { return }
        activated = true
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard file.metadata?[TransferMetadataKey.type] as? String == TransferMetadataKey.recording else {
            return
        }

        do {
            let recording = try repository.acceptTemporaryFile(file.fileURL, metadata: file.metadata ?? [:])
            session.transferUserInfo([
                TransferMetadataKey.type: TransferMetadataKey.acknowledgement,
                TransferMetadataKey.id: recording.id.uuidString
            ])
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .whatRecordingReceived, object: recording.id)
            }
        } catch {
            // No ACK: the Watch keeps its durable local copy and can retry later.
        }
    }
}

extension Notification.Name {
    static let whatRecordingReceived = Notification.Name("what.recording.received")
}
