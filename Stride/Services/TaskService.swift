import Foundation
import SwiftData

protocol TaskServiceProtocol {
    func createTask(from parsed: ParsedTask, rawInput: String) async throws -> Task
    func fetchActiveTasks() async throws -> [Task]
    func complete(_ task: Task) async throws
}

@MainActor
final class TaskService: TaskServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createTask(from parsed: ParsedTask, rawInput: String) async throws -> Task {
        let task = Task(
            rawInput: rawInput,
            title: parsed.title,
            notes: "",
            energyLevel: parsed.energyLevel,
            estimatedMinutes: parsed.estimatedMinutes,
            status: .active,
            taskType: .obligation,
            contextTags: parsed.contextTags
        )

        let subtasks = parsed.subtasks.enumerated().map { index, title in
            Subtask(title: title, order: index, parentTask: task)
        }
        task.subtasks = subtasks

        modelContext.insert(task)
        subtasks.forEach { modelContext.insert($0) }
        try modelContext.save()
        return task
    }

    func fetchActiveTasks() async throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
        )
        let allTasks = try modelContext.fetch(descriptor)
        return allTasks.filter { $0.status == .active }
    }

    func complete(_ task: Task) async throws {
        task.status = .completed
        task.completedAt = Date()
        try modelContext.save()
    }
}
