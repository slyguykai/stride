import Foundation
import Observation
import SwiftData
import SwiftUI
import UIKit

@Observable
@MainActor
final class NowViewModel {
    private let modelContext: ModelContext
    private let notificationScheduler: NotificationSchedulerProtocol
    private let streakTracker = StreakTracker()
    private let aspirationalSurfacing = AspirationalSurfacingService()
    private let contextEngine = ContextEngine()
    
    // Track task start times for completion duration
    private var taskStartTimes: [UUID: Date] = [:]

    private(set) var tasks: [Task] = []
    private(set) var isLoading = false
    var selectedTask: Task?
    var showDeferSheet = false
    var taskToDefer: Task?
    var focusTimeCandidate: FocusTimeCandidate?
    var streakData: StreakData?
    var lastCompletionTitle: String?
    var cascadeCount: Int?
    var showAspirationalSection = false
    var aspirationalTasks: [Task] = []

    init(
        modelContext: ModelContext,
        notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler()
    ) {
        self.modelContext = modelContext
        self.notificationScheduler = notificationScheduler
    }

    func loadTasks() {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<Task>(
                sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
            )
            let allTasks = try modelContext.fetch(descriptor)
            let reactivated = reactivateDeferredTasks(allTasks)
            let waitingDue = reactivated.filter { isWaitingFollowUpDue($0) }
            let activeTasks = reactivated.filter { $0.status == .active }
            tasks = rankTasks(activeTasks + waitingDue)
            focusTimeCandidate = evaluateFocusTimeCandidate(from: reactivated)
            streakData = streakTracker.currentData()
            showAspirationalSection = aspirationalSurfacing.shouldSurfaceAspirational(tasks: reactivated)
            aspirationalTasks = reactivated.filter { $0.taskType == .aspirational }
        } catch {
            tasks = []
        }
    }

    func complete(_ task: Task) async {
        task.status = .completed
        task.completedAt = Date()
        let count = updateCascade(for: task)
        cascadeCount = count
        
        // Haptic feedback - cascade effect if tasks were unblocked
        if count > 0 {
            HapticEngine.shared.cascadeEffect(count: count)
        } else {
            HapticEngine.shared.taskComplete()
        }
        
        AudioManager.shared.play(.completeMajor)
        lastCompletionTitle = task.title
        streakData = streakTracker.recordCompletion(on: task.completedAt ?? Date())
        try? modelContext.save()
        
        // Record completion for learning
        let timeToComplete = taskStartTimes[task.id].map { Date().timeIntervalSince($0) }
        await contextEngine.recordCompletion(for: task, timeToComplete: timeToComplete)
        taskStartTimes.removeValue(forKey: task.id)
        
        loadTasks()
    }

    func showDefer(_ task: Task) {
        taskToDefer = task
        showDeferSheet = true
    }

    func deferTask(_ task: Task, reason: DeferReason, until: Date?) async {
        task.status = .deferred
        task.deferCount += 1
        task.deferUntil = until
        let event = DeferEvent(reason: reason, proposedTime: until, task: task)
        task.deferEvents.append(event)
        modelContext.insert(event)
        try? modelContext.save()
        if let until {
            let preferences = NotificationPreferencesStore.load()
            await notificationScheduler.scheduleDeferredReminder(
                for: task,
                at: until,
                preferences: preferences
            )
        }
        
        // Record defer for learning
        await contextEngine.recordDefer(for: task, reason: reason)
        
        showDeferSheet = false
        taskToDefer = nil
        loadTasks()
    }

    private func rankTasks(_ tasks: [Task]) -> [Task] {
        let ranked = tasks
            .map { ($0, calculateDoabilityScore(task: $0)) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
        
        // Track when tasks are surfaced for duration measurement
        for task in ranked {
            if taskStartTimes[task.id] == nil {
                taskStartTimes[task.id] = Date()
            }
        }
        
        return ranked
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
            return isWaitingFollowUpDue(task) ? 30 : -1000
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

    private func isWaitingFollowUpDue(_ task: Task) -> Bool {
        guard task.status == .waiting else { return false }
        let dueDate = waitingFollowUpDate(for: task)
        return dueDate.map { $0 <= Date() } ?? false
    }

    private func waitingFollowUpDate(for task: Task) -> Date? {
        let intervalDays = task.waitingFollowUpIntervalDays ?? 0
        guard intervalDays > 0 else { return nil }
        let base = task.waitingLastFollowUpAt ?? task.waitingSince
        guard let base else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: base)
    }

    private func reactivateDeferredTasks(_ tasks: [Task]) -> [Task] {
        let now = Date()
        var updated = tasks
        for task in updated where task.status == .deferred {
            if let until = task.deferUntil, until <= now {
                task.status = .active
                task.deferUntil = nil
            }
        }
        try? modelContext.save()
        return updated
    }

    private func updateCascade(for completed: Task) -> Int {
        let completedId = completed.id
        let dependencyDescriptor = FetchDescriptor<TaskDependency>(
            predicate: #Predicate { $0.blocker.id == completedId }
        )
        let dependencies = (try? modelContext.fetch(dependencyDescriptor)) ?? []
        var newlyUnblocked: [Task] = []

        for dependency in dependencies {
            let blocked = dependency.blocked
            let allDependencies = blocked.dependencies
            let stillBlocked = allDependencies.contains { $0.blocker.status != .completed }
            if !stillBlocked && blocked.status == .waiting {
                blocked.status = .active
                newlyUnblocked.append(blocked)
            }
        }

        if !newlyUnblocked.isEmpty {
            try? modelContext.save()
        }
        return newlyUnblocked.count
    }

    private func evaluateFocusTimeCandidate(from tasks: [Task]) -> FocusTimeCandidate? {
        if let deferred = tasks.first(where: { $0.deferCount >= 5 }) {
            return FocusTimeCandidate(task: deferred, trigger: .deferredStreak)
        }

        let staleThreshold = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        if let stale = tasks.first(where: { $0.status == .active && $0.createdAt < staleThreshold }) {
            return FocusTimeCandidate(task: stale, trigger: .staleTask)
        }

        let dependencies = tasks.flatMap(\.dependencies)
        if let blocking = tasks.first(where: { task in
            dependencies.filter { $0.blocker.id == task.id }.count >= 2
        }) {
            return FocusTimeCandidate(task: blocking, trigger: .blockingOthers)
        }

        return nil
    }
}
