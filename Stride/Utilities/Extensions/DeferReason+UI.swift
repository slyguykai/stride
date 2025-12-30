import Foundation

extension DeferReason {
    var emoji: String {
        switch self {
        case .blocked: return "🚫"
        case .noEnergy: return "😴"
        case .wrongTime: return "⏰"
        case .unsure: return "🤔"
        case .notImportant: return "🤷"
        }
    }

    var title: String {
        switch self {
        case .blocked: return "Blocked"
        case .noEnergy: return "No energy"
        case .wrongTime: return "Wrong time"
        case .unsure: return "Unsure how to start"
        case .notImportant: return "Not important right now"
        }
    }
}
