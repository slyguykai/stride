import Foundation

struct StreakData: Sendable {
    let tasksToday: Int
    let tasksBestToday: Int
    let currentDayStreak: Int
    let longestDayStreak: Int
    let weeklyAverage: Double
}

final class StreakTracker {
    private enum Keys {
        static let tasksToday = "streak.tasksToday"
        static let lastCompletionDay = "streak.lastCompletionDay"
        static let currentStreak = "streak.currentStreak"
        static let longestStreak = "streak.longestStreak"
        static let dailyHistory = "streak.dailyHistory"
        static let tasksBestToday = "streak.tasksBestToday"
    }

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    func recordCompletion(on date: Date = Date()) -> StreakData {
        let dayKey = dayString(for: date)
        let lastDayKey = defaults.string(forKey: Keys.lastCompletionDay)

        var tasksToday = defaults.integer(forKey: Keys.tasksToday)
        var tasksBestToday = defaults.integer(forKey: Keys.tasksBestToday)
        var currentStreak = defaults.integer(forKey: Keys.currentStreak)
        var longestStreak = defaults.integer(forKey: Keys.longestStreak)

        if lastDayKey != dayKey {
            tasksToday = 0
            tasksBestToday = max(tasksBestToday, defaults.integer(forKey: Keys.tasksToday))
            if let lastDayKey, let lastDate = dateFromDayString(lastDayKey) {
                let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0
                currentStreak = daysBetween == 1 ? currentStreak + 1 : 1
            } else {
                currentStreak = 1
            }
        }

        tasksToday += 1
        if tasksToday > tasksBestToday {
            tasksBestToday = tasksToday
        }
        longestStreak = max(longestStreak, currentStreak)

        defaults.set(tasksToday, forKey: Keys.tasksToday)
        defaults.set(dayKey, forKey: Keys.lastCompletionDay)
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(tasksBestToday, forKey: Keys.tasksBestToday)

        updateHistory(dayKey: dayKey, count: tasksToday)

        return StreakData(
            tasksToday: tasksToday,
            tasksBestToday: tasksBestToday,
            currentDayStreak: currentStreak,
            longestDayStreak: longestStreak,
            weeklyAverage: weeklyAverage()
        )
    }

    func currentData() -> StreakData {
        StreakData(
            tasksToday: defaults.integer(forKey: Keys.tasksToday),
            tasksBestToday: defaults.integer(forKey: Keys.tasksBestToday),
            currentDayStreak: defaults.integer(forKey: Keys.currentStreak),
            longestDayStreak: defaults.integer(forKey: Keys.longestStreak),
            weeklyAverage: weeklyAverage()
        )
    }

    private func updateHistory(dayKey: String, count: Int) {
        var history = defaults.dictionary(forKey: Keys.dailyHistory) as? [String: Int] ?? [:]
        history[dayKey] = count
        defaults.set(history, forKey: Keys.dailyHistory)
    }

    private func weeklyAverage() -> Double {
        let history = defaults.dictionary(forKey: Keys.dailyHistory) as? [String: Int] ?? [:]
        let lastSeven = (0..<7).compactMap { dayOffset -> String? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { return nil }
            return dayString(for: date)
        }
        let totals = lastSeven.compactMap { history[$0] }
        guard !totals.isEmpty else { return 0 }
        return Double(totals.reduce(0, +)) / Double(totals.count)
    }

    private func dayString(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func dateFromDayString(_ string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
