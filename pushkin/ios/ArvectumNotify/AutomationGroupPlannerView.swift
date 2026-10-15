import SwiftUI
import UIKit

/// Offline checklist for people who WANT several small Notification triggers.
/// It cannot inspect installed apps, create automations or attest that they
/// are enabled. Signed base/micro shortcuts remain the recommended setup.
struct AutomationGroupPlannerView: View {
    @AppStorage("coverage.optionalGroupSelection.v1")
    private var savedSelectionJSON = "[]"

    @State private var search = ""

    private let automationsURL = URL(string: "shortcuts://automations")!

    private var selectedIDs: [String] {
        AutomationGroupPlan.decode(savedSelectionJSON)
    }

    private var selectedEntries: [CoverageCatalogEntry] {
        let byID = Dictionary(uniqueKeysWithValues: CoverageCatalog.entries.map {
            ($0.bundleIdentifier, $0)
        })
        return selectedIDs.compactMap { byID[$0] }
    }

    private var selectedGroups: [[CoverageCatalogEntry]] {
        AutomationGroupPlan.groups(selectedEntries)
    }

    private var results: [CoverageCatalogEntry] {
        let value = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return CoverageCatalog.commonEntries
        }
        return Array(CoverageCatalog.entries.filter {
            $0.title.localizedCaseInsensitiveContains(value)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(value)
        }.prefix(60))
    }

    var body: some View {
        List {
            Section("How it works") {
                Label("Optional: plan smaller groups", systemImage: "square.stack.3d.up")
                    .font(.headline)

                Text(
                    "PUSHKIN's signed base shortcut already contains 1,000 app entries. An iOS 27 test retained all of them in one trigger. 25 is a convenient group size, not a confirmed iOS limit."
                )
                .foregroundStyle(.secondary)

                Text(
                    "Choose only apps you have installed. This page plans groups locally; it cannot add or activate Shortcuts automations for you."
                )
                .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Selected apps", value: "\(selectedEntries.count)")
                LabeledContent("Suggested groups", value: "\(selectedGroups.count)")
            } header: {
                Text("Your plan")
            } footer: {
                Text("No notifications or selected app lists leave your iPhone.")
            }

            if !selectedGroups.isEmpty {
                Section("Groups to configure") {
                    ForEach(selectedGroups.indices, id: \.self) { index in
                        AutomationGroupRow(
                            index: index,
                            entries: selectedGroups[index]
                        )
                    }

                    Link(destination: automationsURL) {
                        Label("Configure manually in Shortcuts", systemImage: "arrow.up.forward.app")
                    }
                    .accessibilityIdentifier("open-group-automations")

                    Text(
                        "Create a Notification automation for each group. Select its apps, add PUSHKIN → Archive Notification, map App / Title / Subtitle / Text, then enable it. Copying names is only a checklist; Shortcuts still requires manual app selection."
                    )
                    .foregroundStyle(.secondary)

                    Text(
                        "Send a real notification from one app in each group and check that it appears in History. One captured app does not verify every app in its group."
                    )
                    .foregroundStyle(.secondary)
                }
            }

            Section("Choose apps for groups") {
                TextField("Search catalog", text: $search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("group-app-search")

                ForEach(results) { entry in
                    Button {
                        savedSelectionJSON = AutomationGroupPlan.encode(
                            AutomationGroupPlan.toggle(
                                entry.bundleIdentifier,
                                in: selectedIDs
                            )
                        )
                    } label: {
                        HStack {
                            Text(entry.title)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(
                                systemName: selectedIDs.contains(entry.bundleIdentifier)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundStyle(Color.arvectumMint)
                        }
                    }
                    .accessibilityIdentifier("group-select-\(entry.bundleIdentifier)")
                }
            }

            if !selectedIDs.isEmpty {
                Section {
                    Button("Clear group plan", role: .destructive) {
                        savedSelectionJSON = "[]"
                    }
                    .accessibilityIdentifier("clear-group-plan")
                } footer: {
                    Text("Clearing this local checklist does not remove any automation or notification history.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.arvectumBackground)
        .navigationTitle("Optional Groups")
        .navigationBarTitleDisplayMode(.inline)
        .tint(.arvectumMint)
        .accessibilityIdentifier("automation-group-planner")
    }
}


private struct AutomationGroupRow: View {
    let index: Int
    let entries: [CoverageCatalogEntry]

    var body: some View {
        DisclosureGroup {
            ForEach(entries) { entry in
                Text(entry.title)
            }
            Button {
                UIPasteboard.general.string = entries
                    .map(\.title)
                    .joined(separator: "\n")
            } label: {
                Label("Copy app names", systemImage: "doc.on.doc")
            }
            .accessibilityIdentifier("copy-group-\(index + 1)")
        } label: {
            HStack {
                Text("Group \(index + 1)")
                Spacer()
                Text("\(entries.count) apps")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("optional-group-\(index + 1)")
    }
}
