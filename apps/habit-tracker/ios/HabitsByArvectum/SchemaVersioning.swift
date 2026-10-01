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

enum HabitsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HabitsSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

enum HabitsSchema {
    static var current: Schema {
        Schema(versionedSchema: HabitsSchemaV1.self)
    }
}
