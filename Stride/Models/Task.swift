import Foundation
import SwiftData

@Model
final class Task: IdentifiedModel {
    @Attribute(.unique) var id: UUID
    var rawInput: String
    var title: String
    var notes: String
    var energyLevel: EnergyLevel
    var estimatedMinutes: Int
    var status: TaskStatus
    var taskType: TaskType
    var deferCount: Int
    var deferUntil: Date?
    var waitingContactName: String?
    var waitingSince: Date?
    var waitingFollowUpIntervalDays: Int?
    var waitingFollowUpMessage: String?
    var waitingFollowUpCount: Int?
    var waitingLastFollowUpAt: Date?
    var aspirationWhy: String?
    var aspirationWhen: String?
    var aspirationOnboardingComplete: Bool?
    var deadline: Date?
    var createdAt: Date
    var completedAt: Date?
    var contextTags: [String]?

    var subtasks: [Subtask]
    var dependencies: [TaskDependency]
    var deferEvents: [DeferEvent]
    var recurringRule: RecurringRule?

    init(
        id: UUID = UUID(),
        rawInput: String,
        title: String,
        notes: String = "",
        energyLevel: EnergyLevel,
        estimatedMinutes: Int,
        status: TaskStatus,
        taskType: TaskType,
        deferCount: Int = 0,
        deferUntil: Date? = nil,
        waitingContactName: String? = nil,
        waitingSince: Date? = nil,
        waitingFollowUpIntervalDays: Int? = nil,
        waitingFollowUpMessage: String? = nil,
        waitingFollowUpCount: Int? = nil,
        waitingLastFollowUpAt: Date? = nil,
        aspirationWhy: String? = nil,
        aspirationWhen: String? = nil,
        aspirationOnboardingComplete: Bool? = nil,
        deadline: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        contextTags: [String] = [],
        subtasks: [Subtask] = [],
        dependencies: [TaskDependency] = [],
        deferEvents: [DeferEvent] = [],
        recurringRule: RecurringRule? = nil
    ) {
        self.id = id
        self.rawInput = rawInput
        self.title = title
        self.notes = notes
        self.energyLevel = energyLevel
        self.estimatedMinutes = estimatedMinutes
        self.status = status
        self.taskType = taskType
        self.deferCount = deferCount
        self.deferUntil = deferUntil
        self.waitingContactName = waitingContactName
        self.waitingSince = waitingSince
        self.waitingFollowUpIntervalDays = waitingFollowUpIntervalDays
        self.waitingFollowUpMessage = waitingFollowUpMessage
        self.waitingFollowUpCount = waitingFollowUpCount
        self.waitingLastFollowUpAt = waitingLastFollowUpAt
        self.aspirationWhy = aspirationWhy
        self.aspirationWhen = aspirationWhen
        self.aspirationOnboardingComplete = aspirationOnboardingComplete
        self.deadline = deadline
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.contextTags = contextTags
        self.subtasks = subtasks
        self.dependencies = dependencies
        self.deferEvents = deferEvents
        self.recurringRule = recurringRule
    }

    var progress: Double {
        guard !subtasks.isEmpty else { return 0 }
        let completed = subtasks.filter(\Subtask.isCompleted).count
        return Double(completed) / Double(subtasks.count)
    }
}
