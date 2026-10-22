import SwiftUI
import UIKit

/// Offline checklist for people who WANT several small Notification triggers.
/// It cannot inspect installed apps, create automations or attest that they
/// are enabled. Signed base/micro shortcuts remain the recommended setup.
struct AutomationGroupPlannerView: View {
    @AppStorage("coverage.optionalGroupSelection.v1")
    private var savedSelectionJSON = "[]"

    @State private var search = ""
    @FocusState private var searchIsFocused: Bool

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
            Section {
                LabeledContent(pc("Selected apps"), value: "\(selectedEntries.count)")
                LabeledContent(pc("Suggested groups"), value: "\(selectedGroups.count)")
                Text(pc("Your group plan is stored locally in PUSHKIN. Copying app names uses the system clipboard."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(pc("Your plan"))
            }

            Section(pc("Choose apps for groups")) {
                TextField(pc("Search catalog"), text: $search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchIsFocused)
                    .submitLabel(.done)
                    .onSubmit { searchIsFocused = false }
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
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Image(
                                systemName: selectedIDs.contains(entry.bundleIdentifier)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundStyle(Color.arvectumInteractiveTint)
                        }
                    }
                    .accessibilityIdentifier("group-select-\(entry.bundleIdentifier)")
                    .accessibilityValue(selectedIDs.contains(entry.bundleIdentifier)
                        ? pc("Selected") : pc("Not selected"))
                    .accessibilityAddTraits(selectedIDs.contains(entry.bundleIdentifier)
                        ? [.isSelected] : [])
                }
            }

            if !selectedGroups.isEmpty {
                Section(pc("Groups to configure")) {
                    ForEach(selectedGroups.indices, id: \.self) { index in
                        AutomationGroupRow(
                            index: index,
                            entries: selectedGroups[index]
                        )
                    }

                    Link(destination: automationsURL) {
                        Label(pc("Configure manually in Shortcuts"), systemImage: "arrow.up.forward.app")
                    }
                    .accessibilityIdentifier("open-group-automations")

                    Text(
                        pc("Create a Notification automation for each group. Select its apps, add PUSHKIN → Archive Notification, map App / Title / Subtitle / Text, then enable it. Copying names is only a checklist; Shortcuts still requires manual app selection.")
                    )
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    Text(
                        pc("Send a real notification from one app in each group and check that it appears in History. One captured app does not verify every app in its group.")
                    )
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section(pc("How it works")) {
                Label(pc("Optional: plan smaller groups"), systemImage: "square.stack.3d.up")
                    .font(.headline)

                Text(
                    pc("PUSHKIN's signed base shortcut already contains 1,000 app entries. An iOS 27 test retained all of them in one trigger. 25 is a convenient group size, not a confirmed iOS limit.")
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Text(
                    pc("Choose only apps you have installed. This page plans groups locally; it cannot add or activate Shortcuts automations for you.")
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            if !selectedIDs.isEmpty {
                Section {
                    Button(pc("Clear group plan"), role: .destructive) {
                        savedSelectionJSON = "[]"
                    }
                    .accessibilityIdentifier("clear-group-plan")
                    Text(pc("Clearing this local checklist does not remove any automation or notification history."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.arvectumBackground)
        .navigationTitle(pc("Optional Groups"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(.arvectumInteractiveTint)
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
                Label(pc("Copy app names"), systemImage: "doc.on.doc")
            }
            .accessibilityIdentifier("copy-group-\(index + 1)")
        } label: {
            HStack {
                Text(String(format: pc("Group %d"), index + 1))
                Spacer()
                Text(PushkinCopy.appCount(entries.count))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("optional-group-\(index + 1)")
    }
}
