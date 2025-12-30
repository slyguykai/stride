import Foundation
import SwiftData

@Model
final class TaskDependency: IdentifiedModel {
    @Attribute(.unique) var id: UUID
    var type: DependencyType

    var blocker: Task

    var blocked: Task

    init(
        id: UUID = UUID(),
        type: DependencyType,
        blocker: Task,
        blocked: Task
    ) {
        self.id = id
        self.type = type
        self.blocker = blocker
        self.blocked = blocked
    }
}
