import SwiftData

enum HabitsSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self,
            HabitPausePeriod.self,
            HabitDayMutation.self
        ]
    }
}

enum HabitsSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self,
            HabitPausePeriod.self,
            HabitDayMutation.self,
            OneOffReminder.self
        ]
    }
}

enum HabitsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HabitsSchemaV1.self, HabitsSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: HabitsSchemaV1.self,
                toVersion: HabitsSchemaV2.self
            )
        ]
    }
}

enum HabitsSchema {
    static var current: Schema {
        Schema(versionedSchema: HabitsSchemaV2.self)
    }
}
