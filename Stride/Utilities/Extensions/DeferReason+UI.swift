import Foundation

extension DeferReason {
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
