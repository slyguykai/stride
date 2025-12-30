import Foundation

struct PatternInsight: Identifiable {
    let id = UUID()
    let taskType: String
    let avgDeferCount: Double
    let bestTimeOfDay: Int?
    let worstTimeOfDay: Int?
    let commonBlockers: [String]
    let summary: String
}

struct PatternDetectionService {
    func analyzePatterns(for tasks: [Task]) -> [PatternInsight] {
        let grouped = Dictionary(grouping: tasks) { $0.taskType.rawValue }

        return grouped.compactMap { taskType, groupedTasks in
            guard !groupedTasks.isEmpty else { return nil }
            let avgDefer = groupedTasks
                .map { Double($0.deferCount) }
                .reduce(0, +) / Double(groupedTasks.count)

            let completionHours = groupedTasks
                .compactMap(\.completedAt)
                .map { Calendar.current.component(.hour, from: $0) }

            let bestHour = mostCommonHour(completionHours)
            let worstHour = leastCommonHour(completionHours)

            let blockers = groupedTasks
                .flatMap { $0.dependencies }
                .map { $0.blocker.title }

            let commonBlockers = mostCommonStrings(blockers, limit: 3)

            let summary = buildSummary(
                taskType: taskType,
                avgDeferCount: avgDefer,
                bestHour: bestHour,
                worstHour: worstHour,
                commonBlockers: commonBlockers
            )

            return PatternInsight(
                taskType: taskType.capitalized,
                avgDeferCount: avgDefer,
                bestTimeOfDay: bestHour,
                worstTimeOfDay: worstHour,
                commonBlockers: commonBlockers,
                summary: summary
            )
        }
        .sorted { $0.taskType < $1.taskType }
    }

    private func mostCommonHour(_ hours: [Int]) -> Int? {
        guard !hours.isEmpty else { return nil }
        var counts: [Int: Int] = [:]
        hours.forEach { counts[$0, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func leastCommonHour(_ hours: [Int]) -> Int? {
        guard !hours.isEmpty else { return nil }
        var counts: [Int: Int] = [:]
        hours.forEach { counts[$0, default: 0] += 1 }
        return counts.min(by: { $0.value < $1.value })?.key
    }

    private func mostCommonStrings(_ values: [String], limit: Int) -> [String] {
        var counts: [String: Int] = [:]
        values.forEach { counts[$0, default: 0] += 1 }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    private func buildSummary(
        taskType: String,
        avgDeferCount: Double,
        bestHour: Int?,
        worstHour: Int?,
        commonBlockers: [String]
    ) -> String {
        var parts: [String] = []
        parts.append("\(taskType.capitalized) tasks average \(String(format: "%.1f", avgDeferCount)) defers.")
        if let bestHour {
            parts.append("Best completion time: \(formatHour(bestHour)).")
        }
        if let worstHour {
            parts.append("Hardest time: \(formatHour(worstHour)).")
        }
        if let firstBlocker = commonBlockers.first {
            parts.append("Common blocker: \(firstBlocker).")
        }
        return parts.joined(separator: " ")
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
