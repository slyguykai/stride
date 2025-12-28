import Foundation

struct TaskContext: Sendable {
    var recentTasks: [String]
    var userPatterns: [String]
    var personalContext: [String: String]
}
