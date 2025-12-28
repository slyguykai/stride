import SwiftData

@MainActor
enum SampleDataSeeder {
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Task>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let task = Task(
            rawInput: "order contacts, need to take prescription renewal phone exam",
            title: "Order contacts from 1-800 Contacts",
            energyLevel: .low,
            estimatedMinutes: 10,
            status: .active,
            taskType: .obligation
        )
        let subtask1 = Subtask(title: "Take vision exam on phone", order: 0, parentTask: task)
        let subtask2 = Subtask(title: "Submit prescription", order: 1, parentTask: task)
        let subtask3 = Subtask(title: "Place order", order: 2, parentTask: task)
        task.subtasks = [subtask1, subtask2, subtask3]

        let aspirational = Task(
            rawInput: "learn watercolor basics",
            title: "Practice watercolor basics",
            energyLevel: .medium,
            estimatedMinutes: 30,
            status: .active,
            taskType: .aspirational
        )

        modelContext.insert(task)
        modelContext.insert(subtask1)
        modelContext.insert(subtask2)
        modelContext.insert(subtask3)
        modelContext.insert(aspirational)

        do {
            try modelContext.save()
        } catch {
            // Seeding failure should not block app usage.
        }
    }
}
