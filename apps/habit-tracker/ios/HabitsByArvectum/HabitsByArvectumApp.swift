import SwiftData
import SwiftUI

@main
struct HabitsByArvectumApp: App {
    @UIApplicationDelegateAdaptor(HabitsAppDelegate.self) private var appDelegate
    private let modelContainer: ModelContainer
    private let storageUnavailable: Bool

    init() {

        let schema = HabitsSchema.current
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--ui-testing")
        let cloudSyncDisabled = isUITesting || arguments.contains(
            "--disable-cloud-sync"
        )
        let bootstrap = Self.bootstrapModelContainer(
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            cloudSyncEnabled: !cloudSyncDisabled,
            forceRecovery: arguments.contains("--simulate-storage-recovery")
        )
        let container = bootstrap.container
        modelContainer = container
        storageUnavailable = bootstrap.storageUnavailable

        guard !bootstrap.storageUnavailable else {
            return
        }

#if DEBUG
        seedWatchSyncDemoIfRequested(container: container)
        seedScreenshotDemoIfRequested(container: container)
        seedOneOffReminderDemoIfRequested(container: container)
        seedFlexibleWeeklyDemoIfRequested(container: container)
        seedReminderSmokeIfRequested(container: container)
        completeFirstIncompleteHabitIfRequested(container: container)
        skipFirstIncompleteHabitIfRequested(container: container)
        HabitMutationDiagnostics.runIfRequested(container: container)
#endif
        if !cloudSyncDisabled {
            ChickMarkGroupsCloudSync.shared.start()
        }
        HabitNotificationActionCoordinator.shared.configure(
            modelContainer: container
        )
        HabitReminderCoordinator.shared.configure(
            modelContainer: container
        )
#if DEBUG
        HabitNotificationActionDiagnostics.runIfRequested(
            container: container
        )
#endif
        PhoneWatchSyncCoordinator.shared.configure(
            modelContainer: container
        )
        HabitWidgetCoordinator.shared.configure(
            modelContainer: container
        )
    }

    private struct ContainerBootstrap {
        let container: ModelContainer
        let storageUnavailable: Bool
    }

    private static func bootstrapModelContainer(
        schema: Schema,
        isStoredInMemoryOnly: Bool,
        cloudSyncEnabled: Bool,
        forceRecovery: Bool
    ) -> ContainerBootstrap {
#if DEBUG
        if forceRecovery {
            return emergencyContainer(schema: schema)
        }
#endif

        let habitsStoreSchema = Schema(
            versionedSchema: HabitsSchemaV1.self
        )
        let oneOffStoreSchema = Schema([OneOffReminder.self])

        let preferredHabits = ModelConfiguration(
            "Habits",
            schema: habitsStoreSchema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )
        let preferredOneOffs = ModelConfiguration(
            "OneOffReminders",
            schema: oneOffStoreSchema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        do {
            return ContainerBootstrap(
                container: try ModelContainer(
                    for: schema,
                    migrationPlan: HabitsMigrationPlan.self,
                    configurations: [preferredHabits, preferredOneOffs]
                ),
                storageUnavailable: false
            )
        } catch {
#if DEBUG
            HabitDebugLog.emit(
                "HABITS_PRIMARY_STORE_FAILED reason=\(error.localizedDescription)"
            )
#endif
        }

        if cloudSyncEnabled {
            let localHabits = ModelConfiguration(
                "Habits",
                schema: habitsStoreSchema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            let localOneOffs = ModelConfiguration(
                "OneOffReminders",
                schema: oneOffStoreSchema,
                isStoredInMemoryOnly: isStoredInMemoryOnly,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )

            do {
                return ContainerBootstrap(
                    container: try ModelContainer(
                        for: schema,
                        migrationPlan: HabitsMigrationPlan.self,
                        configurations: [localHabits, localOneOffs]
                    ),
                    storageUnavailable: false
                )
            } catch {
#if DEBUG
                HabitDebugLog.emit(
                    "HABITS_LOCAL_STORE_FAILED reason=\(error.localizedDescription)"
                )
#endif
            }
        }

        return emergencyContainer(schema: schema)
    }

    private static func emergencyContainer(
        schema: Schema
    ) -> ContainerBootstrap {
        let habitsStoreSchema = Schema(
            versionedSchema: HabitsSchemaV1.self
        )
        let oneOffStoreSchema = Schema([OneOffReminder.self])
        let habitsRecovery = ModelConfiguration(
            "HabitsRecovery",
            schema: habitsStoreSchema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        let oneOffRecovery = ModelConfiguration(
            "OneOffRemindersRecovery",
            schema: oneOffStoreSchema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        do {
            return ContainerBootstrap(
                container: try ModelContainer(
                    for: schema,
                    migrationPlan: HabitsMigrationPlan.self,
                    configurations: [habitsRecovery, oneOffRecovery]
                ),
                storageUnavailable: true
            )
        } catch {
            fatalError(
                "Could not create emergency in-memory SwiftData container: \(error)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            if storageUnavailable {
                StorageRecoveryView()
            } else {
                TodayView()
            }
        }
        .modelContainer(modelContainer)
    }

}
