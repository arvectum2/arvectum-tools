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
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    Label(pc("History"), systemImage: "tray.full")
                }
                .tag(0)

            SetupGuideView()
                .tabItem {
                    Label(pc("Apps"), systemImage: "square.stack.3d.up")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label(pc("Settings"), systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(.arvectumInteractiveTint)
        .task {
#if DEBUG
            StoreScreenshotFixture.installIfRequested(into: modelContext)
#endif
        }
    }
}

private struct InboxView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var searchText = ""

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

    @State private var deleteError: String?

    private var filteredNotifications: [NotificationHistoryItem] {
        let values = notifications.map(NotificationHistoryItem.init)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return values }

        return values.filter { item in
            [item.sourceApp, item.titleText, item.subtitleText, item.bodyText]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ArvectumBrandHeader(productName: "PUSHKIN")
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                if !notifications.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField(pc("Search notifications"), text: $searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(pc("Clear search"))
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
                    VStack(spacing: 18) {
                        ContentUnavailableView(
                            pc("History is empty"),
                            systemImage: "bell.badge",
                            description: Text(
                                pc("Connect the apps you want to track in Shortcuts. Notifications captured from those sources will appear here.")
                            )
                        )

                        if let url = CoverageCatalog.basePackageURL {
                            Button {
                                if url.isFileURL {
                                    pendingBasePackageURL = url
                                } else {
                                    openURL(url)
                                }
                            } label: {
                                Label(
                                    pc("Set up PUSHKIN"),
                                    systemImage: "wand.and.stars"
                                )
                            }
                            .buttonStyle(ArvectumPrimaryActionStyle())
                            .accessibilityIdentifier("setup-pushkin")
                        }

                        Link(destination: automationsURL) {
                            Label(
                                pc("Enable PUSHKIN automation"),
                                systemImage: "switch.2"
                            )
                        }
                        .font(.footnote)
                        .accessibilityIdentifier("enable-pushkin-automation")
                    }
                    .padding()
                    } else if filteredNotifications.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List(filteredNotifications) { item in
                            NavigationLink {
                                NotificationDetailView(item: item)
                            } label: {
                                NotificationRow(item: item)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label(pc("Delete"), systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = item.shareText
                                } label: {
                                    Label(pc("Copy"), systemImage: "doc.on.doc")
                                }

                                ShareLink(item: item.shareText) {
                                    Label(pc("Share"), systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
            .background(Color.arvectumBackground.ignoresSafeArea())
            .navigationTitle(pc("History"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(pc("Couldn’t delete notification"), isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? pc("Please try again."))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAppPicker = true
                    } label: {
                        Label(
                            pc("Add app"),
                            systemImage: "plus.app"
                        )
                    }
                    .accessibilityIdentifier("add-app")
                }
            }
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

            // A substring overlap is not evidence that this exact source
            // was captured (e.g. "Mail" could match "Gmail").
            return candidates.contains(source)
        }
    }

    private var pendingCoverageDisplayName: String {
        PushkinDisplayName.brief(pendingCoverageTitle)
    }

    private var pendingCoverageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                pendingCoverageVerified
                    ? pc("Test capture received")
                    : String(format: pc("Finish adding %@"), pendingCoverageDisplayName),
                systemImage: pendingCoverageVerified
                    ? "checkmark.seal.fill"
                    : "switch.2"
            )
            .font(.headline)

            if pendingCoverageVerified {
                Text(
                    String(format: pc("PUSHKIN received a notification from %@. This confirms that source only; check the automation in Shortcuts."), pendingCoverageDisplayName)
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button(pc("Done")) {
                    clearPendingCoverage()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("coverage-finish-done")
            } else {
                Text(
                    pc("In Shortcuts, tap Add, then enable the new automation (imports start disabled). PUSHKIN can observe a real notification from this app, but cannot read the Shortcuts enable switch.")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Link(destination: automationsURL) {
                    Label(
                        pc("Open Automations"),
                        systemImage: "arrow.up.forward.app"
                    )
                }
                .buttonStyle(ArvectumPrimaryActionStyle())
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

    private func delete(_ item: NotificationHistoryItem) {
        do {
            try NotificationHistoryDeletion.delete(id: item.id, in: modelContext)
        } catch {
            deleteError = error.localizedDescription
        }
    }

    private func normalizedAppName(_ value: String) -> String {
        value.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .joined()
    }
}

private struct NotificationRow: View {
    let item: NotificationHistoryItem

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
                Label(pc("Possible duplicate"), systemImage: "doc.on.doc")
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
    @State private var deleteError: String?
    let item: NotificationHistoryItem

    var body: some View {
        detail(item)
        .navigationTitle(item.sourceApp)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            pc("Delete this notification?"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(pc("Delete"), role: .destructive) {
                do {
                    try NotificationHistoryDeletion.delete(
                        id: item.id,
                        in: modelContext
                    )
                    dismiss()
                } catch {
                    deleteError = error.localizedDescription
                }
            }
        }
        .alert(pc("Couldn’t delete notification"), isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? pc("Please try again."))
        }
    }

    private func detail(_ item: NotificationHistoryItem) -> some View {
        List {
            Section(pc("From")) {
                Label(item.sourceApp, systemImage: "app.fill")
            }

            Section(pc("Notification")) {
                if !item.titleText.isEmpty {
                    Text(item.titleText)
                        .font(.headline)
                }
                if !item.subtitleText.isEmpty {
                    Text(item.subtitleText)
                        .foregroundStyle(.secondary)
                }
                Text(item.bodyText.isEmpty ? pc("No message body") : item.bodyText)
                    .textSelection(.enabled)
                    .foregroundStyle(item.bodyText.isEmpty ? .secondary : .primary)
            }

            Section(pc("Time")) {
                LabeledContent(
                    pc("Received"),
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
                    Label(pc("Copy text"), systemImage: "doc.on.doc")
                }

                ShareLink(item: item.shareText) {
                    Label(pc("Share"), systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label(pc("Delete"), systemImage: "trash")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.arvectumBackground)
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
            Text(value.isEmpty ? pc("Empty") : value)
                .textSelection(.enabled)
        }
    }
}
