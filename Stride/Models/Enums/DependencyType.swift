import Foundation

enum DependencyType: String, Codable, CaseIterable {
    case hardBlock
    case softBlock
    case waiting
}
