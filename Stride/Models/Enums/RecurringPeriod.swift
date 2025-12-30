import Foundation

enum RecurringPeriod: String, Codable, CaseIterable {
    case week
    case month
}

extension RecurringPeriod {
    var title: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        }
    }
}
