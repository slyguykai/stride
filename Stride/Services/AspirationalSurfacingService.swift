import Foundation

struct AspirationalSurfacingService {
    func shouldSurfaceAspirational(tasks: [Task]) -> Bool {
        let recentCompletions = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt > Date().addingTimeInterval(-86400)
        }
        let pendingObligations = tasks.filter { $0.taskType == .obligation && $0.status == .active }
        let currentEnergy = estimateCurrentEnergy()

        return recentCompletions.count >= 5
            && pendingObligations.count < 3
            && currentEnergy == .high
    }

    private func estimateCurrentEnergy() -> EnergyLevel {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6...10:
            return .high
        case 11...16:
            return .medium
        default:
            return .low
        }
    }
}
