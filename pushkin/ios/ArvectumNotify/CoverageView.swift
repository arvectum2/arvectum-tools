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
        commonEntries(preferredLanguages: Locale.preferredLanguages)
    }

    static func commonEntries(preferredLanguages: [String]) -> [CoverageCatalogEntry] {
        let globalFirst = [
            "ph.telegra.Telegraph", "net.whatsapp.WhatsApp",
            "com.google.Gmail", "com.burbn.instagram",
            "com.hammerandchisel.discord", "org.whispersystems.signal",
            "com.ubercab.UberClient", "com.ubercab.UberEats",
            "doordash.DoorDashConsumer", "com.google.Maps"
        ]
        let russianFirst = [
            "ph.telegra.Telegraph", "net.whatsapp.WhatsApp",
            "ru.ozon.OzonStore", "RU.WILDBERRIES.MOBILEAPP",
            "ru.yandex.ytaxi", "ru.yandex.traffic",
            "ru.doublegis.grymmobile", "com.minsvyaz.gosuslugi",
            "ru.yandex.mobile.search", "ru.yandex.blue.market",
            "ru.mts.mymts", "ru.megafon.lk",
            "ru.beeline.mobile", "ru.sbcs.store",
            "com.vkusvill", "ru.tander.magnit",
            "ru.5ka.browser.app"
        ]
        // The actual offline catalog already has Discord, Instagram, Gmail,
        // Signal, Uber and DoorDash. Surface them up front for non-RU users,
        // rather than shipping duplicate shortcut packages or claiming that
        // Shortcuts can intercept every iOS notification automatically.
        let preferredBundles = preferredLanguages.first?
            .hasPrefix("ru") == true
            ? russianFirst + globalFirst
            : globalFirst + russianFirst
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
    }

    static func packageURL(for entry: CoverageCatalogEntry) -> URL? {
        bundledURL(filename: entry.packageFile, isMicro: true)
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

        if let bundled = Bundle.main.url(
            forResource: filename,
            withExtension: nil
        ) {
            return bundled
        }

        // Apple's bundle resource index can fail for a literal filename
        // containing punctuation, accents or multiple dots, even when the
        // exact .shortcut file was copied into the app. XcodeGen currently
        // flattens the bundled micro-packages to the app resource root.
        guard let root = Bundle.main.resourceURL else { return nil }
        for subdirectory in subdirectories {
            let directory = subdirectory.isEmpty
                ? root
                : root.appendingPathComponent(subdirectory, isDirectory: true)
            let exactFile = directory.appendingPathComponent(
                filename, isDirectory: false
            )
            if FileManager.default.fileExists(atPath: exactFile.path) {
                return exactFile
            }
        }
        let exactFile = root.appendingPathComponent(filename, isDirectory: false)
        return FileManager.default.fileExists(atPath: exactFile.path)
            ? exactFile
            : nil
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
            Section(pc("Offline catalog")) {
                LabeledContent(
                    pc("Signed app options"),
                    value: "\(CoverageCatalog.entries.count)"
                )

                if quickRefreshCount > 0 {
                    LabeledContent(
                        pc("App packages opened"),
                        value: "\(quickRefreshCount)"
                    )
                }

                if !lastQuickRefreshName.isEmpty {
                    LabeledContent(
                        pc("Latest"),
                        value: lastQuickRefreshName
                    )
                }
            }

            Section(pc("Add an app")) {
                Button {
                    showAppPicker = true
                } label: {
                    Label(
                        pc("Add app to PUSHKIN"),
                        systemImage: "plus.app.fill"
                    )
                }

                Text(
                    pc("Importing a signed app package opens Shortcuts but does not enable the new automation. Enable it there and check a real notification. If missing from this catalog, use the manual guide.")
                )
                .foregroundStyle(.secondary)
            }

            Section(pc("Optional groups")) {
                NavigationLink {
                    AutomationGroupPlannerView()
                } label: {
                    Label(pc("Plan smaller groups"), systemImage: "square.stack.3d.up")
                }
                .accessibilityIdentifier("coverage-optional-groups")
                Text(pc("One base shortcut can contain 1,000 app entries. Optional groups of 25 are just a planning convenience, not an iOS limit."))
                    .foregroundStyle(.secondary)
            }

            Section(pc("Shortcuts")) {
                Link(destination: automationsURL) {
                    Label(
                        pc("Open Shortcuts automations"),
                        systemImage: "arrow.up.forward.app"
                    )
                }

                Text(
                    pc("Newly imported automations are disabled. Turn each one on in Shortcuts; PUSHKIN cannot read its enabled state. A notification from one app does not verify every app.")
                )
                .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.arvectumBackground)
        .navigationTitle(pc("Apps"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(.arvectumInteractiveTint)
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

    @State private var query = ""
    @State private var pendingLocalPackageURL: URL?
    @State private var pendingApp: CoverageCatalogEntry?

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

    private var searchSection: some View {
        Section {
            TextField(pc("Search apps"), text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("app-search")
        } footer: {
            Text(
                pc("Searches the offline catalog bundled with this version of PUSHKIN.")
            )
        }
    }

    @ViewBuilder
    private var catalogSection: some View {
        Section(trimmedQuery.isEmpty ? pc("Popular apps") : pc("In PUSHKIN")) {
            if catalogResults.isEmpty {
                ContentUnavailableView(
                    pc("Not in this version"),
                    systemImage: "square.dashed",
                    description: Text(
                        pc("You can still add this app manually in Shortcuts.")
                    )
                )
            } else {
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
    }

    @ViewBuilder
    private var manualSection: some View {
        if !trimmedQuery.isEmpty {
            Section {
                NavigationLink {
                    ManualCoverageGuide(appName: trimmedQuery)
                } label: {
                    Label(
                        catalogResults.isEmpty
                            ? pc("Add manually")
                            : pc("App not listed? Add manually"),
                        systemImage: "hand.tap"
                    )
                }
                .accessibilityIdentifier("manual-add-app")
            } footer: {
                Text(
                    pc("Manual setup takes a few more taps, but stays entirely on your iPhone and needs no PUSHKIN server.")
                )
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                searchSection
                catalogSection
                manualSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.arvectumBackground)
            .navigationTitle(pc("Add App"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(pc("Cancel")) {
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

        pendingApp = app
        pendingLocalPackageURL = url
    }
}

private struct ManualCoverageGuide: View {
    @Environment(\.openURL) private var openURL

    let appName: String

    private let automationsURL = URL(string: "shortcuts://automations")!

    var body: some View {
        List {
            Section {
                Label(
                    pc("This path is only for apps missing from the built-in catalog."),
                    systemImage: "iphone"
                )
                Text(
                    pc("Nothing is uploaded. You create one Notification automation directly in Apple's Shortcuts app.")
                )
                .foregroundStyle(.secondary)
            }

            Section(pc("1. Choose the app")) {
                Text(
                    pc("Open Shortcuts → Automation → + → Notification → App, then choose the app you want to add.")
                )

                Button {
                    openURL(automationsURL)
                } label: {
                    Label(
                        pc("Open Shortcuts Automations"),
                        systemImage: "arrow.up.forward.app"
                    )
                }
                .accessibilityIdentifier("open-manual-automations")

                if !appName.isEmpty {
                    LabeledContent(pc("You searched for"), value: appName)
                }
            }

            Section(pc("2. Add the PUSHKIN action")) {
                Text(
                    pc("Add the action PUSHKIN → Archive Notification.")
                )
            }

            Section(pc("3. Map the notification")) {
                mappingRow(pc("Source app"), "Notification → App")
                mappingRow(pc("Title"), "Notification → Title")
                mappingRow(pc("Subtitle"), "Notification → Subtitle")
                mappingRow(pc("Message"), "Notification → Text")

                Text(
                    pc("When Shortcuts asks how the automation should run, choose the immediate/automatic option.")
                )
                .foregroundStyle(.secondary)
            }

            Section(pc("4. Save")) {
                Text(
                    pc("Save and make sure the new automation is enabled. The first matching notification should then appear in PUSHKIN automatically.")
                )
            }

            Section(pc("Help us improve the catalog")) {
                Text(
                    pc("Want this app to become a one-tap option? Mention its exact name in an App Store review or send it to Arvectum support. Requested apps can be added in regular catalog updates.")
                )
                .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.arvectumBackground)
        .navigationTitle(pc("Add Manually"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(.arvectumInteractiveTint)
        .accessibilityIdentifier("manual-coverage-guide")
    }

    private func mappingRow(
        _ parameter: String,
        _ value: String
    ) -> some View {
        LabeledContent(parameter, value: value)
    }
}
