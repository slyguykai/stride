import Foundation
import SwiftData

@Model
final class Subtask: IdentifiedModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int

    var parentTask: Task?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        order: Int,
        parentTask: Task? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
        self.parentTask = parentTask
    }
}
