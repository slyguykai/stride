import Foundation
import Observation
import SwiftData
import SwiftUI
import UIKit

@Observable
@MainActor
final class NowViewModel {
    private let modelContext: ModelContext

    private(set) var tasks: [Task] = []
    private(set) var isLoading = false
    var selectedTask: Task?
    var showDeferSheet = false
    var taskToDefer: Task?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadTasks() {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(descriptor)
            tasks = rankTasks(allTasks.filter { $0.status == .active })
        } catch {
            tasks = []
        }
    }

    func complete(_ task: Task) async {
        task.status = .completed
        task.completedAt = Date()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        try? modelContext.save()
        loadTasks()
    }

    func showDefer(_ task: Task) {
        taskToDefer = task
        showDeferSheet = true
    }

    func deferTask(_ task: Task, reason: DeferReason) {
        task.status = .deferred
        task.deferCount += 1
        let event = DeferEvent(reason: reason, task: task)
        task.deferEvents.append(event)
        modelContext.insert(event)
        try? modelContext.save()
        showDeferSheet = false
        taskToDefer = nil
        loadTasks()
    }

    private func rankTasks(_ tasks: [Task]) -> [Task] {
        tasks
            .map { ($0, calculateDoabilityScore(task: $0)) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
    }

    func cardSize(for task: Task) -> TaskCardSize {
        let score = calculateDoabilityScore(task: task)
        switch score {
        case 70...:
            return .large
        case 40..<70:
            return .medium
        default:
            return .small
        }
    }

    private func calculateDoabilityScore(task: Task) -> Float {
        var score: Float = 0
        score += recencyBoost(task.createdAt)

        if currentEnergyLevel() == task.energyLevel {
            score += 20
        }

        if task.estimatedMinutes < 5 {
            score += 15
        }

        if task.dependencies.isEmpty {
            score += 25
        }

        if let deadline = task.deadline {
            score += deadlineProximityBoost(deadline)
        }

        score -= Float(task.deferCount) * 5

        if task.status == .waiting {
            return -1000
        }

        return score
    }

    private func recencyBoost(_ createdAt: Date) -> Float {
        let hours = max(1, Float(Date().timeIntervalSince(createdAt) / 3600))
        return max(0, 20 - hours)
    }

    private func deadlineProximityBoost(_ deadline: Date) -> Float {
        let hoursToDeadline = Float(deadline.timeIntervalSinceNow / 3600)
        if hoursToDeadline <= 0 { return 30 }
        return max(0, 30 - hoursToDeadline)
    }

    private func currentEnergyLevel() -> EnergyLevel {
        .medium
    }
}
