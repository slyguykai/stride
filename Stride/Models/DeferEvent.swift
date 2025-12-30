import Foundation
import SwiftData

@Model
final class DeferEvent: IdentifiedModel {
    @Attribute(.unique) var id: UUID
    var reason: DeferReason
    var timestamp: Date
    var proposedTime: Date?

    var task: Task?

    init(
        id: UUID = UUID(),
        reason: DeferReason,
        timestamp: Date = Date(),
        proposedTime: Date? = nil,
        task: Task? = nil
    ) {
        self.id = id
        self.reason = reason
        self.timestamp = timestamp
        self.proposedTime = proposedTime
        self.task = task
    }
}
