import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ManageHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @AppStorage(ChickMarkGroups.storageKey) private var groupSettings = Data()
    @State private var showingAddGroup = false
    @State private var newGroupName = ""
    @State private var backupDocument: ChickMarkBackupDocument?
    @State private var showingExport = false
    @State private var showingImport = false
    @State private var pendingImport: ChickMarkBackup?
    @State private var showingImportChoice = false
    @State private var backupMessage: String?
    @State private var showingBackupMessage = false

    private var groups: [ChickMarkGroup] {
        ChickMarkGroups.decode(groupSettings)
    }

    private var ungroupedHabits: [Habit] {
        let memberIDs = Set(groups.flatMap(\.habitIDs))
        return activeHabits.filter { !memberIDs.contains($0.id) }
    }

    private var activeHabits: [Habit] {
        HabitOrdering.sorted(
            habits.filter { !$0.isArchived && !$0.isPaused }
        )
    }

    private var pausedHabits: [Habit] {
        HabitOrdering.sorted(
            habits.filter { !$0.isArchived && $0.isPaused }
        )
    }

    private var archivedHabits: [Habit] {
        HabitOrdering.sorted(habits.filter(\.isArchived))
    }

    var body: some View {
        Group {
            if habits.isEmpty {
                ContentUnavailableView(
                    L10n.string("manage.empty.title"),
                    systemImage: "tray",
                    description: Text(
                        L10n.string("manage.empty.description")
                    )
                )
            } else {
                List {
                    ForEach(groups) { group in
                        let members = activeHabits.filter {
                            group.habitIDs.contains($0.id)
                        }
                        Section {
                            ForEach(members) { habit in
                                habitLink(habit)
                            }
                            Button(role: .destructive) {
                                ChickMarkGroups.delete(id: group.id)
                            } label: {
                                Label(
                                    L10n.string("groups.delete"),
                                    systemImage: "folder.badge.minus"
                                )
                            }
                            .font(.footnote)
                        } header: {
                            Text(group.name)
                        }
                    }

                    if !ungroupedHabits.isEmpty {
                        Section {
                            Text(L10n.string("manage.active"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .accessibilityAddTraits(.isHeader)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 4,
                                        leading: 20,
                                        bottom: 2,
                                        trailing: 20
                                    )
                                )

                            ForEach(ungroupedHabits) { habit in
                                habitLink(habit)
                            }
                            .onMove(perform: moveActiveHabits)
                        } footer: {
                            if activeHabits.count > 1 {
                                Text(L10n.string("manage.reorder.hint"))
                                    .foregroundStyle(Color.habitsSecondaryText)
                            }
                        }
                    }

                    if !pausedHabits.isEmpty {
                        Section(L10n.string("manage.paused")) {
                            ForEach(pausedHabits) { habit in
                                habitLink(habit)
                            }
                        }
                    }

                    if !archivedHabits.isEmpty {
                        Section(L10n.string("archive.title")) {
                            ForEach(archivedHabits) { habit in
                                habitLink(habit)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(L10n.string("manage.title"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            supportLinks
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if activeHabits.count > 1 { EditButton() }
                Menu {
                    Button {
                        newGroupName = ""
                        showingAddGroup = true
                    } label: {
                        Label(L10n.string("groups.add"), systemImage: "folder.badge.plus")
                    }
                    Button {
                        do {
                            backupDocument = ChickMarkBackupDocument(
                                backup: try ChickMarkBackupService.capture(from: modelContext)
                            )
                            showingExport = true
                        } catch { reportBackupError(error) }
                    } label: {
                        Label(L10n.string("backup.export"), systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingImport = true
                    } label: {
                        Label(L10n.string("backup.import"), systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "externaldrive")
                }
                .accessibilityLabel(L10n.string("backup.menu"))
            }
        }
        .alert(
            L10n.string("groups.add"),
            isPresented: $showingAddGroup
        ) {
            TextField(L10n.string("groups.placeholder"), text: $newGroupName)
            Button(L10n.string("common.save")) {
                _ = ChickMarkGroups.create(name: newGroupName)
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        }
        .fileExporter(
            isPresented: $showingExport,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "ChickMark-backup"
        ) { result in
            if case .failure(let error) = result { reportBackupError(error) }
            backupDocument = nil
        }
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.json]
        ) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                guard data.count <= 20_000_000 else { throw BackupError.invalidData }
                let decoded = try JSONDecoder().decode(ChickMarkBackup.self, from: data)
                try decoded.validate()
                pendingImport = decoded
                showingImportChoice = true
            } catch { reportBackupError(error) }
        }
        .confirmationDialog(
            L10n.string("backup.chooseMode"),
            isPresented: $showingImportChoice,
            titleVisibility: .visible
        ) {
            Button(L10n.string("backup.merge")) { finishImport(mode: .merge) }
            Button(L10n.string("backup.replace"), role: .destructive) {
                finishImport(mode: .replace)
            }
            Button(L10n.string("common.cancel"), role: .cancel) { pendingImport = nil }
        } message: {
            Text(L10n.string("backup.warning"))
        }
        .alert(
            L10n.string("backup.result"),
            isPresented: $showingBackupMessage
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupMessage ?? "")
        }
    }

    private func reportBackupError(_ error: Error) {
        backupMessage = error.localizedDescription
        showingBackupMessage = true
    }

    private func finishImport(mode: ChickMarkBackupService.ImportMode) {
        guard let backup = pendingImport else { return }
        pendingImport = nil
        do {
            try ChickMarkBackupService.restore(
                backup, to: modelContext, mode: mode
            )
            backupMessage = L10n.string("backup.success")
            showingBackupMessage = true
        } catch { reportBackupError(error) }
    }

    private var supportLinks: some View {
        HStack(spacing: 10) {
            Button {
                openURL(
                    URL(string: "https://arvectum.com/privacy")!
                )
            } label: {
                Text(L10n.string("manage.privacy"))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manage.privacy")

            Button {
                openURL(
                    URL(string: "https://arvectum.com/contact.html")!
                )
            } label: {
                Text(L10n.string("manage.support"))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manage.support")
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color(uiColor: .systemBackground))
    }

    private func habitLink(_ habit: Habit) -> some View {
        NavigationLink {
            HabitDetailView(habit: habit)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            Color(hex: habit.colorHex)
                                .opacity(0.16)
                        )
                    Image(systemName: habit.symbolName)
                        .foregroundStyle(
                            Color.habitsReadableAccent(for: habit.colorHex)
                        )
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(
                        habit.isPaused && !habit.isArchived
                            ? L10n.string("manage.paused")
                            : HabitScheduleText.description(for: habit)
                    )
                    .font(.caption)
                    .foregroundStyle(Color.habitsSecondaryText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func moveActiveHabits(
        from source: IndexSet,
        to destination: Int
    ) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, habit) in reordered.enumerated() {
            habit.sortOrder = index
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }
}
