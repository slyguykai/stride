import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case active
    case waiting
    case deferred
    case completed
}
