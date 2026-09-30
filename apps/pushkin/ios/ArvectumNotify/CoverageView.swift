import Foundation
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
        switch bundleIdentifier {
        case "ph.telegra.Telegraph":
            return "Telegram"
        case "net.whatsapp.WhatsApp":
            return "WhatsApp"
        case "ru.ozon.OzonStore":
            return "Ozon"
        case "ru.yandex.ytaxi":
            return "Yandex Go"
        default:
            let display = displayName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (display?.isEmpty == false ? display : nil) ?? name
        }
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
    }

    static func packageURL(for entry: CoverageCatalogEntry) -> URL? {
        bundledURL(filename: entry.packageFile, isMicro: true)
    }

    private static func bundledURL(
        filename: String,
        isMicro: Bool
    ) -> URL? {
        let subdirectories = isMicro
            ? ["", "Coverage/Micro", "Micro", "Coverage"]
            : ["", "Coverage"]

        if let resourceURL = Bundle.main.resourceURL {
            for subdirectory in subdirectories {
                let directory = subdirectory.isEmpty
                    ? resourceURL
                    : resourceURL.appendingPathComponent(
                        subdirectory,
                        isDirectory: true
                    )
                let candidate = directory.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
        }

        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: filename,
                withExtension: nil,
                subdirectory: subdirectory.isEmpty ? nil : subdirectory
            ) {
                return url
            }
        }

        return nil
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

struct CoverageAppPicker: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var pendingLocalPackageURL: URL?
    @State private var pendingApp: CoverageCatalogEntry?
    @State private var showManualGuide = false
    @FocusState private var searchFocused: Bool

    let onOpenPack: (CoverageCatalogEntry) -> Void

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var catalogResults: [CoverageCatalogEntry] {
        let matches: [CoverageCatalogEntry]

        if trimmedQuery.isEmpty {
            matches = Array(CoverageCatalog.commonEntries.prefix(4))
        } else {
            matches = CoverageCatalog.entries.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedQuery)
                    || $0.name.localizedCaseInsensitiveContains(trimmedQuery)
                    || $0.bundleIdentifier
                        .localizedCaseInsensitiveContains(trimmedQuery)
            }
        }

        return Array(matches.prefix(5))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search apps", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .accessibilityIdentifier("app-search")

                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
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
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if catalogResults.isEmpty {
                    missingAppState
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trimmedQuery.isEmpty ? "Popular apps" : "In PUSHKIN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ArvectumCard {
                            VStack(spacing: 0) {
                                ForEach(catalogResults) { app in
                                    Button {
                                        open(app)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(app.title)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.tertiary)
                                        }
                                        .frame(height: 44)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(CoverageCatalog.packageURL(for: app) == nil)

                                    if app.id != catalogResults.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }

                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 0)
            }
            .background(Color.arvectumBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if !trimmedQuery.isEmpty {
                    manualAddButton
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.arvectumBackground)
                }
            }
            .navigationTitle("Add App")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showManualGuide) {
                ManualCoverageGuide(appName: trimmedQuery)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        searchFocused = false
                    }
                    .accessibilityIdentifier("app-search-done")
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

    private var manualAddButton: some View {
        Button {
            searchFocused = false
            showManualGuide = true
        } label: {
            Label(
                catalogResults.isEmpty
                    ? "Add manually"
                    : "Not listed? Add manually",
                systemImage: "hand.tap"
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("manual-add-app")
    }

    private var missingAppState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 18)

            Image(systemName: "square.dashed")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text("Not in this version")
                .font(.headline)

            Spacer(minLength: 18)
        }
        .padding(.horizontal, 24)
    }

    private func open(_ app: CoverageCatalogEntry) {
        guard let url = CoverageCatalog.packageURL(for: app) else {
            return
        }

        searchFocused = false
        pendingApp = app
        pendingLocalPackageURL = url
    }

}

struct ManualCoverageGuide: View {
    @Environment(\.openURL) private var openURL

    let appName: String

    private let automationsURL = URL(string: "shortcuts://automations")!

    var body: some View {
        VStack(spacing: 12) {
            if !appName.isEmpty {
                Text(appName)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.top, 4)
            }

            ArvectumCard {
                VStack(spacing: 12) {
                    step(1, "Automation → Notification → choose app.")
                    step(2, "Add PUSHKIN → Archive Notification.")
                    step(3, "Map App, Title, Subtitle and Text.")
                    step(4, "Run immediately, then save.")
                }
            }

            Button {
                openURL(automationsURL)
            } label: {
                Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("open-manual-automations")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.arvectumBackground.ignoresSafeArea())
        .navigationTitle("Add Manually")
        .navigationBarTitleDisplayMode(.inline)
        .tint(.arvectumMint)
        .accessibilityIdentifier("manual-coverage-guide")
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(Color.arvectumNavy)
                .frame(width: 24, height: 24)
                .background(Color.arvectumMint, in: Circle())

            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
