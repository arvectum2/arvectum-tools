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
    private var captureRequestedAt: TimeInterval?
    private var activeRecordingID: UUID?
    private var activeCreatedAt: Date?
    private var activated = false

    override init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        outboundDirectory = documents.appendingPathComponent("WhatOutbound", isDirectory: true)
        queueIndexURL = outboundDirectory.appendingPathComponent("queue.json")
        super.init()

        try? fileManager.createDirectory(at: outboundDirectory, withIntermediateDirectories: true)
        queue = loadQueue()
        recoverUnqueuedAudioFiles()
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
        captureRequestedAt = ProcessInfo.processInfo.systemUptime
        state = .preparing

        let audioApplication = AVAudioApplication.shared
        switch audioApplication.recordPermission {
        case .granted:
            beginRecording()
        case .denied:
            isStarting = false
            state = .error("Microphone access is off.")
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginRecording()
                    } else {
                        self?.isStarting = false
                        self?.state = .error("Microphone access is off.")
                    }
                }
            }
        @unknown default:
            isStarting = false
            state = .error("Microphone permission is unavailable.")
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

    private func beginRecording() {
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
                guard let self else { return }

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

        queue.removeAll { $0.id == recording.id }
        queue.append(recording)
        try persistQueueLocked()
        publishPendingCount(queue.count)
    }

    private func acknowledge(_ id: UUID) {
        queueLock.lock()
        let match = queue.first { $0.id == id }
        queue.removeAll { $0.id == id }
        retryPolicy.didAcknowledge(id)
        immediateAttempts.removeValue(forKey: id)

        do {
            try persistQueueLocked()
            if let match {
                try? fileManager.removeItem(at: outboundDirectory.appendingPathComponent(match.fileName))
            }
        } catch {
            if let match, !queue.contains(where: { $0.id == match.id }) {
                queue.append(match)
            }
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

    private func loadQueue() -> [RecordingEnvelope] {
        guard
            let data = try? Data(contentsOf: queueIndexURL),
            let decoded = try? JSONDecoder().decode([RecordingEnvelope].self, from: data)
        else {
            return []
        }
        return decoded
    }

    /// Crash recovery: if audio finished but the process died before updating
    /// queue.json, recover the original UUID and retry delivery. Invalid or
    /// unfinished AAC is left untouched, never silently deleted.
    private func recoverUnqueuedAudioFiles() {
        let recovered = WatchQueueRecovery.recover(
            from: outboundDirectory,
            knownIDs: Set(queue.map(\.id)),
            fileManager: fileManager,
            decodedDuration: { url in
                (try? AVAudioPlayer(contentsOf: url))?.duration
            }
        )
        guard !recovered.isEmpty else { return }
        queue.append(contentsOf: recovered)
        do {
            try persistQueueLocked()
            ArvectumDiagnostics.failure(
                subsystem: "ru.arvectum.tools.what.watch",
                category: "capture", operation: "recover",
                code: "recovered-unindexed-audio"
            )
        } catch {
            // Never delete recovered audio; scan again on next app launch.
        }
    }

    private func persistQueueLocked() throws {
        let data = try JSONEncoder().encode(queue)
        try data.write(to: queueIndexURL, options: .atomic)
    }

    private func publishPendingCount(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.pendingCount = count
        }
    }

    private func pumpTransfers() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else { return }

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
                session.sendMessageData(encoded, replyHandler: { [weak self] response in
                    guard let reply = try? ImmediateRecordingReply.decode(response),
                          reply.acknowledgedID == recording.id else { return }
                    self?.acknowledge(recording.id)
                }, errorHandler: { _ in
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
        if activationState == .activated {
            publishQueueStatus()
            pumpTransfers()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        // Helps pending transfers resume quickly when both apps are already active.
        if session.isReachable { pumpTransfers() }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard
            userInfo[TransferMetadataKey.type] as? String == TransferMetadataKey.acknowledgement,
            let idString = userInfo[TransferMetadataKey.id] as? String,
            let id = UUID(uuidString: idString)
        else {
            return
        }

        acknowledge(id)
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

        queueLock.lock()
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
