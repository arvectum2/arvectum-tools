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

    let onOpenPack: (CoverageCatalogEntry) -> Void

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filtered: [CoverageCatalogEntry] {
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

    var body: some View {
        NavigationStack {
            List {
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

                Section(trimmedQuery.isEmpty ? "Popular apps" : "Results") {
                    if filtered.isEmpty {
                        ContentUnavailableView.search(text: trimmedQuery)
                    } else {
                        ForEach(filtered) { app in
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
                            .disabled(
                                CoverageCatalog.packageURL(for: app) == nil
                            )
                        }
                    }
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
