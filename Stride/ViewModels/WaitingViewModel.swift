import Foundation
import Observation
import SwiftData
import UIKit

@Observable
@MainActor
final class WaitingViewModel {
    private let modelContext: ModelContext
    private let notificationScheduler: NotificationSchedulerProtocol
    private let templateService = WaitingMessageTemplateService()

    private(set) var waitingTasks: [Task] = []

    init(
        modelContext: ModelContext,
        notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler()
    ) {
        self.modelContext = modelContext
        self.notificationScheduler = notificationScheduler
    }

    func load() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
        )
        let tasks = (try? modelContext.fetch(descriptor)) ?? []
        waitingTasks = tasks.filter { $0.status == .waiting }
    }

    func configureWaiting(
        task: Task,
        contactName: String,
        followUpIntervalDays: Int,
        customMessage: String?
    ) {
        task.status = .waiting
        task.waitingContactName = contactName.isEmpty ? nil : contactName
        task.waitingSince = task.waitingSince ?? Date()
        task.waitingFollowUpIntervalDays = followUpIntervalDays
        task.waitingFollowUpMessage = customMessage?.isEmpty == false
            ? customMessage
            : templateService.defaultTemplate(for: task, contactName: task.waitingContactName)
        try? modelContext.save()
        scheduleNextFollowUp(for: task)
        load()
    }

    func followUpNow(task: Task) {
        task.waitingFollowUpCount = (task.waitingFollowUpCount ?? 0) + 1
        task.waitingLastFollowUpAt = Date()
        if task.waitingFollowUpMessage == nil {
            task.waitingFollowUpMessage = templateService.defaultTemplate(
                for: task,
                contactName: task.waitingContactName
            )
        }
        try? modelContext.save()
        UIPasteboard.general.string = task.waitingFollowUpMessage
        HapticEngine.shared.mediumTap()
        scheduleNextFollowUp(for: task)
        load()
    }

    func followUpDate(for task: Task) -> Date? {
        let interval = task.waitingFollowUpIntervalDays ?? 0
        guard interval > 0 else { return nil }
        let base = task.waitingLastFollowUpAt ?? task.waitingSince
        guard let base else { return nil }
        return Calendar.current.date(byAdding: .day, value: interval, to: base)
    }

    private func scheduleNextFollowUp(for task: Task) {
        guard let date = followUpDate(for: task) else { return }
        let preferences = NotificationPreferencesStore.load()
        _Concurrency.Task {
            await notificationScheduler.scheduleWaitingFollowUp(
                for: task,
                at: date,
                preferences: preferences
            )
        }
    }
}
