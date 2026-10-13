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

    func find(
        query: String,
        recordings: [RecordingEnvelope],
        transcripts: [UUID: String]
    ) -> SemanticSearchOutput {
        let embedder = AppleLocalEmbedder(query: query)
        return index.search(
            query: query,
            recordings: recordings,
            transcripts: transcripts,
            vectorizer: embedder.isAvailable ? { embedder.vector(for: $0) } : nil,
            modelKey: embedder.key
        )
    }

    func installRussianAssets() async throws -> Bool {
        guard let model = NLContextualEmbedding(language: .russian) else {
            return false
        }
        guard !model.hasAvailableAssets else { return true }
        // Only called after an explicit confirmation in the iPhone UI.
        return try await model.requestAssets() == .available
    }
}

struct SmartSearchView: View {
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var searching = false
    @State private var installingAssets = false
    @State private var showDownloadConfirmation = false
    @State private var result: SemanticSearchOutput?
    @State private var error: String?
    @State private var requestID = UUID()

    @State private var worker = SmartSearchWorker()

    private var isRussianQuery: Bool {
        query.unicodeScalars.contains { (0x0400...0x052F).contains($0.value) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("What was that thought about?", text: $query)
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
                            || searching || installingAssets)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 6)

                if searching {
                    ProgressView("Searching your notes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let result {
                    searchResults(result)
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
            .onChange(of: store.transcripts.count) { _, _ in
                if result != nil && !query.isEmpty { performSearch() }
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
                Text("Apple will download the language model to this iPhone. After installation, your voice notes and searches stay on-device and work without internet.")
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
                         ? "Exact word search"
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
                if !output.semanticAvailable && isRussianQuery &&
                   query.split(whereSeparator: { $0.isWhitespace }).count > 1 {
                    Button {
                        showDownloadConfirmation = true
                    } label: {
                        Label(
                            installingAssets ? "Installing Russian model…" : "Enable Russian meaning search",
                            systemImage: "arrow.down.to.line"
                        )
                    }
                    .disabled(installingAssets)
                    .font(.subheadline)
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
                Section("\(output.hits.count) results") {
                    ForEach(output.hits) { hit in
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
                                    .lineLimit(4)
                                    .font(.body)
                                Label("Open original recording", systemImage: "waveform")
                                    .font(.caption)
                                    .foregroundStyle(.tint)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }

    private func performSearch() {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 2 else { return }
        searchFocused = false
        let recordings = store.recordings
        let transcripts = store.transcripts
        let currentID = UUID()
        requestID = currentID
        searching = true
        Task {
            let output = await worker.find(
                query: needle, recordings: recordings, transcripts: transcripts
            )
            guard currentID == requestID else { return }
            result = output
            searching = false
        }
    }

    private func installModel() {
        installingAssets = true
        Task {
            do {
                let succeeded = try await worker.installRussianAssets()
                installingAssets = false
                if succeeded {
                    performSearch()
                } else {
                    error = "The Russian language model is unavailable. Text search still works offline."
                }
            } catch {
                installingAssets = false
                self.error = "Could not install the language model: \(error.localizedDescription)"
            }
        }
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
