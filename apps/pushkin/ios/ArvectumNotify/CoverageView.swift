import SwiftUI

struct CoverageCatalogEntry: Codable, Identifiable, Hashable {
    let name: String
    let displayName: String?
    let bundleIdentifier: String
    let teamIdentifier: String?
    let shortcutName: String
    let packageFile: String
    let rank: Int

    var id: String { bundleIdentifier }
    var title: String {
        let display = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (display?.isEmpty == false ? display : nil) ?? name
    }
}

struct CoverageCatalogDocument: Codable {
    let catalogVersion: Int
    let basePackageFile: String
    let apps: [CoverageCatalogEntry]
}

enum CoverageCatalog {
    static let document: CoverageCatalogDocument = load()
    static var entries: [CoverageCatalogEntry] { document.apps }

    static var commonEntries: [CoverageCatalogEntry] {
        let preferredBundles = [
            "ph.telegra.Telegraph", "net.whatsapp.WhatsApp",
            "ru.ozon.OzonStore", "RU.WILDBERRIES.MOBILEAPP",
            "ru.yandex.ytaxi", "ru.yandex.traffic",
            "ru.doublegis.grymmobile", "com.minsvyaz.gosuslugi",
            "ru.yandex.mobile.search", "ru.yandex.blue.market",
            "ru.mts.mymts", "ru.megafon.lk",
            "ru.beeline.mobile", "ru.sbcs.store",
            "com.vkusvill", "ru.tander.magnit",
            "ru.5ka.browser.app", "com.google.Gmail",
            "com.google.Maps", "com.burbn.instagram"
        ]
        let byBundle = Dictionary(uniqueKeysWithValues: entries.map {
            ($0.bundleIdentifier, $0)
        })
        let preferred = preferredBundles.compactMap { byBundle[$0] }
        if preferred.count >= 20 { return Array(preferred.prefix(20)) }
        let used = Set(preferred.map(\.bundleIdentifier))
        return preferred + entries.filter {
            !used.contains($0.bundleIdentifier)
        }.prefix(20 - preferred.count)
    }

    static var basePackageURL: URL? {
        bundledURL(filename: document.basePackageFile, isMicro: false)
            ?? developmentURL(filename: document.basePackageFile)
    }

    static func packageURL(for entry: CoverageCatalogEntry) -> URL? {
        bundledURL(filename: entry.packageFile, isMicro: true)
            ?? developmentURL(filename: entry.packageFile)
    }

    private static func bundledURL(
        filename: String,
        isMicro: Bool
    ) -> URL? {
        let subdirectories = isMicro
            ? ["Coverage/Micro", "Micro", "Coverage"]
            : ["Coverage", ""]

        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: filename,
                withExtension: nil,
                subdirectory: subdirectory.isEmpty ? nil : subdirectory
            ) {
                return url
            }
        }

        return Bundle.main.url(
            forResource: filename,
            withExtension: nil
        )
    }

    private static func developmentURL(filename: String) -> URL? {

#if DEBUG
        return URL(
            string: "http://192.168.1.80:8765/pushkin-coverage-dev/signed/\(filename)"
        )
#else
        return nil
#endif
    }

    private static func load() -> CoverageCatalogDocument {
        let urls = [
            Bundle.main.url(
                forResource: "coverage-catalog",
                withExtension: "json"
            ),
            Bundle.main.url(
                forResource: "coverage-catalog",
                withExtension: "json",
                subdirectory: "Coverage"
            )
        ]

        for url in urls.compactMap({ $0 }) {
            if let data = try? Data(contentsOf: url),
               let document = try? JSONDecoder().decode(
                   CoverageCatalogDocument.self,
                   from: data
               ) {
                return document
            }
        }

        assertionFailure("coverage-catalog.json is missing or invalid")
        return CoverageCatalogDocument(
            catalogVersion: 0,
            basePackageFile: "",
            apps: []
        )
    }
}

struct CoverageView: View {
    @AppStorage("coverage.quickRefreshCount")
    private var quickRefreshCount = 0

    @AppStorage("coverage.lastQuickRefreshName")
    private var lastQuickRefreshName = ""

    @AppStorage("coverage.lastQuickRefreshAt")
    private var lastQuickRefreshAt = 0.0

    @State private var showAppPicker = false

    private let automationsURL = URL(string: "shortcuts://automations")!

    var body: some View {
        List {
            Section("Coverage") {
                LabeledContent(
                    "Base catalog",
                    value: "\(CoverageCatalog.entries.count) apps"
                )
                LabeledContent(
                    "Catalog version",
                    value: "\(CoverageCatalog.document.catalogVersion)"
                )

                if quickRefreshCount > 0 {
                    LabeledContent(
                        "Apps added later",
                        value: "\(quickRefreshCount)"
                    )
                }

                if !lastQuickRefreshName.isEmpty {
                    LabeledContent(
                        "Latest",
                        value: lastQuickRefreshName
                    )
                }
            }

            Section("Installed a new app?") {
                Button {
                    showAppPicker = true
                } label: {
                    Label(
                        "Add app to PUSHKIN",
                        systemImage: "plus.app.fill"
                    )
                }

                Text(
                    "Choose the app once. PUSHKIN opens a tiny one-app refresh package instead of rebuilding the full catalog."
                )
                .foregroundStyle(.secondary)
            }

            Section("Maintenance") {
                Link(destination: automationsURL) {
                    Label(
                        "Open Shortcuts automations",
                        systemImage: "arrow.up.forward.app"
                    )
                }

                Text(
                    "A full catalog rebuild is intentionally not part of the normal update flow."
                )
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("App Coverage")
        .sheet(isPresented: $showAppPicker) {
            CoverageAppPicker { app in
                recordQuickRefresh(app)
            }
        }
    }

    private func recordQuickRefresh(_ app: CoverageCatalogEntry) {
        lastQuickRefreshName = app.name
        lastQuickRefreshAt = Date().timeIntervalSince1970
        quickRefreshCount += 1
    }
}

struct CoverageAppPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var query = ""
    @State private var pendingLocalPackageURL: URL?
    @State private var pendingApp: CoverageCatalogEntry?
    @State private var appStoreResults: [AppStoreCoverageResult] = []
    @State private var isSearchingAppStore = false
    @State private var preparingBundleIdentifier: String?
    @State private var customErrorMessage: String?

    let onOpenPack: (CoverageCatalogEntry) -> Void

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var catalogResults: [CoverageCatalogEntry] {
        guard !trimmedQuery.isEmpty else {
            return CoverageCatalog.commonEntries
        }

        return CoverageCatalog.entries.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.name.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.bundleIdentifier
                    .localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private var customResults: [AppStoreCoverageResult] {
        let bundled = Set(CoverageCatalog.entries.map(\.bundleIdentifier))
        return appStoreResults.filter { !bundled.contains($0.bundleId) }
    }

    private var searchSection: some View {
        Section {
            TextField("Search apps", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("app-search")
        } footer: {
            Text(
                "Choose an app. Shortcuts will open; tap Add, then enable the new automation once."
            )
        }
    }

    private var catalogSection: some View {
        Section(trimmedQuery.isEmpty ? "Popular apps" : "In PUSHKIN") {
            ForEach(catalogResults) { app in
                Button {
                    open(app)
                } label: {
                    HStack(spacing: 12) {
                        Text(app.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .disabled(CoverageCatalog.packageURL(for: app) == nil)
            }
        }
    }

    @ViewBuilder
    private var customSection: some View {
        Section {
            if isSearchingAppStore {
                HStack {
                    Spacer()
                    ProgressView("Searching App Store…")
                    Spacer()
                }
            } else {
                ForEach(customResults) { app in
                    customRow(app)
                }

                if catalogResults.isEmpty && customResults.isEmpty {
                    ContentUnavailableView.search(text: trimmedQuery)
                }
            }
        } header: {
            Text("More from the App Store")
        } footer: {
            Text(
                "For apps outside the built-in catalog, PUSHKIN prepares a small signed coverage configuration using only the app identity. Notification contents stay on your iPhone."
            )
        }
    }

    private func customRow(_ app: AppStoreCoverageResult) -> some View {
        Button {
            prepareCustom(app)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.trackName)
                        .foregroundStyle(.primary)
                    if let seller = app.sellerName {
                        Text(seller)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if preparingBundleIdentifier == app.bundleId {
                    ProgressView()
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(preparingBundleIdentifier != nil)
        .accessibilityIdentifier("custom-app-\(app.bundleId)")
    }

    var body: some View {
        NavigationStack {
            List {
                searchSection
                catalogSection
                if trimmedQuery.count >= 2 {
                    customSection
                }
            }
            .navigationTitle("Add App")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task(id: trimmedQuery) {
                await searchAppStore()
            }
            .alert(
                "Couldn't add app",
                isPresented: Binding(
                    get: { customErrorMessage != nil },
                    set: { if !$0 { customErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(customErrorMessage ?? "")
            }
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingLocalPackageURL
                ) {
                    guard let app = pendingApp else { return }
                    onOpenPack(app)
                    pendingApp = nil
                    dismiss()
                }
            }
        }
    }

    @MainActor
    private func searchAppStore() async {
        appStoreResults = []
        guard trimmedQuery.count >= 2 else {
            isSearchingAppStore = false
            return
        }

        isSearchingAppStore = true
        do {
            try await Task.sleep(for: .milliseconds(350))
            try Task.checkCancellation()
            let results = try await CustomCoverageService.searchAppStore(
                term: trimmedQuery
            )
            try Task.checkCancellation()
            appStoreResults = results
            isSearchingAppStore = false
        } catch is CancellationError {
            return
        } catch {
            isSearchingAppStore = false
        }
    }

    private func prepareCustom(_ result: AppStoreCoverageResult) {
        preparingBundleIdentifier = result.bundleId
        customErrorMessage = nil

        Task { @MainActor in
            do {
                let url = try await CustomCoverageService.signedPackage(
                    for: result
                )
                pendingApp = CoverageCatalogEntry(
                    name: result.trackName,
                    displayName: result.trackName,
                    bundleIdentifier: result.bundleId,
                    teamIdentifier: nil,
                    shortcutName: "PUSHKIN - \(result.trackName)",
                    packageFile: url.lastPathComponent,
                    rank: Int.max
                )
                pendingLocalPackageURL = url
            } catch {
                customErrorMessage = error.localizedDescription
            }
            preparingBundleIdentifier = nil
        }
    }

    private func open(_ app: CoverageCatalogEntry) {
        guard let url = CoverageCatalog.packageURL(for: app) else {
            return
        }

        if url.isFileURL {
            pendingApp = app
            pendingLocalPackageURL = url
            return
        }

        onOpenPack(app)
        dismiss()
        openURL(url)
    }
}
