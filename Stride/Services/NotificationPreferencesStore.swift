import Foundation

enum NotificationPreferencesStore {
    enum Keys {
        static let allowTimeBased = "notifications.allowTimeBased"
        static let allowEnergyBased = "notifications.allowEnergyBased"
        static let allowDeferReminders = "notifications.allowDeferReminders"
        static let allowWaitingReminders = "notifications.allowWaitingReminders"
        static let dailyLimit = "notifications.dailyLimit"
    }

    static func load() -> NotificationPreferences {
        let defaults = UserDefaults.standard
        return NotificationPreferences(
            allowTimeBased: defaults.object(forKey: Keys.allowTimeBased) as? Bool ?? true,
            allowEnergyBased: defaults.object(forKey: Keys.allowEnergyBased) as? Bool ?? true,
            allowDeferReminders: defaults.object(forKey: Keys.allowDeferReminders) as? Bool ?? true,
            allowWaitingReminders: defaults.object(forKey: Keys.allowWaitingReminders) as? Bool ?? true,
            dailyLimit: defaults.object(forKey: Keys.dailyLimit) as? Int ?? 3
        )
    }
}
