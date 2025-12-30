import Foundation

struct ParsedTask: Codable, Sendable {
    var title: String
    var subtasks: [String]
    var dependencies: [String]
    var estimatedMinutes: Int
    var energyLevel: EnergyLevel
    var contextTags: [String]
}
