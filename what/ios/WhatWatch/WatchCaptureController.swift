import AVFoundation
import Combine
import Foundation
import WatchConnectivity
import WatchKit

final class WatchCaptureController: NSObject, ObservableObject, AVAudioRecorderDelegate, WCSessionDelegate {
    enum CaptureState: Equatable {
        case idle
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
    private var scheduledIDs = Set<UUID>()
    private var recorder: AVAudioRecorder?
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
        pendingCount = queue.count
    }

    func activateConnectivity() {
        guard WCSession.isSupported(), !activated else {
            pumpTransfers()
            return
        }

        activated = true
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func startCapture() {
        guard recorder == nil else { return }

        let audioApplication = AVAudioApplication.shared
        switch audioApplication.recordPermission {
        case .granted:
            beginRecording()
        case .denied:
            state = .error("Microphone access is off.")
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginRecording()
                    } else {
                        self?.state = .error("Microphone access is off.")
                    }
                }
            }
        @unknown default:
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

        let envelope = RecordingEnvelope(
            id: id,
            createdAt: createdAt,
            duration: duration,
            fileName: "\(id.uuidString).m4a"
        )

        do {
            try enqueue(envelope)
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
            activeRecordingID = id
            activeCreatedAt = createdAt
            state = .recording(createdAt)
            WKInterfaceDevice.current().play(.start)
        } catch {
            failRecordingStart(error, fileURL: url)
        }
    }

    private func failRecordingStart(_ error: Error, fileURL: URL) {
        try? fileManager.removeItem(at: fileURL)
        let message = (error as NSError).localizedDescription
        print("What? recording start failed: \(error)")
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
        scheduledIDs.remove(id)

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
        pumpTransfers()
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

        for recording in queueSnapshot() {
            queueLock.lock()
            let alreadyScheduled = scheduledIDs.contains(recording.id)
            queueLock.unlock()

            guard !alreadyScheduled, !outstanding.contains(recording.id) else { continue }

            let url = outboundDirectory.appendingPathComponent(recording.fileName)
            guard fileManager.fileExists(atPath: url.path) else { continue }

            session.transferFile(url, metadata: [
                TransferMetadataKey.type: TransferMetadataKey.recording,
                TransferMetadataKey.id: recording.id.uuidString,
                TransferMetadataKey.createdAt: recording.createdAt.timeIntervalSince1970,
                TransferMetadataKey.duration: recording.duration
            ])

            queueLock.lock()
            scheduledIDs.insert(recording.id)
            queueLock.unlock()
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if activationState == .activated {
            pumpTransfers()
        }
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

        if error != nil {
            queueLock.lock()
            scheduledIDs.remove(id)
            queueLock.unlock()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.pumpTransfers()
            }
        }
        // Success stays scheduled until the phone confirms durable storage.
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        self.recorder = nil
        activeRecordingID = nil
        activeCreatedAt = nil
        state = .error("The recording stopped unexpectedly.")
        WKInterfaceDevice.current().play(.failure)
    }
}
