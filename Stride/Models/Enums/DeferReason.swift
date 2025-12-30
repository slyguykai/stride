import Foundation

enum DeferReason: String, Codable, CaseIterable {
    case blocked
    case noEnergy
    case wrongTime
    case unsure
    case notImportant
}
