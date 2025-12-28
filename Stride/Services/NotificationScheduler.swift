import Foundation
import UserNotifications

struct NotificationPreferences: Sendable {
    var allowTimeBased: Bool = true
    var allowEnergyBased: Bool = true
    var allowDeferReminders: Bool = true
    var allowWaitingReminders: Bool = true
    var dailyLimit: Int = 3
}

protocol NotificationSchedulerProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func scheduleDeferredReminder(for task: Task, at date: Date, preferences: NotificationPreferences) async
    func scheduleWaitingFollowUp(for task: Task, at date: Date, preferences: NotificationPreferences) async
    func scheduleContextSuggestions(
        tasks: [Task],
        calendarService: CalendarServiceProtocol,
        preferences: NotificationPreferences
    ) async
    func scheduleWeeklyRetrospective(at time: Date, preferences: NotificationPreferences) async
}

actor NotificationScheduler: NotificationSchedulerProtocol {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDeferredReminder(for task: Task, at date: Date, preferences: NotificationPreferences) async {
        guard preferences.allowDeferReminders else { return }
        let content = UNMutableNotificationContent()
        content.title = "Ready to resume?"
        content.body = task.title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "defer-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func scheduleWaitingFollowUp(for task: Task, at date: Date, preferences: NotificationPreferences) async {
        guard preferences.allowWaitingReminders else { return }
        let content = UNMutableNotificationContent()
        content.title = "Follow up"
        content.body = task.title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "waiting-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func scheduleContextSuggestions(
        tasks: [Task],
        calendarService: CalendarServiceProtocol,
        preferences: NotificationPreferences
    ) async {
        guard preferences.allowTimeBased || preferences.allowEnergyBased else { return }

        let pending = tasks.filter { $0.status == .active }
        guard !pending.isEmpty else { return }

        var scheduled = 0
        let limit = max(1, min(preferences.dailyLimit, 5))

        if preferences.allowTimeBased {
            if let suggestion = await scheduleQuickWin(
                tasks: pending,
                calendarService: calendarService,
                remaining: limit - scheduled
            ) {
                scheduled += suggestion
            }
        }

        if preferences.allowEnergyBased, scheduled < limit {
            let additional = await scheduleEnergyMatches(
                tasks: pending,
                remaining: limit - scheduled
            )
            scheduled += additional
        }
    }

    func scheduleWeeklyRetrospective(at time: Date, preferences: NotificationPreferences) async {
        guard preferences.allowTimeBased else { return }
        let content = UNMutableNotificationContent()
        content.title = "Weekly retrospective"
        content.body = "Take a moment to reflect on your week."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.weekday, .hour, .minute],
            from: time
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        let request = UNNotificationRequest(
            identifier: "retrospective-weekly",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private func scheduleQuickWin(
        tasks: [Task],
        calendarService: CalendarServiceProtocol,
        remaining: Int
    ) async -> Int? {
        guard remaining > 0 else { return nil }
        let quickWins = tasks.filter { $0.estimatedMinutes <= 5 }
        guard let task = quickWins.first else { return nil }

        do {
            let slots = try await calendarService.nextAvailableSlots(durationMinutes: 5, searchDays: 1)
            guard let slot = slots.first else { return nil }
            await scheduleSuggestion(
                title: "Quick win window",
                body: "\(task.title) fits before your next block.",
                date: slot,
                identifier: "quickwin-\(task.id.uuidString)"
            )
            return 1
        } catch {
            return nil
        }
    }

    private func scheduleEnergyMatches(tasks: [Task], remaining: Int) async -> Int {
        guard remaining > 0 else { return 0 }
        let windows: [(EnergyLevel, DateComponents, String)] = [
            (.high, DateComponents(hour: 9, minute: 0), "High energy window"),
            (.medium, DateComponents(hour: 14, minute: 0), "Steady focus window"),
            (.low, DateComponents(hour: 19, minute: 0), "Low energy window")
        ]

        var scheduled = 0
        for (energy, time, title) in windows {
            guard scheduled < remaining else { break }
            guard let task = tasks.first(where: { $0.energyLevel == energy }) else { continue }
            if let date = Calendar.current.nextDate(
                after: Date(),
                matching: time,
                matchingPolicy: .nextTime
            ) {
                await scheduleSuggestion(
                    title: title,
                    body: task.title,
                    date: date,
                    identifier: "energy-\(task.id.uuidString)-\(energy.rawValue)"
                )
                scheduled += 1
            }
        }
        return scheduled
    }

    private func scheduleSuggestion(title: String, body: String, date: Date, identifier: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
