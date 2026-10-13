import SwiftUI
import NaturalLanguage

/// Serializes inference and cache updates away from SwiftUI's main thread.
actor SmartSearchWorker {
    private let index: LocalSemanticSearch

    init() {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        index = LocalSemanticSearch(
            cacheURL: support.appendingPathComponent("What/semantic-search-index.json")
        )
    }

    /// A controlled on-device diagnostic that exercises the actual Russian
    /// Apple model with the three examples reported by the user. This never
    /// sends private note contents to a server and is not used for ranking.
    func modelQualityProbe() -> [String] {
        let embedding = AppleLocalEmbedder(query: "цветок")
        guard embedding.isAvailable else {
            return ["Russian model has no loadable assets on this iPhone."]
        }
        let pairs: [(String, String, String)] = [
            ("цветок", "эдельвейс", "стол"),
            ("журнал", "дневник", "лампа"),
            ("красота", "эстетика", "колесо")
        ]
        return pairs.map { query, target, unrelated in
            guard let vector = embedding.vector(for: query) else {
                return query + ": query vector unavailable"
            }
            let linked = embedding.vector(for: target)
                .flatMap { LocalSemanticSearch.cosine(vector, $0) }
            let random = embedding.vector(for: unrelated)
                .flatMap { LocalSemanticSearch.cosine(vector, $0) }
            func label(_ value: Double?) -> String {
                value.map { String(format: "%.3f", $0) } ?? "n/a"
            }
            return query + " → " + target + ": " + label(linked)
                + " | unrelated " + label(random)
        }
    }

    func find(
        query: String,
        recordings: [RecordingEnvelope],
        transcripts: [UUID: String],
        askMode: Bool = false
    ) -> SemanticSearchOutput {
        let embedder = AppleLocalEmbedder(query: query)
        return index.search(
            query: query,
            recordings: recordings,
            transcripts: transcripts,
            vectorizer: embedder.isAvailable ? { embedder.vector(for: $0) } : nil,
            modelKey: embedder.key,
            lexicalQuery: askMode ? GroundedMemoryAnswer.focusQuery(query) : nil,
            askMode: askMode,
            termVectorizer: askMode && embedder.isAvailable
                ? { embedder.termVectors(for: $0) } : nil
        )
    }

}

struct SmartSearchView: View {
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var mode: SearchMode = .find
    @FocusState private var searchFocused: Bool
    @State private var searching = false
    @ObservedObject private var modelManager = RussianModelManager.shared
    @State private var showDownloadConfirmation = false
    @State private var showWeakCandidates = false
    @State private var evaluatingModel = false
    @State private var qualityProbeLines: [String] = []
    @State private var result: SemanticSearchOutput?
    @State private var error: String?
    @State private var requestID = UUID()

    @State private var worker = SmartSearchWorker()

    private enum SearchMode: String, CaseIterable {
        case find = "Find notes"
        case ask = "Ask memory"
    }

    private var isRussianQuery: Bool {
        query.unicodeScalars.contains { (0x0400...0x052F).contains($0.value) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Search mode", selection: $mode) {
                    ForEach(SearchMode.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(
                        mode == .ask ? "What did I say about…?" :
                            "What was that thought about?",
                        text: $query
                    )
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
                        .accessibilityLabel("Search voice transcripts")
                    if !query.isEmpty {
                        Button {
                            requestID = UUID()
                            searching = false
                            query = ""
                            result = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(12)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 12)

                HStack {
                    Label("Only on this iPhone", systemImage: "iphone.gen3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if searchFocused {
                        Button("Hide keyboard") {
                            searchFocused = false
                        }
                        .font(.caption)
                    }
                    Button("Find") { performSearch() }
                        .buttonStyle(.borderedProminent)
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                            || searching || modelManager.phase.isBusy)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 6)

                if modelManager.phase == .requesting ||
                   modelManager.phase == .verifying {
                    modelInstallationPanel
                }
                if searching {
                    ProgressView("Searching your notes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let result {
                    if mode == .ask {
                        groundedAnswerResults(result)
                    } else {
                        searchResults(result)
                    }
                } else {
                    ContentUnavailableView(
                        "Search your memory",
                        systemImage: "text.magnifyingglass",
                        description: Text(
                            "Search for an idea, task, or topic. Results lead back to your original voice recordings. Only notes with saved text are searchable."
                        )
                    )
                }
            }
            .onAppear { modelManager.refresh() }
            .onChange(of: modelManager.phase) { _, next in
                if next == .ready && isRussianQuery &&
                   query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                    performSearch()
                }
            }
            .onChange(of: store.transcripts.count) { _, _ in
                if result != nil && !query.isEmpty { performSearch() }
            }
            .onChange(of: mode) { _, _ in
                if result != nil && query.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).count >= 2 {
                    performSearch()
                }
            }
            .navigationTitle("Smart search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { searchFocused = false }
                }
            }
            .confirmationDialog(
                "Download Russian language model?",
                isPresented: $showDownloadConfirmation
            ) {
                Button("Download model") { installModel() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Download size: Apple does not publish the exact number of MB or GB. Apple also does not provide download percentage. What? will show installation stages and verify that the model works before reporting success. Search and audio remain on-device.")
            }
            .alert("Search", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
        }
    }

    @ViewBuilder
    private func searchResults(_ output: SemanticSearchOutput) -> some View {
        List {
            Section {
                HStack(spacing: 6) {
                    Image(systemName: output.semanticAvailable
                          ? "brain" : "text.magnifyingglass")
                    Text(query.split(whereSeparator: { $0.isWhitespace }).count == 1
                         ? "Word search (including spoken numbers)"
                         : (output.semanticAvailable
                             ? "Meaning + text search"
                             : "Text search (semantic model not installed)"))
                    Spacer()
                    Text("\(output.indexedCount) indexed")
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                let missing = store.recordings.filter {
                    store.transcripts[$0.id] == nil && store.isAudioAvailable($0)
                }.count
                if missing > 0 {
                    Button {
                        store.transcribeMissing()
                    } label: {
                        Label(
                            store.batchTranscriptionActive
                                ? "Transcribing notes…"
                                : "Transcribe \(missing) unindexed recordings",
                            systemImage: "waveform.badge.mic"
                        )
                    }
                    .disabled(store.batchTranscriptionActive || store.transcribingID != nil)
                    .font(.subheadline)
                    Text("Only saved text is searchable. New audio must be transcribed first.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if isRussianQuery &&
                   query.split(whereSeparator: { $0.isWhitespace }).count > 1 {
                    modelAvailabilityRow
                }
            }

            if output.hits.isEmpty {
                ContentUnavailableView(
                    "No matching notes",
                    systemImage: "magnifyingglass",
                    description: Text(
                        "Try different words, or transcribe more voice recordings. Search never guesses missing content."
                    )
                )
            } else {
                let direct = output.hits.filter { $0.match != .semantic }
                let meaning = output.hits.filter { $0.match == .semantic }
                if !direct.isEmpty {
                    Section("Word and number matches — \(direct.count)") {
                        ForEach(direct) { hit in
                            sourceLink(hit)
                        }
                    }
                }
                if !meaning.isEmpty {
                    Section("Similar by meaning — \(meaning.count)") {
                        ForEach(meaning) { hit in
                            sourceLink(hit)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func groundedAnswerResults(_ output: SemanticSearchOutput) -> some View {
        let answer = GroundedMemoryAnswer.extract(output)
        List {
            Section {
                modelAvailabilityRow
                if modelManager.phase == .ready {
                    Button {
                        evaluateModel()
                    } label: {
                        Label(
                            evaluatingModel
                                ? "Testing Russian model…"
                                : "Check Russian model quality",
                            systemImage: "waveform.path.ecg"
                        )
                    }
                    .disabled(evaluatingModel)
                    if evaluatingModel {
                        ProgressView("Comparing Russian word meanings…")
                    }
                    if !qualityProbeLines.isEmpty {
                        Text("Actual Apple similarity scores (not accuracy percentages):")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(qualityProbeLines, id: \.self) { line in
                            Text(line).font(.caption.monospaced())
                        }
                    }
                }
                Label("Private, on-device excerpts", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(
                    "These are possible matches from saved notes, not a generated answer. Meaning-based matches can be approximate. Open the audio to verify them."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if answer.hasEvidence {
                Section("Relevant source excerpts — \(answer.evidence.count)") {
                    ForEach(answer.evidence) { hit in
                        sourceLink(hit)
                    }
                }
            } else {
                ContentUnavailableView(
                    "No reliable match",
                    systemImage: "text.book.closed",
                    description: Text(noEvidenceDescription(answer, output: output))
                )
                if output.semanticAvailable &&
                   !output.hits.isEmpty {
                    Section {
                        Button(
                            showWeakCandidates
                                ? "Hide unverified candidates"
                                : "Inspect approximate candidates (not answers)"
                        ) {
                            showWeakCandidates.toggle()
                        }
                    }
                    if showWeakCandidates {
                        Section("Unverified suggestions") {
                            ForEach(Array(output.hits.prefix(5))) { hit in
                                sourceLink(hit)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }

    private func noEvidenceDescription(
        _ answer: GroundedMemoryAnswer,
        output: SemanticSearchOutput
    ) -> String {
        if !output.semanticAvailable {
            return "The Russian semantic model isn't loaded. No synonym matching is possible until installation is complete."
        }
        switch answer.assessment {
        case .ambiguousSimilarity:
            return "The model scores several notes almost equally. None is reliable enough to present as an answer."
        case .weakSimilarity:
            return "The model found only weak conceptual similarity. Try other phrasing."
        case .clearEvidence, .noEvidence:
            return "No matching evidence was found in the saved transcripts."
        }
    }

    @ViewBuilder
    private var modelAvailabilityRow: some View {
        switch modelManager.phase {
        case .unchecked, .checking:
            Label("Checking Russian model…", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .ready:
            Label("Russian meaning model: installed and working", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .requesting:
            Label("Requesting/downloading model from Apple…", systemImage: "arrow.down.circle")
                .font(.caption)
        case .verifying:
            Label("Download finished — verifying model…", systemImage: "checkmark.shield")
                .font(.caption)
        case .missing:
            Label("Russian meaning model: not installed", systemImage: "exclamationmark.triangle")
                .font(.caption)
            Button("Install Russian model") {
                showDownloadConfirmation = true
            }
            .font(.subheadline)
        case .failed(let message):
            Text("Russian model not ready: \(message)")
                .font(.caption)
                .foregroundStyle(.orange)
            Button("Retry installation") {
                showDownloadConfirmation = true
            }
            .font(.subheadline)
        }
    }

    private var modelInstallationPanel: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 4) {
                Text(modelManager.phase == .requesting
                    ? "Apple model: downloading / preparing"
                    : "Apple model: verifying installed assets")
                    .font(.subheadline.bold())
                Text("Size and % are not provided by Apple. Please wait.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let startedAt = modelManager.startedAt {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text("Elapsed \(Int(max(0, context.date.timeIntervalSince(startedAt)))) sec")
                            .font(.caption.monospacedDigit())
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func sourceLink(_ hit: SemanticSearchHit) -> some View {
        NavigationLink {
            SmartSearchRecordingDetail(recording: hit.recording)
                .environmentObject(store)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(hit.recording.createdAt, format:
                        .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(hit.match.rawValue + " match")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(hit.snippet)
                    .lineLimit(mode == .ask ? 6 : 4)
                    .font(.body)
                Label("Open original recording", systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
            .padding(.vertical, 5)
        }
    }

    private func performSearch() {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 2 else { return }
        searchFocused = false
        let recordings = store.recordings
        let transcripts = store.transcripts
        showWeakCandidates = false
        let currentID = UUID()
        let askMode = mode == .ask
        requestID = currentID
        searching = true
        Task {
            let output = await worker.find(
                query: needle, recordings: recordings, transcripts: transcripts,
                askMode: askMode
            )
            guard currentID == requestID else { return }
            result = output
            searching = false
        }
    }

    private func evaluateModel() {
        evaluatingModel = true
        qualityProbeLines = []
        Task {
            qualityProbeLines = await worker.modelQualityProbe()
            evaluatingModel = false
        }
    }

    private func installModel() {
        modelManager.startInstall()
    }

}

struct SmartSearchRecordingDetail: View {
    @EnvironmentObject private var store: PhoneStore
    let recording: RecordingEnvelope

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(recording.createdAt, format:
                    .dateTime.day().month().year().hour().minute())
                    .font(.headline)
                HStack {
                    Button {
                        store.togglePlayback(recording)
                    } label: {
                        Label(
                            store.playingID == recording.id ? "Stop audio" : "Play original audio",
                            systemImage: store.playingID == recording.id
                                ? "stop.circle.fill" : "play.circle.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!store.isAudioAvailable(recording))
                    Spacer()
                    Text(String(format: "%.0f sec", recording.duration))
                        .foregroundStyle(.secondary)
                }
                Divider()
                Text("Saved transcript")
                    .font(.headline)
                Text(store.transcripts[recording.id] ?? "No saved transcription")
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Source recording")
        .navigationBarTitleDisplayMode(.inline)
    }
}
