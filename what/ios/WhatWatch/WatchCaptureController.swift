import AVFoundation
import Combine
import Foundation
import WatchConnectivity
import WatchKit

final class WatchCaptureController: NSObject, ObservableObject, AVAudioRecorderDelegate, WCSessionDelegate {
    enum CaptureState: Equatable {
        case idle
        case preparing
        case recording(Date)
        case saved
        case error(String)
    }

    @Published private(set) var state: CaptureState = .idle
    @Published private(set) var pendingCount: Int = 0

    private let fileManager = FileManager.default
    private let queueLock = NSLock()
    private let outboundDirectory: URL
    private let queueIndexURL: URL

    private var queue: [RecordingEnvelope] = []
    static let shared = WatchCaptureController()

    // Protected by queueLock along with the durable outbound queue.
    private var retryPolicy = WatchTransferRetryPolicy()
    private var immediateAttempts = [UUID: Date]()
    private let immediateRetryInterval: TimeInterval = 20

    private var recorder: AVAudioRecorder?
    private var isStarting = false
    // Invalidates pending microphone-activation callbacks after leaving the app.
    private var captureGeneration = 0
    private var captureRequestedAt: TimeInterval?
    private var activeRecordingID: UUID?
    private var activeCreatedAt: Date?
    private var activated = false

#if WATCH_PHYSICAL_QA
    // An app-local transport pause for physical durability tests. It does NOT
    // change the radio, Watch pairing, WCSession or any non-QA build.
    private let qaTransportLock = NSLock()
    private var qaTransportHeld = false
    private var qaHeldAcknowledgementID: UUID?
    private var qaSuppressedAcknowledgementCount = 0

    /// QA-only simulation of a lost reply AND lost durable UserInfo ACK.
    /// The production queue, file, pairing and system radios are unchanged.
    func qaHoldAcknowledgements(for id: UUID) {
        qaTransportLock.lock()
        qaHeldAcknowledgementID = id
        qaSuppressedAcknowledgementCount = 0
        qaTransportLock.unlock()
    }

    /// Never leave a QA transport filter active indefinitely if the receiver
    /// is unreachable. Clearing the filter does NOT delete source files.
    func qaReleaseAcknowledgementHoldForSafety(for id: UUID) {
        qaTransportLock.lock()
        if qaHeldAcknowledgementID == id {
            qaHeldAcknowledgementID = nil
            qaSuppressedAcknowledgementCount = 0
        }
        qaTransportLock.unlock()
        pumpTransfers()
    }

    func qaDroppedAcknowledgements(for id: UUID) -> Int {
        qaTransportLock.lock()
        defer { qaTransportLock.unlock() }
        guard qaHeldAcknowledgementID == id else { return 0 }
        return qaSuppressedAcknowledgementCount
    }

    private func qaShouldDropAcknowledgement(for id: UUID) -> Bool {
        qaTransportLock.lock()
        defer { qaTransportLock.unlock() }
        guard qaHeldAcknowledgementID == id else { return false }
        qaSuppressedAcknowledgementCount += 1
        return true
    }

    /// The first delivery must have been durably ACKed by iPhone (then
    /// deliberately ignored here). Re-send the SAME UUID through the ordinary
    /// background WCSession path only after lifting the QA ACK filter.
    /// Does not modify the retry policy or bypass receiver validation.
    @discardableResult
    func qaResendAfterDroppedACK(for id: UUID) -> Bool {
        qaTransportLock.lock()
        guard qaHeldAcknowledgementID == id,
              qaSuppressedAcknowledgementCount > 0 else {
            qaTransportLock.unlock()
            return false
        }
        qaTransportLock.unlock()

        guard let original = queueSnapshot().first(where: { $0.id == id }) else {
            return false
        }
        let source = outboundDirectory.appendingPathComponent(original.fileName)
        guard fileManager.fileExists(atPath: source.path), WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return false }

        qaTransportLock.lock()
        // Restore normal ACK handling BEFORE the duplicate is sent.
        qaHeldAcknowledgementID = nil
        qaSuppressedAcknowledgementCount = 0
        qaTransportLock.unlock()
        WCSession.default.transferFile(source, metadata: [
            TransferMetadataKey.type: TransferMetadataKey.recording,
            TransferMetadataKey.id: original.id.uuidString,
            TransferMetadataKey.createdAt: original.createdAt.timeIntervalSince1970,
            TransferMetadataKey.duration: original.duration
        ])
        return true
    }

    /// Generate an audible AAC using deterministic PCM entirely on Watch.
    /// Exercises the actual durable queue and WCSession background transport,
    /// without requesting microphone access or touching any user recording.
    /// This method exists only in the isolated WATCH_PHYSICAL_QA target.
    func qaEnqueueSyntheticAAC() throws -> UUID {
        let id = UUID()
        let url = outboundDirectory.appendingPathComponent(id.uuidString + ".m4a")
        let createdAt = Date()
        do {
            guard let format = AVAudioFormat(
                standardFormatWithSampleRate: 16_000, channels: 1
            ) else { throw CocoaError(.fileWriteUnknown) }
            // Release encoder before probing AAC duration.
            do {
                let writer = try AVAudioFile(
                    forWriting: url,
                    settings: [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: 16_000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderBitRateKey: 48_000
                    ],
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
                for frame in 0..<60 {
                    guard let buffer = AVAudioPCMBuffer(
                        pcmFormat: format, frameCapacity: 1_024
                    ), let samples = buffer.floatChannelData else {
                        throw CocoaError(.fileWriteUnknown)
                    }
                    buffer.frameLength = 1_024
                    for offset in 0..<1_024 {
                        samples[0][offset] =
                            0.05 * sin(Float((frame * 1_024 + offset) % 32)
                                       * Float.pi / 16)
                    }
                    try writer.write(from: buffer)
                }
            }
            guard let player = try? AVAudioPlayer(contentsOf: url),
                  let bytes = try? url.resourceValues(
                    forKeys: [.fileSizeKey]
                  ).fileSize,
                  WatchCaptureValidation.isPlausibleAudio(
                    bytes: bytes, decodedDuration: player.duration,
                    expectedDuration: 60.0 * 1024.0 / 16_000.0
                  ) else { throw CocoaError(.fileWriteUnknown) }
            let envelope = RecordingEnvelope(
                id: id, createdAt: createdAt,
                duration: player.duration, fileName: id.uuidString + ".m4a"
            )
            try enqueue(envelope)
            publishQueueStatus()
            pumpTransfers()
            return id
        } catch {
            // Preserve even a partially created source for examination.
            // No queue index was mutated if encoding itself failed.
            throw error
        }
    }

    func qaSetTransportHeld(_ held: Bool) {
        qaTransportLock.lock()
        qaTransportHeld = held
        qaTransportLock.unlock()
        if !held { pumpTransfers() }
    }

    private var qaIsTransportHeld: Bool {
        qaTransportLock.lock()
        defer { qaTransportLock.unlock() }
        return qaTransportHeld
    }
#endif

    override init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        outboundDirectory = documents.appendingPathComponent("WhatOutbound", isDirectory: true)
        queueIndexURL = outboundDirectory.appendingPathComponent("queue.json")
        super.init()

        try? fileManager.createDirectory(at: outboundDirectory, withIntermediateDirectories: true)
        // File protection may hide queue.json during locked-at-boot startup.
        // Never overwrite an unreadable queue with an empty orphan scan.
        if let restored = loadQueue() {
            queue = restored
            try? WatchAcknowledgementJournal.reconcile(
                queue: &queue, at: queueIndexURL, outbound: outboundDirectory,
                fileManager: fileManager
            )
            recoverUnqueuedAudioFiles()
        }
        pendingCount = queue.count
    }

    func activateConnectivity() {
        guard WCSession.isSupported(), !activated else {
            publishQueueStatus()
            pumpTransfers()
            return
        }

        activated = true
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func startCapture() {
        guard recorder == nil, !isStarting else { return }
        isStarting = true
        captureGeneration += 1
        let generation = captureGeneration
        captureRequestedAt = ProcessInfo.processInfo.systemUptime
        state = .preparing

        let audioApplication = AVAudioApplication.shared
        switch audioApplication.recordPermission {
        case .granted:
            beginRecording(generation: generation)
        case .denied:
            isStarting = false
            state = .error("Microphone access is off.")
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self, self.captureGeneration == generation,
                          self.isStarting else { return }
                    if granted {
                        self.beginRecording(generation: generation)
                    } else {
                        self.isStarting = false
                        self.state = .error("Microphone access is off.")
                    }
                }
            }
        @unknown default:
            isStarting = false
            state = .error("Microphone permission is unavailable.")
        }
    }

    func finishCaptureWhenBackgrounded() {
        if isStarting {
            captureGeneration += 1
            isStarting = false
            captureRequestedAt = nil
            state = .idle
        }
        if recorder != nil {
            stopCapture()
        }
    }

    func stopCapture() {
        guard let recorder, let id = activeRecordingID else { return }

        let duration = max(recorder.currentTime, 0)
        let createdAt = activeCreatedAt ?? Date()
        recorder.stop()
        self.recorder = nil
        activeRecordingID = nil
        activeCreatedAt = nil

        let audioURL = outboundDirectory.appendingPathComponent("\(id.uuidString).m4a")
        let actualDuration = (try? AVAudioPlayer(contentsOf: audioURL))?.duration ?? 0
        let fileSize = (try? audioURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard WatchCaptureValidation.isPlausibleAudio(
            bytes: fileSize,
            decodedDuration: actualDuration,
            expectedDuration: duration
        ) else {
            // Keep the original file for investigation and possible recovery.
            // Never claim Saved or enqueue a header-only AAC recording.
            state = .error("Recording audio was incomplete. Try again.")
            WKInterfaceDevice.current().play(.failure)
            return
        }

        let envelope = RecordingEnvelope(
            id: id,
            createdAt: createdAt,
            duration: actualDuration,
            fileName: "\(id.uuidString).m4a"
        )

        do {
            try enqueue(envelope)
            publishQueueStatus()
            state = .saved
            WKInterfaceDevice.current().play(.success)
            pumpTransfers()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard self?.state == .saved else { return }
                self?.state = .idle
            }
        } catch {
            state = .error("The recording could not be saved.")
            WKInterfaceDevice.current().play(.failure)
        }
    }

    private func beginRecording(generation: Int) {
        guard isStarting, captureGeneration == generation else { return }
        let id = UUID()
        let createdAt = Date()
        let url = outboundDirectory.appendingPathComponent("\(id.uuidString).m4a")
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
        } catch {
            failRecordingStart(error, fileURL: url)
            return
        }

        audioSession.activate { [weak self] activated, error in
            DispatchQueue.main.async {
                guard let self, self.captureGeneration == generation,
                      self.isStarting else { return }

                guard activated else {
                    self.failRecordingStart(
                        error ?? CocoaError(.featureUnsupported),
                        fileURL: url
                    )
                    return
                }

                self.startRecorder(id: id, createdAt: createdAt, url: url)
            }
        }
    }

    private func startRecorder(id: UUID, createdAt: Date, url: URL) {
        do {
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.prepareToRecord()

            guard recorder.record() else {
                throw CocoaError(.fileWriteUnknown)
            }

            self.recorder = recorder
            if let startTime = captureRequestedAt {
                CaptureLatency.record(startedAt: startTime, source: "watch")
            }
            captureRequestedAt = nil
            isStarting = false
            activeRecordingID = id
            activeCreatedAt = createdAt
            state = .recording(createdAt)
            WKInterfaceDevice.current().play(.start)
        } catch {
            failRecordingStart(error, fileURL: url)
        }
    }

    private func failRecordingStart(_ error: Error, fileURL: URL) {
        captureRequestedAt = nil
        isStarting = false
        // A failed prepare has no finalized audio. Deleting its scratch file
        // is safe; never delete an audio file that already reached recording.
        try? fileManager.removeItem(at: fileURL)
        let message = (error as NSError).localizedDescription
        ArvectumDiagnostics.failure(
            subsystem: "ru.arvectum.tools.what.watch",
            category: "capture", operation: "start", code: "recorder-start-failed"
        )
        state = .error("Start failed: \(message)")
        WKInterfaceDevice.current().play(.failure)
    }

    private func enqueue(_ recording: RecordingEnvelope) throws {
        queueLock.lock()
        defer { queueLock.unlock() }

        try WatchDurableQueue.enqueue(
            recording, into: &queue, at: queueIndexURL
        )
#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("watch-queue-committed", id: recording.id)
#endif
        publishPendingCount(queue.count)
    }

    private func acknowledge(_ id: UUID) {
#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("watch-ack-callback", id: id)
#endif
#if WATCH_PHYSICAL_QA
        guard !qaShouldDropAcknowledgement(for: id) else { return }
#endif
        queueLock.lock()
        do {
            // Keep both the in-memory queue and the original AAC intact if
            // the atomic queue index write fails (e.g. disk is full).
            if try WatchAcknowledgementJournal.acknowledge(
                id, in: &queue, at: queueIndexURL,
                outbound: outboundDirectory, fileManager: fileManager
            ) {
                retryPolicy.didAcknowledge(id)
                immediateAttempts.removeValue(forKey: id)
#if WATCH_ROUTE_QA
                WatchRouteQATrace.add("watch-ack-index-committed", id: id)
#endif
            }
        } catch {
            ArvectumDiagnostics.failure(
                subsystem: "ru.arvectum.tools.what.watch",
                category: "transfer", operation: "acknowledge",
                code: "queue-index-commit-failed"
            )
        }
        let count = queue.count
        queueLock.unlock()
        publishPendingCount(count)
        publishQueueStatus()
        pumpTransfers()
    }

    private func publishQueueStatus() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let snapshot = WatchQueueSnapshot(
            pendingCount: queueSnapshot().count,
            updatedAt: Date()
        )
        // Last-value-wins background snapshot. Never use this for audio or ACKs.
        try? session.updateApplicationContext(snapshot.context)
    }

    private func queueSnapshot() -> [RecordingEnvelope] {
        queueLock.lock()
        defer { queueLock.unlock() }
        return queue
    }

    private func loadQueue() -> [RecordingEnvelope]? {
        guard fileManager.fileExists(atPath: queueIndexURL.path) else { return [] }
        guard let data = try? Data(contentsOf: queueIndexURL),
              let decoded = try? JSONDecoder().decode([RecordingEnvelope].self, from: data)
        else { return nil }
        return decoded
    }

    /// Crash recovery: if audio finished but the process died before updating
    /// queue.json, recover the original UUID and retry delivery. Invalid or
    /// unfinished AAC is left untouched, never silently deleted.
    private func recoverUnqueuedAudioFiles() {
        let recovered = WatchQueueRecovery.recover(
            from: outboundDirectory,
            knownIDs: Set(queue.map(\.id)).union(
                WatchAcknowledgementJournal.pendingIDs(
                    in: outboundDirectory, fileManager: fileManager
                )
            ),
            fileManager: fileManager,
            decodedDuration: { url in
                (try? AVAudioPlayer(contentsOf: url))?.duration
            }
        )
        guard !recovered.isEmpty else { return }
        do {
            try WatchDurableQueue.recover(
                recovered, into: &queue, at: queueIndexURL
            )
            ArvectumDiagnostics.failure(
                subsystem: "ru.arvectum.tools.what.watch",
                category: "capture", operation: "recover",
                code: "recovered-unindexed-audio"
            )
        } catch {
            // Never delete recovered audio; scan again on next app launch.
        }
    }

    /// Re-read the queue after the user unlocks Watch following a reboot.
    /// File protection can make the initial index/audio scan in init fail.
    /// An unreadable existing index is NEVER replaced with an empty queue.
    func refreshPendingAudioAfterUnlock() {
        queueLock.lock()
        if fileManager.fileExists(atPath: queueIndexURL.path) {
            guard let index = try? Data(contentsOf: queueIndexURL),
                  let diskEntries = try? JSONDecoder().decode(
                    [RecordingEnvelope].self, from: index
                  )
            else {
                queueLock.unlock()
                ArvectumDiagnostics.failure(
                    subsystem: "ru.arvectum.tools.what.watch",
                    category: "transfer", operation: "refresh",
                    code: "queue-index-temporarily-unavailable"
                )
                return
            }
            queue = WatchDurableQueue.mergeRestored(disk: diskEntries, memory: queue)
        }
        do {
            try WatchAcknowledgementJournal.reconcile(
                queue: &queue, at: queueIndexURL, outbound: outboundDirectory,
                fileManager: fileManager
            )
        } catch {
            // Keep originals and markers for the next unlock/relaunch.
            ArvectumDiagnostics.failure(
                subsystem: "ru.arvectum.tools.what.watch",
                category: "transfer", operation: "refresh",
                code: "acknowledgement-reconcile-failed"
            )
        }

        let recovered = WatchQueueRecovery.recover(
            from: outboundDirectory,
            knownIDs: Set(queue.map(\.id)).union(
                WatchAcknowledgementJournal.pendingIDs(
                    in: outboundDirectory, fileManager: fileManager
                )
            ),
            fileManager: fileManager,
            decodedDuration: { url in
                (try? AVAudioPlayer(contentsOf: url))?.duration
            }
        )
        if !recovered.isEmpty {
            do {
                try WatchDurableQueue.recover(
                    recovered, into: &queue, at: queueIndexURL
                )
            } catch {
                // Keep source audio. Retry on next foreground/session activation.
            }
        }
        let count = queue.count
        queueLock.unlock()
        publishPendingCount(count)
        publishQueueStatus()
        pumpTransfers()
    }

    private func publishPendingCount(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.pendingCount = count
        }
    }

    private func pumpTransfers() {
#if WATCH_PHYSICAL_QA
        guard !qaIsTransportHeld else {
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("watch-pump-held-qa")
#endif
            return
        }
#endif
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("watch-pump-no-activation")
#endif
            return
        }

        let outstanding = Set(session.outstandingFileTransfers.compactMap {
            ($0.file.metadata?[TransferMetadataKey.id] as? String).flatMap(UUID.init(uuidString:))
        })

        queueLock.lock()
        defer { queueLock.unlock() }

        let now = Date()
        for recording in queue {
            let url = outboundDirectory.appendingPathComponent(recording.fileName)
            guard fileManager.fileExists(atPath: url.path) else { continue }

            // The foreground Watch app can wake an iPhone app via live messaging.
            // Keep transferFile as a background fallback even if live delivery fails.
            if session.isReachable,
               (immediateAttempts[recording.id] ?? .distantPast)
                    .addingTimeInterval(immediateRetryInterval) <= now,
               let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               size > 0, size <= ImmediateRecordingPayload.maximumAudioBytes,
               let audio = try? Data(contentsOf: url),
               let encoded = try? ImmediateRecordingPayload(
                    recording: recording, audio: audio
               ).encode() {
                immediateAttempts[recording.id] = now
#if WATCH_ROUTE_QA
                WatchRouteQATrace.add("watch-live-send-attempt", id: recording.id,
                                      note: "reachable=true")
#endif
                session.sendMessageData(encoded, replyHandler: { [weak self] response in
#if WATCH_ROUTE_QA
                    WatchRouteQATrace.add("watch-live-reply", id: recording.id)
#endif
                    guard let reply = try? ImmediateRecordingReply.decode(response),
                          reply.acknowledgedID == recording.id else { return }
                    self?.acknowledge(recording.id)
                }, errorHandler: { _ in
#if WATCH_ROUTE_QA
                    WatchRouteQATrace.add("watch-live-error", id: recording.id)
#endif
                    // Keep the queue and allow a live retry on the next pump.
                    // Already-queued file transfer is not cancelled.
                })
                // A lost reply must not leave an active Watch session waiting
                // indefinitely for the background file fallback.
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + immediateRetryInterval
                ) { [weak self] in
                    self?.pumpTransfers()
                }
            }

            guard retryPolicy.shouldSchedule(
                recording.id,
                isOutstanding: outstanding.contains(recording.id),
                at: now
            ) else { continue }

            // The queue remains on disk until the iPhone confirms durable storage.
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("watch-file-scheduled", id: recording.id,
                note: "reachable=\(session.isReachable),outstanding=\(outstanding.contains(recording.id))")
#endif
            session.transferFile(url, metadata: [
                TransferMetadataKey.type: TransferMetadataKey.recording,
                TransferMetadataKey.id: recording.id.uuidString,
                TransferMetadataKey.createdAt: recording.createdAt.timeIntervalSince1970,
                TransferMetadataKey.duration: recording.duration
            ])
            retryPolicy.didSchedule(recording.id, at: now)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("watch-session-activation",
            note: "state=\(activationState.rawValue),hasError=\(error != nil)")
#endif
        if activationState == .activated {
            refreshPendingAudioAfterUnlock()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("watch-reachability", note: "reachable=\(session.isReachable)")
#endif
        // Helps pending transfers resume quickly when both apps are already active.
        if session.isReachable { pumpTransfers() }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        switch userInfo[TransferMetadataKey.type] as? String {
        case TransferMetadataKey.syncRequest:
            // A newly unlocked Watch may have missed its first queue read.
            // The phone's durable request rehydrates and re-pumps without
            // creating a new note or discarding the original audio.
            refreshPendingAudioAfterUnlock()
        case TransferMetadataKey.acknowledgement:
            guard let idString = userInfo[TransferMetadataKey.id] as? String,
                  let id = UUID(uuidString: idString)
            else { return }
#if WATCH_ROUTE_QA
            WatchRouteQATrace.add("watch-userinfo-ack-received", id: id)
#endif
            acknowledge(id)
        default:
            break
        }
    }

    func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: Error?
    ) {
        guard
            let idString = fileTransfer.file.metadata?[TransferMetadataKey.id] as? String,
            let id = UUID(uuidString: idString)
        else {
            return
        }

#if WATCH_ROUTE_QA
        WatchRouteQATrace.add("watch-file-transfer-completion", id: id,
            note: error == nil ? "success" : "error")
#endif
        queueLock.lock()
        // A delayed file-transfer completion can race with a newer live ACK.
        // Once the durable queue no longer has this UUID, ignore stale retry
        // callbacks instead of recreating backoff state for a removed note.
        guard queue.contains(where: { $0.id == id }) else {
            queueLock.unlock()
            return
        }
        if error != nil {
            retryPolicy.didFail(id)
        } else {
            retryPolicy.didComplete(id, at: Date())
        }
        queueLock.unlock()

        // If transfer succeeded but ACK was lost, retry with the same UUID.
        // When suspended, reopening the Watch app invokes pumpTransfers instead.
        let delay: TimeInterval = error == nil
            ? WatchTransferRetryPolicy.acknowledgementGracePeriod : 2
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.pumpTransfers()
        }
    }

    func audioRecorderDidFinishRecording(
        _ finishedRecorder: AVAudioRecorder, successfully flag: Bool
    ) {
        // stopCapture() deliberately clears the active recorder. This delegate
        // callback means the recording ended without the user's Stop action.
        guard recorder === finishedRecorder,
              let id = activeRecordingID else { return }
        let url = outboundDirectory.appendingPathComponent("\(id.uuidString).m4a")
        let creationDate = activeCreatedAt ?? Date()
        recorder = nil
        activeRecordingID = nil
        activeCreatedAt = nil
        isStarting = false

        let duration = (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        if WatchCaptureValidation.isPlausibleAudio(
            bytes: bytes, decodedDuration: duration, expectedDuration: 0
        ) {
            do {
                try enqueue(RecordingEnvelope(
                    id: id, createdAt: creationDate,
                    duration: duration, fileName: url.lastPathComponent
                ))
                publishQueueStatus()
                pumpTransfers()
                state = .error("Recording was interrupted. The audio captured so far was saved.")
                WKInterfaceDevice.current().play(.success)
                return
            } catch {
                // UUID-named audio remains on disk for next-start recovery.
            }
        }
        state = .error("Recording stopped unexpectedly. Try again.")
        WKInterfaceDevice.current().play(.failure)
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        self.recorder = nil
        isStarting = false
        activeRecordingID = nil
        activeCreatedAt = nil
        state = .error("The recording stopped unexpectedly.")
        WKInterfaceDevice.current().play(.failure)
    }
}
