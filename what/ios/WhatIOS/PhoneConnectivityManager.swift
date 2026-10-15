import Foundation
import WatchConnectivity

final class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager()

    private let repository = RecordingRepository()
    private let watchQueueCache = WatchQueueStatusCache()

    var lastWatchQueueSnapshot: WatchQueueSnapshot? {
        watchQueueCache.latest
    }
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
    ) {
        guard activationState == .activated else { return }
        receiveQueueSnapshot(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        receiveQueueSnapshot(context)
    }

    private func receiveQueueSnapshot(_ context: [String: Any]) {
        guard let snapshot = WatchQueueSnapshot(context: context),
              watchQueueCache.accept(snapshot) else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .whatWatchQueueStatusReceived,
                object: nil
            )
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // A live message can wake the iOS app even when its UI is closed.
    // Reply ONLY after the audio is durably stored, never upon mere receipt.
    func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data,
        replyHandler: @escaping (Data) -> Void
    ) {
        do {
            let payload = try ImmediateRecordingPayload.decode(messageData)
            guard !payload.audio.isEmpty,
                  payload.audio.count <= ImmediateRecordingPayload.maximumAudioBytes,
                  payload.recording.duration.isFinite,
                  payload.recording.duration >= 0 else { return }

            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("what-live-\(UUID().uuidString).m4a")
            defer { try? FileManager.default.removeItem(at: temp) }
            try payload.audio.write(to: temp, options: .atomic)
            // Do not ACK unreadable or header-only audio. The Watch retains
            // the original and retries when the receiver is ready.
            try WatchDeliveredAudioValidation.validate(
                temp, expectedDuration: payload.recording.duration
            )
            let outcome = try repository.acceptTemporaryFile(
                temp, metadata: payload.metadata
            )

            // Fast ACK clears the Watch queue. A background ACK protects against
            // a lost reply or Watch suspension just after the write.
            session.transferUserInfo([
                TransferMetadataKey.type: TransferMetadataKey.acknowledgement,
                TransferMetadataKey.id: outcome.id.uuidString
            ])
            replyHandler(try ImmediateRecordingReply(
                acknowledgedID: outcome.id
            ).encode())
            if case .stored(let recording) = outcome {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .whatRecordingReceived,
                        object: recording.id
                    )
                }
            }
        } catch {
            // No reply means no durable ACK. The Watch retains its audio and
            // WatchConnectivity's background file transfer remains queued.
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard file.metadata?[TransferMetadataKey.type] as? String == TransferMetadataKey.recording,
              let expectedDuration = file.metadata?[TransferMetadataKey.duration] as? Double else {
            return
        }

        do {
            // WatchConnectivity marks transport delivery before checking
            // whether its original AAC is actually playable on iPhone.
            try WatchDeliveredAudioValidation.validate(
                file.fileURL, expectedDuration: expectedDuration
            )
            let outcome = try repository.acceptTemporaryFile(file.fileURL, metadata: file.metadata ?? [:])
            // Already-deleted UUIDs are acknowledged too, so Watch can clear its queue.
            session.transferUserInfo([
                TransferMetadataKey.type: TransferMetadataKey.acknowledgement,
                TransferMetadataKey.id: outcome.id.uuidString
            ])
            if case .stored(let recording) = outcome {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .whatRecordingReceived, object: recording.id)
                }
            }
        } catch {
            // No ACK: the Watch keeps its durable local copy and can retry later.
        }
    }
}

extension Notification.Name {
    static let whatRecordingReceived = Notification.Name("what.recording.received")
    static let whatWatchQueueStatusReceived = Notification.Name("what.watch.queue.updated")
}
