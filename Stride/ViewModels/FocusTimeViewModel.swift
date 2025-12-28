import Foundation
import Observation
import SwiftData

struct FocusTimeCandidate: Identifiable {
    let id = UUID()
    let task: Task
    let trigger: FocusTimeTrigger
}

enum FocusTimeTrigger: String {
    case deferredStreak
    case staleTask
    case blockingOthers

    var title: String {
        switch self {
        case .deferredStreak:
            return "You've deferred this a few times."
        case .staleTask:
            return "This has been hanging around."
        case .blockingOthers:
            return "This is blocking other tasks."
        }
    }

    var prompt: String {
        switch self {
        case .deferredStreak:
            return "What's the smallest first step?"
        case .staleTask:
            return "What would make this easy to start?"
        case .blockingOthers:
            return "Let's unblock everything downstream."
        }
    }
}

@Observable
@MainActor
final class FocusTimeViewModel {
    private let modelContext: ModelContext
    private let calendarService: CalendarServiceProtocol
    private let aiService: AIServiceProtocol
    private let notificationScheduler: NotificationSchedulerProtocol

    let candidate: FocusTimeCandidate
    private(set) var blockedTasks: [Task] = []
    private(set) var availableSlots: [Date] = []
    private(set) var microBreakdown: MicroBreakdown?
    private(set) var isLoading = false
    var selectedSlot: Date?
    var blockReason: String

    init(
        candidate: FocusTimeCandidate,
        modelContext: ModelContext,
        calendarService: CalendarServiceProtocol = CalendarService(),
        aiService: AIServiceProtocol = FocusTimeViewModel.defaultAIService(),
        notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler()
    ) {
        self.candidate = candidate
        self.modelContext = modelContext
        self.calendarService = calendarService
        self.aiService = aiService
        self.notificationScheduler = notificationScheduler
        self.blockReason = candidate.trigger.prompt
    }

    nonisolated private static func defaultAIService() -> AIServiceProtocol {
        if let key = Secrets.openAIKey, !key.isEmpty {
            return AIService(apiClient: OpenAIClient())
        }
        return AIService(apiClient: MockAIClient())
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        blockedTasks = fetchBlockedTasks(for: candidate.task)
        await loadAvailability()
        await loadMicroBreakdown()
    }

    func regenerateMicroBreakdown() async {
        isLoading = true
        defer { isLoading = false }
        await loadMicroBreakdown()
    }

    func addMicroStepsToTask() {
        guard let microBreakdown else { return }
        let startIndex = candidate.task.subtasks.count
        let newSubtasks = microBreakdown.microSteps.enumerated().map { offset, title in
            Subtask(title: title, order: startIndex + offset, parentTask: candidate.task)
        }
        candidate.task.subtasks.append(contentsOf: newSubtasks)
        newSubtasks.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }

    func commitToSlot() {
        guard let selectedSlot else { return }
        candidate.task.status = .active
        candidate.task.deferUntil = selectedSlot
        try? modelContext.save()
        let preferences = NotificationPreferencesStore.load()
        _Concurrency.Task {
            await notificationScheduler.scheduleDeferredReminder(
                for: candidate.task,
                at: selectedSlot,
                preferences: preferences
            )
        }
    }

    func markNotDoing() {
        candidate.task.status = .deferred
        try? modelContext.save()
    }

    private func fetchBlockedTasks(for task: Task) -> [Task] {
        let taskId = task.id
        let descriptor = FetchDescriptor<TaskDependency>(
            predicate: #Predicate { $0.blocker.id == taskId }
        )
        let dependencies = (try? modelContext.fetch(descriptor)) ?? []
        return dependencies.map { $0.blocked }
    }

    private func loadAvailability() async {
        do {
            availableSlots = try await calendarService.nextAvailableSlots(
                durationMinutes: candidate.task.estimatedMinutes,
                searchDays: 7
            )
            selectedSlot = availableSlots.first
        } catch {
            availableSlots = []
        }
    }

    private func loadMicroBreakdown() async {
        do {
            microBreakdown = try await aiService.microBreakdown(
                task: candidate.task,
                blockReason: blockReason
            )
        } catch {
            microBreakdown = nil
        }
    }
}
