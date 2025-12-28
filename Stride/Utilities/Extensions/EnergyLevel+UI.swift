import SwiftUI

extension EnergyLevel {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }

    var title: String {
        switch self {
        case .low: return "Low energy"
        case .medium: return "Medium energy"
        case .high: return "High energy"
        }
    }
}
