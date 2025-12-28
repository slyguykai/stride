import Foundation
import SwiftData

@Model
final class RecurringRule: IdentifiedModel {
    @Attribute(.unique) var id: UUID
    var frequency: Int
    var period: RecurringPeriod
    var windowStart: Date
    var windowEnd: Date
    var preferredDays: [Int]
    var isActive: Bool

    var task: Task?

    init(
        id: UUID = UUID(),
        frequency: Int,
        period: RecurringPeriod,
        windowStart: Date,
        windowEnd: Date,
        preferredDays: [Int] = [],
        isActive: Bool = true,
        task: Task? = nil
    ) {
        self.id = id
        self.frequency = frequency
        self.period = period
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.preferredDays = preferredDays
        self.isActive = isActive
        self.task = task
    }
}
