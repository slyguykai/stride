import Foundation

/// Features captured for each task completion/defer event for ML training
/// These are fed into the on-device model for personalization
struct UserBehaviorFeatures: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    
    // Temporal context
    let hourOfDay: Int           // 0-23
    let dayOfWeek: Int           // 1-7 (Sunday = 1)
    let minuteOfDay: Int         // 0-1439
    let isWeekend: Bool
    
    // Task characteristics
    let taskEnergyLevel: String  // low, medium, high
    let taskType: String         // obligation, aspirational
    let estimatedMinutes: Int
    let subtaskCount: Int
    let dependencyCount: Int
    
    // History context
    let deferCountBefore: Int
    let daysSinceCreation: Int
    let completionsToday: Int
    let defersToday: Int
    
    // Outcome
    let wasCompleted: Bool
    let wasDeferred: Bool
    let deferReason: String?
    let timeToComplete: TimeInterval?  // nil if deferred
    
    init(
        task: Task,
        wasCompleted: Bool,
        deferReason: DeferReason? = nil,
        timeToComplete: TimeInterval? = nil,
        completionsToday: Int = 0,
        defersToday: Int = 0
    ) {
        self.id = UUID()
        self.timestamp = Date()
        
        let calendar = Calendar.current
        self.hourOfDay = calendar.component(.hour, from: timestamp)
        self.dayOfWeek = calendar.component(.weekday, from: timestamp)
        self.minuteOfDay = calendar.component(.hour, from: timestamp) * 60 +
                           calendar.component(.minute, from: timestamp)
        self.isWeekend = calendar.isDateInWeekend(timestamp)
        
        self.taskEnergyLevel = task.energyLevel.rawValue
        self.taskType = task.taskType.rawValue
        self.estimatedMinutes = task.estimatedMinutes
        self.subtaskCount = task.subtasks.count
        self.dependencyCount = task.dependencies.count
        
        self.deferCountBefore = task.deferCount
        self.daysSinceCreation = calendar.dateComponents([.day], from: task.createdAt, to: timestamp).day ?? 0
        self.completionsToday = completionsToday
        self.defersToday = defersToday
        
        self.wasCompleted = wasCompleted
        self.wasDeferred = !wasCompleted
        self.deferReason = deferReason?.rawValue
        self.timeToComplete = timeToComplete
    }
}

/// Collection of behavior features for training
struct BehaviorDataset: Codable {
    var features: [UserBehaviorFeatures]
    var lastUpdated: Date
    
    init(features: [UserBehaviorFeatures] = []) {
        self.features = features
        self.lastUpdated = Date()
    }
    
    mutating func add(_ feature: UserBehaviorFeatures) {
        features.append(feature)
        lastUpdated = Date()
        
        // Keep only last 1000 records to limit storage
        if features.count > 1000 {
            features = Array(features.suffix(1000))
        }
    }
    
    var completionRate: Double {
        guard !features.isEmpty else { return 0 }
        let completed = features.filter { $0.wasCompleted }.count
        return Double(completed) / Double(features.count)
    }
    
    func completionRate(for hour: Int) -> Double {
        let hourFeatures = features.filter { $0.hourOfDay == hour }
        guard !hourFeatures.isEmpty else { return 0.5 } // Default to neutral
        let completed = hourFeatures.filter { $0.wasCompleted }.count
        return Double(completed) / Double(hourFeatures.count)
    }
    
    func completionRate(for energyLevel: String) -> Double {
        let levelFeatures = features.filter { $0.taskEnergyLevel == energyLevel }
        guard !levelFeatures.isEmpty else { return 0.5 }
        let completed = levelFeatures.filter { $0.wasCompleted }.count
        return Double(completed) / Double(levelFeatures.count)
    }
    
    func bestHoursForCompletion() -> [Int] {
        var hourRates: [(hour: Int, rate: Double)] = []
        for hour in 0..<24 {
            let rate = completionRate(for: hour)
            hourRates.append((hour, rate))
        }
        return hourRates
            .sorted { $0.rate > $1.rate }
            .prefix(3)
            .map { $0.hour }
    }
}

