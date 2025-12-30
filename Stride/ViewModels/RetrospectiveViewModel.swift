import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class RetrospectiveViewModel {
    private let modelContext: ModelContext

    private(set) var completedTasks: [Task] = []
    private(set) var completedByType: [TaskType: Int] = [:]
    private(set) var minutesByType: [TaskType: Int] = [:]
    private(set) var deferReasons: [DeferReason: Int] = [:]
    private(set) var cascadeCount: Int = 0
    private(set) var encouragement: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func load() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.completedAt, order: .reverse)]
        )
        let tasks = (try? modelContext.fetch(descriptor)) ?? []
        let weekAgo = Date().addingTimeInterval(-7 * 86400)
        completedTasks = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= weekAgo
        }
        completedByType = Dictionary(grouping: completedTasks, by: \.taskType)
            .mapValues { $0.count }
        minutesByType = Dictionary(grouping: completedTasks, by: \.taskType)
            .mapValues { $0.reduce(0) { $0 + $1.estimatedMinutes } }

        let deferDescriptor = FetchDescriptor<DeferEvent>(
            sortBy: [SortDescriptor(\DeferEvent.timestamp, order: .reverse)]
        )
        let deferEvents = (try? modelContext.fetch(deferDescriptor)) ?? []
        let recentDefers = deferEvents.filter { $0.timestamp >= weekAgo }
        deferReasons = Dictionary(grouping: recentDefers, by: \.reason)
            .mapValues { $0.count }

        cascadeCount = estimateCascadeCount(from: tasks, since: weekAgo)
        encouragement = buildEncouragement()
    }

    private func estimateCascadeCount(from tasks: [Task], since date: Date) -> Int {
        let dependencies = tasks.flatMap(\.dependencies)
        let blockersCompleted = tasks.filter { $0.completedAt ?? .distantPast >= date }
        let blockerIds = Set(blockersCompleted.map(\.id))
        let unblocked = dependencies.filter { blockerIds.contains($0.blocker.id) }
        return unblocked.count
    }

    private func buildEncouragement() -> String {
        let total = completedTasks.count
        if total >= 20 {
            return "You made serious progress this week. Keep that momentum."
        }
        if total >= 5 {
            return "Steady steps add up. Nice work staying engaged."
        }
        return "Even a few completions matter. Be kind to your pace."
    }
}
