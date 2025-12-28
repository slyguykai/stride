import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class TaskDetailViewModel {
    private let task: Task
    private let modelContext: ModelContext

    var blockers: [Task] = []

    init(task: Task, modelContext: ModelContext) {
        self.task = task
        self.modelContext = modelContext
    }

    func toggleSubtask(_ subtask: Subtask) async {
        subtask.isCompleted.toggle()
        try? modelContext.save()
    }

    func markWaiting() {
        task.status = .waiting
        try? modelContext.save()
    }

    func delete() {
        modelContext.delete(task)
        try? modelContext.save()
    }
}
