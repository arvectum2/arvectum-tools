import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab = ContentView.initialTab

    private static var initialTab: Int {
#if DEBUG
        let process = ProcessInfo.processInfo
        if let value = process.environment["PUSHKIN_STORE_TAB"]
            .flatMap(Int.init) {
            return value
        }

        let arguments = process.arguments
        if let index = arguments.firstIndex(of: "--store-tab"),
           arguments.indices.contains(index + 1),
           let value = Int(arguments[index + 1]) {
            return value
        }
#endif
        return 0
    }

    var body: some View {
        Group {
#if DEBUG
            if let screen = ProcessInfo.processInfo.environment["PUSHKIN_DEBUG_SCREEN"] {
                debugScreen(screen)
            } else {
                mainTabs
            }
#else
            mainTabs
#endif
        }
        .tint(.arvectumMint)
        .task {
#if DEBUG
            StoreScreenshotFixture.installIfRequested(into: modelContext)
#endif
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    Label("History", systemImage: "tray.full")
                }
                .tag(0)

            SetupGuideView()
                .tabItem {
                    Label("Apps", systemImage: "square.stack.3d.up")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
    }

#if DEBUG
    @ViewBuilder
    private func debugScreen(_ screen: String) -> some View {
        switch screen {
        case "add-app":
            CoverageAppPicker { _ in }
        case "manual-add":
            NavigationStack {
                ManualCoverageGuide(appName: "Example App")
            }
        default:
            mainTabs
        }
    }
#endif
}

private struct InboxView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    @AppStorage("coverage.quickRefreshCount")
    private var quickRefreshCount = 0

    @AppStorage("coverage.lastQuickRefreshName")
    private var lastQuickRefreshName = ""

    @AppStorage("coverage.lastQuickRefreshAt")
    private var lastQuickRefreshAt = 0.0

    @AppStorage("coverage.pendingAppName")
    private var pendingCoverageName = ""

    @AppStorage("coverage.pendingAppTitle")
    private var pendingCoverageTitle = ""

    @AppStorage("coverage.pendingStartedAt")
    private var pendingCoverageStartedAt = 0.0

    @State private var showAppPicker = false
    @State private var pendingBasePackageURL: URL?

    private let automationsURL = URL(string: "shortcuts://automations")!

    private var filteredNotifications: [CapturedNotification] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return notifications }

        return notifications.filter { item in
            [item.sourceApp, item.titleText, item.subtitleText, item.bodyText]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ArvectumPushkinHeader {
                    showAppPicker = true
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 6)

                if !notifications.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search notifications", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($searchFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                searchFocused = false
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear search")
                        }

                        if searchFocused {
                            Button {
                                searchFocused = false
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundStyle(Color.arvectumMint)
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Dismiss keyboard")
                            .accessibilityIdentifier("dismiss-search-keyboard")
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(
                        Color.arvectumSurface,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.arvectumBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                }

                if !pendingCoverageTitle.isEmpty {
                    pendingCoverageCard
                }

                Group {
                    if notifications.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundStyle(Color.arvectumMint)

                            Text("Notification history")
                                .font(.title3.weight(.semibold))

                            if let url = CoverageCatalog.basePackageURL {
                                Button {
                                    if url.isFileURL {
                                        pendingBasePackageURL = url
                                    } else {
                                        openURL(url)
                                    }
                                } label: {
                                    Label(
                                        "Set up PUSHKIN",
                                        systemImage: "wand.and.stars"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .accessibilityIdentifier("setup-pushkin")
                            }
                        }
                        .padding(.horizontal, 28)
                        .frame(maxWidth: 430)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredNotifications.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List {
                            ForEach(
                                Array(filteredNotifications.indices),
                                id: \.self
                            ) { index in
                                let item = filteredNotifications[index]

                                NavigationLink {
                                    NotificationDetailView(item: item)
                                } label: {
                                    NotificationRow(item: item)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = item.shareText
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }

                                    ShareLink(item: item.shareText) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                }
                                .listRowBackground(Color.arvectumSurface)
                                .listRowSeparatorTint(Color.arvectumBorder)

                                if PushkinFeatureFlags.shouldRenderNativeAdSlot && index == 2 {
                                    FutureNativeAdPlacement()
                                        .listRowInsets(
                                            EdgeInsets(
                                                top: 8,
                                                leading: 16,
                                                bottom: 8,
                                                trailing: 16
                                            )
                                        )
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
            }
            .background(Color.arvectumBackground.ignoresSafeArea())
            .sheet(isPresented: $showAppPicker) {
                CoverageAppPicker { app in
                    let now = Date().timeIntervalSince1970
                    lastQuickRefreshName = app.name
                    lastQuickRefreshAt = now
                    quickRefreshCount += 1
                    pendingCoverageName = app.name
                    pendingCoverageTitle = app.title
                    pendingCoverageStartedAt = now
                }
            }
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {}
            }
        }
    }

    private var pendingCoverageVerified: Bool {
        guard pendingCoverageStartedAt > 0 else { return false }

        let candidates = [
            pendingCoverageTitle,
            pendingCoverageName
        ]
        .map(normalizedAppName)
        .filter { !$0.isEmpty }

        return notifications.contains { item in
            guard item.capturedAt.timeIntervalSince1970
                >= pendingCoverageStartedAt - 2
            else {
                return false
            }

            let source = normalizedAppName(item.sourceApp)
            guard !source.isEmpty else { return false }

            return candidates.contains { candidate in
                candidate == source
                    || candidate.contains(source)
                    || source.contains(candidate)
            }
        }
    }

    private var pendingCoverageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                pendingCoverageVerified
                    ? "Coverage verified"
                    : "Finish adding \(pendingCoverageTitle)",
                systemImage: pendingCoverageVerified
                    ? "checkmark.seal.fill"
                    : "switch.2"
            )
            .font(.headline)

            if pendingCoverageVerified {
                Text("\(pendingCoverageTitle) is active.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Done") {
                    clearPendingCoverage()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("coverage-finish-done")
            } else {
                Text("Enable the new PUSHKIN automation once in Shortcuts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Link(destination: automationsURL) {
                    Label(
                        "Open Automations",
                        systemImage: "arrow.up.forward.app"
                    )
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("finish-coverage-automations")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .accessibilityIdentifier("coverage-finish-card")
    }

    private func clearPendingCoverage() {
        pendingCoverageName = ""
        pendingCoverageTitle = ""
        pendingCoverageStartedAt = 0
    }

    private func delete(_ item: CapturedNotification) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func normalizedAppName(_ value: String) -> String {
        value.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .joined()
    }
}

private struct NotificationRow: View {
    let item: CapturedNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.sourceApp)
                    .font(.headline)
                Spacer()
                Text(item.receivedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !item.titleText.isEmpty {
                Text(item.titleText)
                    .font(.subheadline.weight(.semibold))
            }

            Text(item.bodyText.isEmpty ? item.subtitleText : item.bodyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if item.duplicateCandidate {
                Label("Possible duplicate", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct NotificationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingDeleteConfirmation = false

    let item: CapturedNotification

    var body: some View {
        List {
            Section("From") {
                Label(item.sourceApp, systemImage: "app.fill")
            }

            Section("Notification") {
                if !item.titleText.isEmpty {
                    Text(item.titleText)
                        .font(.headline)
                }
                if !item.subtitleText.isEmpty {
                    Text(item.subtitleText)
                        .foregroundStyle(.secondary)
                }
                Text(item.bodyText.isEmpty ? "No message body" : item.bodyText)
                    .textSelection(.enabled)
                    .foregroundStyle(item.bodyText.isEmpty ? .secondary : .primary)
            }

            Section("Time") {
                LabeledContent(
                    "Received",
                    value: item.receivedAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
            }

            Section {
                Button {
                    UIPasteboard.general.string = item.shareText
                } label: {
                    Label("Copy text", systemImage: "doc.on.doc")
                }

                ShareLink(item: item.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.arvectumBackground)
        .navigationTitle(item.sourceApp)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this notification?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
                dismiss()
            }
        }
    }
}


private extension CapturedNotification {
    var shareText: String {
        var parts = [sourceApp]

        if !titleText.isEmpty {
            parts.append(titleText)
        }
        if !subtitleText.isEmpty {
            parts.append(subtitleText)
        }
        if !bodyText.isEmpty {
            parts.append(bodyText)
        }

        return parts.joined(separator: "\n")
    }
}

private struct DiagnosticPayloadRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "Empty" : value)
                .textSelection(.enabled)
        }
    }
}
