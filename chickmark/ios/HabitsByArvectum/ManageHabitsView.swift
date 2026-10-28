import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ManageHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @AppStorage(ChickMarkGroups.storageKey) private var groupSettings = Data()
    @AppStorage(ChickMarkLanguage.storageKey) private var preferredLanguage = ChickMarkLanguage.system
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
                if dynamicTypeSize.isAccessibilitySize {
                    // Pinning four preferences rows to the bottom consumes
                    // the entire viewport at AXXXL and clips their text.
                    ScrollView {
                        VStack(spacing: 12) {
                            ContentUnavailableView(
                                L10n.string("manage.empty.title"),
                                systemImage: "tray",
                                description: Text(
                                    L10n.string("manage.empty.description")
                                )
                            )
                            preferencesPanel
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ContentUnavailableView(
                        L10n.string("manage.empty.title"),
                        systemImage: "tray",
                        description: Text(
                            L10n.string("manage.empty.description")
                        )
                    )
                }
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
                            if !dynamicTypeSize.isAccessibilitySize {
                                Button(role: .destructive) {
                                    ChickMarkGroups.delete(id: group.id)
                                } label: {
                                    Label(L10n.string("groups.delete.short"),
                                          systemImage: "folder.badge.minus")
                                }
                                .font(.footnote)
                                .accessibilityHint(L10n.string("groups.delete.keepHint"))
                            }
                            if dynamicTypeSize.isAccessibilitySize {
                                HStack {
                                    Spacer(minLength: 0)
                                    Menu {
                                        Button(role: .destructive) {
                                            ChickMarkGroups.delete(id: group.id)
                                        } label: {
                                            Label(L10n.string("groups.delete"),
                                                  systemImage: "folder.badge.minus")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .frame(minWidth: 48, minHeight: 48)
                                            .contentShape(Rectangle())
                                    }
                                    .accessibilityLabel(L10n.string("groups.actions"))
                                    .accessibilityHint(L10n.string("groups.delete.keepHint"))
                                    .accessibilityIdentifier("chickmark.group.actions")
                                }
                            }
                        } header: {
                            Text(group.name)
                                .fixedSize(horizontal: false, vertical: true)
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

                    if dynamicTypeSize.isAccessibilitySize {
                        Section {
                            preferencesPanel
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(L10n.string("manage.title"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                preferencesPanel
            }
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

    /// Compact device preferences. Gentle Restart never mutates history.
    private var preferencesPanel: some View {
        VStack(spacing: 0) {
            languageSelector
            Divider()
                .padding(.leading, 52)

            NavigationLink {
                GentleRestartSettingsView()
            } label: {
                Label(L10n.string("restart.settings.title"), systemImage: "arrow.uturn.forward.circle")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manage.gentle-restart")
            Divider()
                .padding(.leading, 52)

            NavigationLink {
                ChickMarkWeeklySummaryView()
            } label: {
                Label(L10n.string("weekly.title"), systemImage: "chart.bar.xaxis")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manage.weekly-summary")
            Divider()
                .padding(.leading, 52)

            NavigationLink {
                ChickMarkAboutView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.habitsSecondaryText)
                        .frame(width: 22)
                    Text(L10n.string("manage.about"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.habitsSecondaryText)
                }
                .frame(minHeight: 48)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("manage.about")
        }
        .background(
            Color.habitsSurface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.habitsBackground)
    }

    private var languageSelector: some View {
        Menu {
            Picker(L10n.string("language.title"), selection: $preferredLanguage) {
                Text(L10n.string("language.system"))
                    .tag(ChickMarkLanguage.system)
                ForEach(ChickMarkLanguage.supported, id: \.self) { identifier in
                    Text(ChickMarkLanguage.displayName(for: identifier))
                        .tag(identifier)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.habitsSecondaryText)
                    .frame(width: 22)
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string("language.title"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(ChickMarkLanguage.displayName(for: preferredLanguage))
                            .font(.subheadline)
                            .foregroundStyle(Color.habitsSecondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                } else {
                    Text(L10n.string("language.title"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Text(ChickMarkLanguage.displayName(for: preferredLanguage))
                        .font(.subheadline)
                        .foregroundStyle(Color.habitsSecondaryText)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.habitsSecondaryText)
            }
            .frame(minHeight: 48)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("manage.language")
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


// Brand identity and legal/help links are intentionally separate from habit
// management. Original Arvectum wordmark asset; no substitute emblem.
private struct ChickMarkAboutView: View {
    @State private var webPage: ChickMarkWebPage?
#if DEBUG
    @AppStorage(HabitAdDiagnosticStore.statusKey) private var adStatus = "not_requested"
    @AppStorage(HabitAdDiagnosticStore.unitKey) private var adUnit = ""
    @AppStorage(HabitAdDiagnosticStore.errorKey) private var adError = ""
#endif

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image("ChickMarkMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78, height: 78)
                        .accessibilityHidden(true)

                    Text("ChickMark")
                        .font(.custom("PTSans-Bold", size: 30, relativeTo: .title))

                    HStack(spacing: 4) {
                        Text("by")
                            .font(.caption)
                            .foregroundStyle(Color.habitsSecondaryText)
                        Image("ArvectumTypeOnly")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 103, height: 24)
                            .accessibilityLabel("Arvectum")
                    }

                    Text("v" + version)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.habitsSecondaryText)
                        .accessibilityIdentifier("chickmark.version")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 35)

                VStack(spacing: 0) {
                    aboutLink(
                        L10n.string("manage.privacy"),
                        systemImage: "lock.shield",
                        url: URL(string: "https://arvectum.com/privacy")!,
                        identifier: "manage.privacy"
                    )
                    Divider()
                        .padding(.leading, 52)
                    aboutLink(
                        L10n.string("manage.support"),
                        systemImage: "questionmark.circle",
                        url: URL(string: "https://arvectum.com/contact.html")!,
                        identifier: "manage.support"
                    )
                }
                .background(
                    Color.habitsSurface,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

#if DEBUG
                DisclosureGroup(L10n.string("ads.debug.title")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(adUnit.isEmpty ? (HabitAdUnitIDs.native ?? "—") : adUnit)
                            .font(.caption.monospaced())
                        Text(L10n.string("ads.debug.state") + ": " + adStatus)
                            .font(.caption)
                        if !adError.isEmpty {
                            Text(adError)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
                .font(.footnote)
                .foregroundStyle(Color.habitsSecondaryText)
                .accessibilityIdentifier("ads.debug")
#endif
            }
            .padding(.horizontal, 16)
        }
        .background(Color.habitsBackground)
        .navigationTitle(L10n.string("manage.about"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $webPage) { page in
            ChickMarkWebSheet(page: page)
        }
    }

    private func aboutLink(
        _ title: String, systemImage: String, url: URL, identifier: String
    ) -> some View {
        Button {
            webPage = ChickMarkWebPage(url: url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.habitsSecondaryText)
                    .frame(width: 22)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.habitsSecondaryText)
            }
            .frame(minHeight: 50)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
