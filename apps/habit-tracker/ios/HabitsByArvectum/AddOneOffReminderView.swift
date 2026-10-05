import SwiftData
import SwiftUI
import UIKit

struct AddOneOffReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    let reminder: OneOffReminder?

    @State private var title: String
    @State private var dueAt: Date
    @State private var requestingPermission = false
    @State private var showingNotificationDenied = false
    @FocusState private var titleFocused: Bool

    init(reminder: OneOffReminder? = nil) {
        self.reminder = reminder
        _title = State(initialValue: reminder?.title ?? "")

        let initialDate = reminder?.dueAt ?? Calendar.autoupdatingCurrent.date(
            byAdding: .hour,
            value: 1,
            to: .now
        ) ?? Date().addingTimeInterval(3600)
        _dueAt = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        L10n.string("oneoff.title.placeholder"),
                        text: $title
                    )
                    .focused($titleFocused)
                    .submitLabel(.done)
                }

                Section {
                    DatePicker(
                        L10n.string("oneoff.dateTime"),
                        selection: $dueAt,
                        in: dateRangeLowerBound...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text(L10n.string("oneoff.when"))
                } footer: {
                    Text(L10n.string("oneoff.hint"))
                }
            }
            .navigationTitle(
                reminder == nil
                    ? L10n.string("oneoff.new.title")
                    : L10n.string("oneoff.edit.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if reminder == nil {
                    titleFocused = true
                }
            }
            .alert(
                L10n.string("notification.denied.title"),
                isPresented: $showingNotificationDenied
            ) {
                Button(L10n.string("notification.openSettings")) {
                    guard let url = URL(
                        string: UIApplication.openSettingsURLString
                    ) else { return }
                    openURL(url)
                }
                Button(L10n.string("common.cancel"), role: .cancel) {}
            } message: {
                Text(L10n.string("oneoff.notification.denied.message"))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(L10n.string("common.cancel"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel(L10n.string("common.save"))
                    .disabled(!canSave)
                }
            }
        }
    }

    private var dateRangeLowerBound: Date {
        guard let reminder else { return Date() }
        return min(reminder.dueAt, Date())
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        dueAt > Date() &&
        !requestingPermission
    }

    private func save() {
        guard canSave else { return }

        requestingPermission = true
        Task {
            let granted = await HabitReminderScheduler.ensureAuthorization()
            await MainActor.run {
                requestingPermission = false
                guard granted else {
                    showingNotificationDenied = true
                    return
                }

                let trimmed = title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                if let reminder {
                    reminder.title = trimmed
                    reminder.dueAt = dueAt
                    reminder.isCompleted = false
                    reminder.completedAt = nil
                } else {
                    modelContext.insert(
                        OneOffReminder(
                            title: trimmed,
                            dueAt: dueAt
                        )
                    )
                }

                try? modelContext.save()
                HabitReminderCoordinator.shared.dataDidChange()
                dismiss()
            }
        }
    }
}
