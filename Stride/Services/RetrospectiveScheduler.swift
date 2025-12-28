import Foundation

struct RetrospectiveScheduler {
    private let notificationScheduler: NotificationSchedulerProtocol

    init(notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler()) {
        self.notificationScheduler = notificationScheduler
    }

    func scheduleWeekly() {
        let preferences = NotificationPreferencesStore.load()
        let nextSunday = nextSundayAt(hour: 18, minute: 0)
        _Concurrency.Task {
            await notificationScheduler.scheduleWeeklyRetrospective(
                at: nextSunday,
                preferences: preferences
            )
        }
    }

    private func nextSundayAt(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = 1
        components.hour = hour
        components.minute = minute
        return calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? Date()
    }
}
