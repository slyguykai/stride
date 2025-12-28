import Foundation
import SwiftData

@Model
final class UserPattern: IdentifiedModel {
    @Attribute(.unique) var id: UUID
    var dayOfWeek: Int
    var hourOfDay: Int
    var avgEnergyLevel: Float
    var taskCompletionRate: Float
    var preferredTaskTypes: [String]

    init(
        id: UUID = UUID(),
        dayOfWeek: Int,
        hourOfDay: Int,
        avgEnergyLevel: Float,
        taskCompletionRate: Float,
        preferredTaskTypes: [String] = []
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
        self.avgEnergyLevel = avgEnergyLevel
        self.taskCompletionRate = taskCompletionRate
        self.preferredTaskTypes = preferredTaskTypes
    }
}
