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
    private var lastRecoveryRequestAt = Date.distantPast
    private let recoveryRequestCooldown: TimeInterval = 60

    /// Persistently asks the Watch to re-pump its own durable queue after
    /// either side restarts. No audio or Watch storage is modified here.
    /// One outstanding request is kept at most; the system delivers it
    /// when the paired Watch becomes available again.
    func requestWatchQueueRecovery() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled,
              Date().timeIntervalSince(lastRecoveryRequestAt) >= recoveryRequestCooldown
        else { return }
        let pending = session.outstandingUserInfoTransfers.contains {
            $0.userInfo[TransferMetadataKey.type] as? String
                == TransferMetadataKey.syncRequest
        }
        guard !pending else { return }
        lastRecoveryRequestAt = Date()
        session.transferUserInfo([
            TransferMetadataKey.type: TransferMetadataKey.syncRequest
        ])
    }

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported(), !activated else { return }
        activated = true
        let session = WCSession.default
        session.delegate = self
#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("phone-session-activate-request")
#endif
        session.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("phone-session-activation", note: "state=\(activationState.rawValue),hasError=\(error != nil)")
        Task { @MainActor in PhoneWakeEnvironmentQA.snapshot("wc-session-activation") }
#endif
        guard activationState == .activated else { return }
        receiveQueueSnapshot(session.receivedApplicationContext)
        DispatchQueue.main.async { [weak self] in
            self?.requestWatchQueueRecovery()
        }
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
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-live-received", id: payload.recording.id)
#endif
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
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-live-committed", id: outcome.id)
#endif

            // Fast ACK clears the Watch queue. A background ACK protects against
            // a lost reply or Watch suspension just after the write.
            session.transferUserInfo([
                TransferMetadataKey.type: TransferMetadataKey.acknowledgement,
                TransferMetadataKey.id: outcome.id.uuidString
            ])
            replyHandler(try ImmediateRecordingReply(
                acknowledgedID: outcome.id
            ).encode())
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-live-ack-replied", id: outcome.id)
#endif
            if case .stored(let recording) = outcome {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .whatRecordingReceived,
                        object: recording.id
                    )
                }
            }
        } catch {
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-live-error-no-ack")
#endif
            // No reply means no durable ACK. The Watch retains its audio and
            // WatchConnectivity's background file transfer remains queued.
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
#if WATCH_ROUTE_QA
        let receivedID = (file.metadata?[TransferMetadataKey.id] as? String).flatMap(UUID.init(uuidString:))
        WatchRouteQATrace.add("phone-file-received", id: receivedID)
#endif
        do {
            guard let outcome = try WatchInboundFileReceiver.accept(
                file.fileURL, metadata: file.metadata, into: repository
            ) else { return }
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-file-committed", id: outcome.id)
#endif
            // Already-deleted UUIDs are acknowledged too, so Watch can clear its queue.
            session.transferUserInfo([
                TransferMetadataKey.type: TransferMetadataKey.acknowledgement,
                TransferMetadataKey.id: outcome.id.uuidString
            ])
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-file-ack-queued", id: outcome.id)
#endif
            if case .stored(let recording) = outcome {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .whatRecordingReceived, object: recording.id)
                }
            }
        } catch {
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("phone-file-error-no-ack")
#endif
            // No ACK: the Watch keeps its durable local copy and can retry later.
        }
    }
}

extension Notification.Name {
    static let whatRecordingReceived = Notification.Name("what.recording.received")
    static let whatWatchQueueStatusReceived = Notification.Name("what.watch.queue.updated")
}
