import SwiftData

enum ModelContainerFactory {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            Subtask.self,
            TaskDependency.self,
            DeferEvent.self,
            UserPattern.self,
            RecurringRule.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
