import AVFoundation
import Combine
import Foundation
import Speech
import UIKit
import UserNotifications

@MainActor
final class PhoneStore: NSObject, ObservableObject, AVAudioPlayerDelegate,
                        UNUserNotificationCenterDelegate {
    @Published private(set) var recordings: [RecordingEnvelope] = []
    @Published private(set) var localNotes: [LocalNote] = []
    @Published var videoRecoveryNotice: String?
    @Published var reminderTargetID: UUID?
    let reminderManager = NoteReminderManager()
    @Published private(set) var playingID: UUID?
    @Published private(set) var transcribingID: UUID?
    @Published private(set) var transcripts: [UUID: String] = [:]
    @Published private(set) var archivedIDs = Set<UUID>()
    @Published private(set) var lastWatchQueueSnapshot: WatchQueueSnapshot?
    @Published private(set) var batchTranscriptionActive = false
    @Published var showPhoneCapture = false
    @Published var showTextCapture = false
    @Published var showVideoCapture = false
    @Published var errorMessage: String?
    /// Persisted speech recognition locale only. iOS app language controls
    /// the interface separately; existing speech choices are preserved.
    @Published var transcriptionLocale = CaptureBrand.selectedTranscriptionLocale {
        didSet {
            UserDefaults.standard.set(transcriptionLocale, forKey: CaptureBrand.languagePreferenceKey)
        }
    }

    private let repository: RecordingRepository
    private let localNoteRepository: LocalNoteRepository
    private var player: AVAudioPlayer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    /// Also guards against stale callbacks after immediate retry of same UUID.
    private var speechAttempt = SpeechAttemptGate()
    private var batchIDs: [UUID] = []
    let phoneRecorder = PhoneRecordingController()

    init(repository: RecordingRepository = RecordingRepository(),
         localNoteRepository: LocalNoteRepository = LocalNoteRepository()) {
        self.repository = repository
        self.localNoteRepository = localNoteRepository
        super.init()
        UNUserNotificationCenter.current().delegate = self
        reload()
#if DEBUG
        seedDesignLibraryForUITestsIfRequested()
#endif
        reloadWatchQueueStatus()
        Task { [weak self] in await self?.reminderManager.reconcile() }
        Task { [weak self] in
            guard let self else { return }
            let candidates: [(id: UUID, createdAt: Date)] = self.recordings.map {
                (id: $0.id, createdAt: $0.createdAt)
            } + self.localNotes.map { (id: $0.id, createdAt: $0.createdAt) }
            await self.reminderManager.catchUpNewNotes(candidates)
        }
        Task { [weak self] in await self?.recoverInterruptedVideos() }
        phoneRecorder.onSaved = { [weak self] recording in
            guard let self else { return }
            let alreadyIndexed = self.recordings.contains { $0.id == recording.id }
            self.reload()
            if !alreadyIndexed {
                Task { await self.reminderManager.scheduleAutomaticallyIfEnabled(noteID: recording.id) }
            }
            self.transcribeIfAuthorized(recording)
        }
    }

#if DEBUG
    /// Synthetic metadata visible only to disposable simulator UI tests.
    /// Never writes notes, files, archive states, or Watch recordings.
    private func seedDesignLibraryForUITestsIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--qa-design-filled-library") ||
              args.contains("--qa-aso-filled-library") else { return }

        // Native App Store fixture: localized example TEXT only.
        // In-memory data, no fake audio or files; DEBUG-only.
        if args.contains("--qa-aso-filled-library") {
            let language = CaptureBrand.resolvedInterfaceLanguage(
                for: Locale.preferredLanguages)
            let texts: [String]
            switch language {
            case "ru": texts = [
                "Подготовить вопросы к встрече",
                "Проверить идеи для нового проекта"
            ]
            case "es": texts = [
                "Preparar preguntas para la reunión",
                "Revisar ideas para un nuevo proyecto"
            ]
            case "fr": texts = [
                "Préparer des questions pour la réunion",
                "Revoir les idées pour un nouveau projet"
            ]
            case "de": texts = [
                "Fragen für das Treffen vorbereiten",
                "Ideen für ein neues Projekt prüfen"
            ]
            case "it": texts = [
                "Preparare le domande per la riunione",
                "Rivedere le idee per un nuovo progetto"
            ]
            case "ja": texts = [
                "会議で聞くことを整理する",
                "新しい企画のアイデアを確認する"
            ]
            case "ko": texts = [
                "회의에서 할 질문 준비하기",
                "새 프로젝트 아이디어 검토하기"
            ]
            case "pt-PT": texts = [
                "Preparar perguntas para a reunião",
                "Rever ideias para um novo projeto"
            ]
            case "pt": texts = [
                "Preparar perguntas para a reunião",
                "Revisar ideias para um novo projeto"
            ]
            case "zh-Hant": texts = [
                "準備會議要問的問題",
                "整理新專案的想法"
            ]
            case "zh": texts = [
                "准备会议要问的问题",
                "整理新项目的想法"
            ]
            default: texts = [
                "Prepare questions for the meeting",
                "Review ideas for a new project"
            ]
            }
            let now = Date()
            localNotes = texts.enumerated().map { index, text in
                LocalNote(
                    id: UUID(uuidString: String(format:
                        "AAAA0000-0000-0000-0000-%012d", 200 + index))!,
                    kind: .text,
                    createdAt: now.addingTimeInterval(Double(-index * 3600)),
                    updatedAt: now, body: text, fileName: nil,
                    duration: nil, archived: false,
                    sourceDevice: "ASO Simulator"
                )
            }
            return
        }

        func qaID(_ last: Int) -> UUID {
            UUID(uuidString: String(format:
                "AAAA0000-0000-0000-0000-%012d", last))!
        }
        let now = Date()
        localNotes = [
            LocalNote(
                id: qaID(1), kind: .text, createdAt: now,
                updatedAt: now, body: "Нужно сверить план на неделю и список важных задач",
                fileName: nil, duration: nil, archived: false,
                sourceDevice: "QA Simulator"
            ),
            LocalNote(
                id: qaID(2), kind: .text,
                createdAt: now.addingTimeInterval(-3600), updatedAt: now,
                body: "Напомнить о встрече и подготовить вопросы для обсуждения",
                fileName: nil, duration: nil, archived: false,
                sourceDevice: "QA Simulator"
            ),
            LocalNote(
                id: qaID(3), kind: .video,
                createdAt: now.addingTimeInterval(-7200), updatedAt: now,
                body: "", fileName: nil, duration: 13, archived: false,
                sourceDevice: "QA Simulator"
            ),
            LocalNote(
                id: qaID(4), kind: .text,
                createdAt: now.addingTimeInterval(-86400), updatedAt: now,
                body: "Архивная тестовая заметка", fileName: nil, duration: nil,
                archived: true, sourceDevice: "QA Simulator"
            )
        ]
        // There is no fake audio file: absent media should be tested
        // separately as a recovery/error state, not mixed with healthy notes.
        // No playback/export/delete actions are exercised by this fixture.
        // The missing media state on the synthetic video is intentional.
    }
#endif

    func revealReminder(_ noteID: UUID) {
        reload()
        guard recordings.contains(where: { $0.id == noteID }) ||
              localNotes.contains(where: { $0.id == noteID }) else {
            // The user might have deleted or moved the original note since
            // copying its URL to ChickMark. Do not silently open a blank Home.
            errorMessage = CaptureBrand.text(
                "Исходная заметка больше недоступна в Ухвате.",
                "The original note is no longer available in UhWhat."
            )
            return
        }
        reminderTargetID = noteID
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let value = response.notification.request.content.userInfo["noteID"] as? String,
           let id = UUID(uuidString: value) {
            Task { @MainActor [weak self] in self?.revealReminder(id) }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func reloadWatchQueueStatus() {
        lastWatchQueueSnapshot = PhoneConnectivityManager.shared.lastWatchQueueSnapshot
    }

    func reload() {
        recordings = repository.allRecordings()
        do {
            localNotes = try localNoteRepository.allNotes()
        } catch {
            errorMessage = "Could not read saved text/video notes: \(error.localizedDescription)"
        }
        transcripts = repository.transcripts()
        do {
            archivedIDs = try repository.archivedIDs()
        } catch {
            errorMessage = "Could not read the archive: \(error.localizedDescription)"
        }
    }

    /// Files remains the source of truth; only a protected copy is stored.
    @discardableResult
    func importAudioFromFiles(_ source: URL) async throws -> RecordingEnvelope {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        let prepared = try await AudioFileImportService.prepare(source)
        defer { prepared.cleanUp() }
        let id = UUID()
        let result = try repository.acceptTemporaryFile(prepared.url, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: prepared.duration
        ])
        guard case .stored(let recording) = result else {
            throw RecordingRepository.RepositoryError.recordingUnavailable
        }
        reload()
        Task { await reminderManager.scheduleAutomaticallyIfEnabled(noteID: id) }
        transcribeIfAuthorized(recording)
        return recording
    }

    func saveText(id: UUID, body: String) {
        do {
            _ = try localNoteRepository.saveText(
                id: id, body: body,
                sourceDevice: UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
            )
            localNotes = try localNoteRepository.allNotes()
        } catch {
            errorMessage = "Text note could not be saved: \(error.localizedDescription)"
        }
    }

    /// Called after the *new* text editor closes. Autosave stays immediate;
    /// auto-follow-up starts only when the user finishes composing the note.
    func finishedNewTextNote(id: UUID) {
        guard let note = localNotes.first(where: { $0.id == id && $0.kind == .text }),
              !note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        Task { await reminderManager.scheduleAutomaticallyIfEnabled(noteID: id) }
    }

    func saveVideo(from temporaryURL: URL, duration: TimeInterval,
                   id: UUID = UUID()) throws {
        let alreadyIndexed = localNotes.contains { $0.id == id }
        _ = try localNoteRepository.importVideo(
            from: temporaryURL, duration: duration, id: id,
            sourceDevice: UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        )
        localNotes = try localNoteRepository.allNotes()
        if !alreadyIndexed {
            Task { await reminderManager.scheduleAutomaticallyIfEnabled(noteID: id) }
        }
    }

    func recoverInterruptedVideos(
        requireCompleteSegments: Bool = false,
        expectedSegmentCount: Int = 0
    ) async {
        do {
            let previouslyIndexed = Set(localNotes.map(\.id))
            let result = try await VideoCaptureRecovery.recover(
                journal: VideoCaptureJournal(), repository: localNoteRepository,
                requireCompleteSegments: requireCompleteSegments,
                expectedSegmentCount: expectedSegmentCount
            )
            if result.recovered > 0 {
                localNotes = try localNoteRepository.allNotes()
                for note in localNotes where !previouslyIndexed.contains(note.id) {
                    await reminderManager.scheduleAutomaticallyIfEnabled(noteID: note.id)
                }
            }
            if result.unresolved > 0 {
                videoRecoveryNotice = CaptureBrand.formatted(
                    "Восстановлено видео: %d. Не все прерванные записи удалось восстановить. Доступные исходные данные сохранены для повторной попытки.",
                    "Recovered videos: %d. Some interrupted recordings could not be restored. Available originals were kept for retry.",
                    result.recovered
                )
            } else if result.recovered > 0 {
                videoRecoveryNotice = CaptureBrand.formatted(
                    "Восстановлено видео: %d.",
                    "Recovered video notes: %d.",
                    result.recovered
                )
            }
        } catch {
            videoRecoveryNotice = CaptureBrand.formatted(
                "Не удалось восстановить видео. Исходные файлы не удалены. %@",
                "Video recovery failed. Original files remain on device. %@",
                error.localizedDescription
            )
        }
    }

    func videoURL(for note: LocalNote) -> URL? {
        localNoteRepository.videoURL(for: note)
    }

    func setArchived(_ note: LocalNote, archived: Bool) {
        do {
            try localNoteRepository.setArchived(note.id, archived: archived)
            localNotes = try localNoteRepository.allNotes()
        } catch {
            errorMessage = "Could not archive the note: \(error.localizedDescription)"
        }
    }

    func delete(_ note: LocalNote) {
        do {
            try localNoteRepository.delete(note.id)
            reminderManager.noteWasDeleted(note.id)
            localNotes = try localNoteRepository.allNotes()
        } catch {
            // An interrupted MOV cleanup may throw AFTER the note was
            // journaled as deleted. Refresh the Inbox and cancel reminders
            // for a logically deleted UUID, rather than showing a phantom
            // note or sending a notification for a hidden item.
            if let visible = try? localNoteRepository.allNotes() {
                localNotes = visible
                if !visible.contains(where: { $0.id == note.id }) {
                    reminderManager.noteWasDeleted(note.id)
                }
            }
            errorMessage = CaptureBrand.text(
                "Не удалось завершить удаление файла заметки. Если удаление уже подтверждено, очистка будет повторена при следующем запуске. ",
                "Note media cleanup could not finish. If deletion was already committed, cleanup will retry on the next launch. "
            ) + error.localizedDescription
        }
    }

    func setArchived(_ recording: RecordingEnvelope, archived: Bool) {
        do {
            try repository.setArchived(recording.id, archived: archived)
            archivedIDs = try repository.archivedIDs()
        } catch {
            errorMessage = "Could not update the archive: \(error.localizedDescription)"
        }
    }

    func delete(_ recording: RecordingEnvelope) {
        if playingID == recording.id {
            player?.stop()
            player = nil
            playingID = nil
        }
        if transcribingID == recording.id {
            cancelTranscription()
        }

        do {
            try repository.deleteRecording(recording.id)
            reminderManager.noteWasDeleted(recording.id)
            reload()
        } catch {
            reload()
            errorMessage = "Recording deletion was not completed: \(error.localizedDescription)"
        }
    }

    /// Received Watch audio is immediately indexed if iOS Speech permission
    /// was already granted; never silently prompt for permission from a background
    /// WatchConnectivity callback.
    func receivedRecording(_ recordingID: UUID?) {
        let previouslyIndexed = recordingID.map { id in
            recordings.contains { $0.id == id }
        } ?? false
        reload()
        guard let recordingID,
              let recording = recordings.first(where: { $0.id == recordingID })
        else { return }
        if !previouslyIndexed {
            Task { await reminderManager.scheduleAutomaticallyIfEnabled(noteID: recordingID) }
        }
        transcribeIfAuthorized(recording)
    }

    private func transcribeIfAuthorized(_ recording: RecordingEnvelope) {
        guard transcripts[recording.id] == nil,
              SFSpeechRecognizer.authorizationStatus() == .authorized else { return }
        if transcribingID != nil {
            if !batchIDs.contains(recording.id) {
                batchIDs.append(recording.id)
                batchTranscriptionActive = true
            }
        } else {
            transcribe(recording)
        }
    }

    func transcribeMissing() {
        guard transcribingID == nil && !batchTranscriptionActive else { return }
        batchIDs = recordings
            .filter { transcripts[$0.id] == nil && repository.audioExists(for: $0) }
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.id)
        batchTranscriptionActive = !batchIDs.isEmpty
        transcribeNextInBatch()
    }

    private func transcribeNextInBatch() {
        guard transcribingID == nil else { return }
        while !batchIDs.isEmpty {
            let id = batchIDs.removeFirst()
            if transcripts[id] != nil { continue }
            if let recording = recordings.first(where: { $0.id == id }),
               repository.audioExists(for: recording) {
                transcribe(recording)
                return
            }
        }
        batchTranscriptionActive = false
    }

    private func finishTranscription() {
        // Invalidate before releasing the recognition task, since Speech may
        // deliver one more final result or error after completion/cancellation.
        speechAttempt.invalidate()
        transcribingID = nil
        recognitionTask = nil
        recognizer = nil
        if batchTranscriptionActive { transcribeNextInBatch() }
    }

    func cancelTranscription() {
        batchIDs.removeAll()
        batchTranscriptionActive = false
        // Invalidate *before* cancelling; a late callback for an earlier
        // attempt must not overwrite corrections during a same-UUID retry.
        speechAttempt.invalidate()
        transcribingID = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizer = nil
    }

    func transcriptRecoveryStatus() -> RecordingRepository.TranscriptRecoveryStatus {
        repository.transcriptRecoveryStatus()
    }

    func restoreTranscriptCatalogFromBackup() throws {
        try repository.restoreTranscriptCatalogFromBackup()
        reload()
    }

    func updateTranscript(_ text: String, for recording: RecordingEnvelope) throws {
        if transcribingID == recording.id {
            cancelTranscription()
        }
        try repository.updateTranscript(text, for: recording.id)
        transcripts[recording.id] = text
    }

    func prepareExport(
        _ recording: RecordingEnvelope,
        selection: RecordingExportSelection
    ) -> PreparedRecordingExport? {
        do {
            return try RecordingExportService.prepare(
                recording: recording,
                audioURL: repository.audioURL(for: recording),
                transcript: transcripts[recording.id],
                selection: selection
            )
        } catch {
            errorMessage = "Unable to prepare the export: \(error.localizedDescription)"
            return nil
        }
    }

    func isAudioAvailable(_ recording: RecordingEnvelope) -> Bool {
        repository.audioExists(for: recording)
    }

    func isAudioComplete(_ recording: RecordingEnvelope) -> Bool {
        guard repository.audioExists(for: recording),
              let player = try? AVAudioPlayer(contentsOf: repository.audioURL(for: recording))
        else { return false }
        return (try? PhoneCaptureValidation.validate(
            actualDuration: player.duration,
            elapsedTime: recording.duration
        )) != nil
    }

    func beginPhoneCapture() {
        player?.stop()
        player = nil
        playingID = nil
        // Do not reconfigure the shared audio session while an old recognition
        // or playback operation is still using it.
        if transcribingID != nil { cancelTranscription() }
        showPhoneCapture = true
    }

    func togglePlayback(_ recording: RecordingEnvelope) {
        if playingID == recording.id {
            player?.stop()
            player = nil
            playingID = nil
            return
        }
        player?.stop()
        playingID = nil
        player = nil
        guard repository.audioExists(for: recording) else {
            errorMessage = "The audio file is missing. Keep the recording on your Watch until it can be transferred again."
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let audioPlayer = try AVAudioPlayer(contentsOf: repository.audioURL(for: recording))
            audioPlayer.delegate = self
            guard audioPlayer.prepareToPlay(), audioPlayer.play() else {
                errorMessage = "Audio playback could not start."
                return
            }
            player = audioPlayer
            playingID = recording.id
        } catch {
            errorMessage = "Audio could not be played: \(error.localizedDescription)"
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playingID = nil
        self.player = nil
        if !flag { errorMessage = "Audio playback ended unexpectedly." }
    }

    func transcribe(_ recording: RecordingEnvelope) {
        guard transcribingID == nil else { return }
        guard transcripts[recording.id] == nil || !batchTranscriptionActive else {
            return
        }
        guard repository.audioExists(for: recording) else {
            errorMessage = "The audio file is missing. Transcription is unavailable."
            return
        }
        guard isAudioComplete(recording) else {
            errorMessage = "Audio is incomplete: the microphone did not capture the full recording. Please record it again."
            if batchTranscriptionActive { transcribeNextInBatch() }
            return
        }
        // A valid-looking AAC file can contain entirely zeroed microphone
        // buffers (observed after iPhone Mirroring). Never send such files to
        // Speech: it can only return "No speech detected".
        guard (try? PhoneCaptureValidation.validateFileHasSound(
            repository.audioURL(for: recording)
        )) != nil else {
            errorMessage = "This recording contains no microphone sound. Restart the iPhone if needed and record again; speech recognition cannot recover missing audio."
            if batchTranscriptionActive { transcribeNextInBatch() }
            return
        }
        transcribingID = recording.id
        let attempt = speechAttempt.begin(for: recording.id)
        SFSpeechRecognizer.requestAuthorization { [weak self] authorization in
            Task { @MainActor [weak self] in
                // Authorization can return after cancellation or deletion.
                guard let self, self.transcribingID == recording.id,
                      self.speechAttempt.accepts(recording: recording.id, attempt: attempt)
                else { return }
                guard authorization == .authorized else {
                    self.batchIDs.removeAll()
                    self.batchTranscriptionActive = false
                    self.finishTranscription()
                    self.errorMessage = CaptureBrand.text(
                        "Разрешите распознавание речи для Ухвата в настройках iPhone. Аудиозапись сохранена.",
                        "Allow Speech Recognition for UhWhat? in iPhone Settings. Your audio is safe."
                    )
                    return
                }
                self.beginTranscription(recording, attempt: attempt)
            }
        }
    }

    private func beginTranscription(_ recording: RecordingEnvelope, attempt: UUID) {
        guard transcribingID == recording.id,
              speechAttempt.accepts(recording: recording.id, attempt: attempt)
        else { return }
        // Only on-device recognition: never silently upload private recordings.
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: transcriptionLocale)),
              recognizer.supportsOnDeviceRecognition,
              recognizer.isAvailable else {
            batchIDs.removeAll()
            batchTranscriptionActive = false
            finishTranscription()
            errorMessage = CaptureBrand.text(
                "Локальное распознавание для выбранного языка недоступно. Выберите другой язык или проверьте поддержку в настройках iOS. Исходное аудио сохранено.",
                "On-device speech recognition is unavailable for the selected language. Choose another language or check iOS Settings. Original audio is preserved."
            )
            return
        }
        self.recognizer = recognizer
        let request = SFSpeechURLRecognitionRequest(url: repository.audioURL(for: recording))
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self, self.transcribingID == recording.id,
                      self.speechAttempt.accepts(recording: recording.id, attempt: attempt)
                else { return }
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        self.errorMessage = CaptureBrand.text(
                            "Речь не распознана. Проверьте запись или выберите другой язык. Аудио сохранено.",
                            "Speech was not detected. Check the recording or choose another language. Audio is safe."
                        )
                        self.finishTranscription()
                        return
                    }
                    do {
                        try self.repository.saveTranscript(text, for: recording.id)
                        self.transcripts[recording.id] = text
                    } catch {
                        self.errorMessage = CaptureBrand.text(
                            "Речь распознана, но сохранить текст не удалось. Исходное аудио не удалено.",
                            "Speech was recognized, but the text could not be saved. Original audio was not deleted."
                        )
                    }
                    self.finishTranscription()
                } else if let error {
                    self.finishTranscription()
                    self.errorMessage = CaptureBrand.formatted(
                        "Ошибка распознавания: %@. Исходное аудио сохранено.",
                        "Transcription failed: %@. Original audio was preserved.",
                        error.localizedDescription
                    )
                }
            }
        }
    }
}
