import Foundation
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

        let followUp = Task(
            rawInput: "schedule follow-up eye exam after ordering contacts",
            title: "Schedule follow-up eye exam",
            energyLevel: .low,
            estimatedMinutes: 5,
            status: .active,
            taskType: .obligation
        )

        let waitingTask = Task(
            rawInput: "waiting on Dr. Lee to send referral",
            title: "Receive referral from Dr. Lee",
            energyLevel: .low,
            estimatedMinutes: 2,
            status: .waiting,
            taskType: .obligation,
            waitingContactName: "Dr. Lee",
            waitingSince: Date(),
            waitingFollowUpIntervalDays: 3
        )

        let dependency = TaskDependency(type: .hardBlock, blocker: task, blocked: followUp)
        followUp.dependencies = [dependency]

        let recurringRule = RecurringRule(
            frequency: 3,
            period: .week,
            windowStart: Date(),
            windowEnd: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            preferredDays: [2, 4, 6],
            task: aspirational
        )
        aspirational.recurringRule = recurringRule

        modelContext.insert(task)
        modelContext.insert(subtask1)
        modelContext.insert(subtask2)
        modelContext.insert(subtask3)
        modelContext.insert(aspirational)
        modelContext.insert(followUp)
        modelContext.insert(waitingTask)
        modelContext.insert(dependency)
        modelContext.insert(recurringRule)

        do {
            try modelContext.save()
        } catch {
            // Seeding failure should not block app usage.
        }
    }
}
